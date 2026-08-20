#Requires -Version 5.1
<#
.SYNOPSIS
  One-time setup: enable hexo_blog GitHub Actions auto-deploy to alen9966.github.io.

.DESCRIPTION
  This script must run on YOUR machine (logged into GitHub).
  Cloud agents cannot create PATs or repository secrets.

  What it does:
  1. Checks `gh` login
  2. Creates a write deploy key on alen9966/alen9966.github.io
  3. Stores the private key as secret DEPLOY_SSH_KEY on alen9966/hexo_blog
  4. Triggers the Deploy GitHub Pages workflow

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\setup-auto-deploy.ps1
#>

$ErrorActionPreference = "Stop"

$SourceRepo = "alen9966/hexo_blog"
$PagesRepo = "alen9966/alen9966.github.io"
$SecretName = "DEPLOY_SSH_KEY"
$KeyTitle = "hexo-blog-actions-deploy-$(Get-Date -Format 'yyyyMMdd')"

function Assert-Gh {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw @"
未找到 GitHub CLI (gh)。

请先安装: https://cli.github.com/
安装后重新打开 PowerShell，执行:
  gh auth login
然后再运行本脚本。
"@
  }

  gh auth status 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "正在登录 GitHub..."
    gh auth login
  }
}

Write-Host "==> 检查 gh 登录状态"
Assert-Gh
gh auth status

Write-Host ""
Write-Host "==> 生成部署用 SSH 密钥（仅用于推送到 $PagesRepo）"
$tmp = Join-Path $env:TEMP ("hexo-deploy-key-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
$keyPath = Join-Path $tmp "id_ed25519"
ssh-keygen -t ed25519 -N '""' -C $KeyTitle -f $keyPath | Out-Host
$publicKey = (Get-Content -Raw ($keyPath + ".pub")).Trim()
$privateKey = (Get-Content -Raw $keyPath)

Write-Host ""
Write-Host "==> 把公钥加到 $PagesRepo 的 Deploy keys（可写）"
# Remove old keys with same title prefix to avoid duplicates on re-run
$existing = gh api "repos/$PagesRepo/keys" --jq ".[] | select(.title|startswith(`"hexo-blog-actions-deploy-`")) | .id" 2>$null
if ($existing) {
  foreach ($id in ($existing -split "`n")) {
    if ($id) {
      Write-Host "    删除旧 deploy key id=$id"
      gh api -X DELETE "repos/$PagesRepo/keys/$id" | Out-Null
    }
  }
}

gh api -X POST "repos/$PagesRepo/keys" `
  -f title="$KeyTitle" `
  -f key="$publicKey" `
  -F read_only=false | Out-Null

Write-Host ""
Write-Host "==> 把私钥写入 $SourceRepo 的 Actions Secret: $SecretName"
$privateKey | gh secret set $SecretName --repo $SourceRepo

Write-Host ""
Write-Host "==> 触发 Deploy GitHub Pages 工作流"
gh workflow run "Deploy GitHub Pages" --repo $SourceRepo

Write-Host ""
Write-Host "清理临时密钥文件..."
Remove-Item -Recurse -Force $tmp

Write-Host ""
Write-Host "完成。"
Write-Host "查看运行状态: https://github.com/$SourceRepo/actions/workflows/deploy-pages.yml"
Write-Host "部署仓库提交: https://github.com/$PagesRepo/commits/main"
Write-Host ""
Write-Host "之后只要 push 到 hexo_blog 的 main，就会自动部署，不必再本地 hexo deploy。"
