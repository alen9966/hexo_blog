---
name: hexo-github-sync
description: 本 Hexo 博客项目的 GitHub 同步、分支、提交、推送与自动部署。用户提到 pull/push、同步 my_blog、部署网站、hexo 命令或 GitHub Actions 时使用。
---

# Hexo 博客 GitHub 同步与部署

## 两个仓库

| 仓库 | 用途 | URL |
|------|------|-----|
| `alen9966/hexo_blog` | **源码**（文章、主题、配置） | https://github.com/alen9966/hexo_blog |
| `alen9966/alen9966.github.io` | **静态站点**（Actions 自动推送） | https://github.com/alen9966/alen9966.github.io |

- 线上站点：https://alen9966.github.io/
- 作者本机目录：**`F:\my_blog`**（对应 `hexo_blog`）

## 云端 Agent 能做什么 / 不能做什么

**能做：**

- 修改 `hexo_blog` 源码，commit 并 push 到 `main` 或 feature 分支
- 创建/更新 Pull Request（分支名：`cursor/<描述>-f4f8`）
- push 到 `main` 后触发 **GitHub Actions** 自动 build + 部署

**不能做：**

- 直接写入作者本机 `F:\my_blog`（必须提醒用户 `git pull`）
- 在没有权限时直接 push 到 `alen9966.github.io`（已由 Actions + `DEPLOY_TOKEN` 处理）
- 替用户在 GitHub 网页创建 PAT（一次性授权需作者本人操作）

## 每次 push 后必须提醒作者

云端改完并 push 到 `main` 后，在回复中给出：

```powershell
cd F:\my_blog
git pull origin main
```

说明：网站已由 Actions 自动更新，**一般不必**再跑 `npx hexo deploy`。

## 作者本机常用命令

Windows PowerShell；**不要用裸 `hexo`**，用 `npx` 或 npm 脚本：

```powershell
cd F:\my_blog
git pull origin main
npm install          # 依赖变更时
npx hexo clean
npx hexo generate
npx hexo server      # 本地预览
# npx hexo deploy    # 已配置 Actions 后通常不需要
```

或：

```powershell
npm run clean
npm run build
npm run server
```

## 自动部署（已配置）

- 工作流：`.github/workflows/deploy-pages.yml`
- 触发：`push` 到 `main`，或手动 **Run workflow**
- Secret：`DEPLOY_TOKEN`（Classic PAT，`repo` 权限）已在 `hexo_blog` 配置
- 成功标志：Actions 全绿；`alen9966.github.io` 出现 `github-actions[bot]` 提交

查看：https://github.com/alen9966/hexo_blog/actions/workflows/deploy-pages.yml

## Cloud Agent Git 规范

1. 新分支：`git checkout -b cursor/<描述>-f4f8`
2. 提交信息用完整中文或英文句子，说明改了什么、为什么
3. Push：`git push -u origin <分支名>`
4. 用 ManagePullRequest 创建/更新 PR；合并到 `main` 后 Actions 自动部署
5. 每轮有代码改动：commit → push → 更新 PR

## 环境

- Node 20+，`npm ci` / `npm install`
- 云端环境：`.cursor/environment.json` 中 `install: npm ci`
- Hexo CLI 为项目本地依赖，路径 `node_modules/.bin/hexo`

## 故障排查

| 现象 | 处理 |
|------|------|
| `hexo` 找不到 | 用 `npx hexo` 或 `npm run` |
| Actions 成功但网站未变 | 等 1–2 分钟，Ctrl+F5 强刷 |
| Actions `403` on push | 更新 `DEPLOY_TOKEN`（需对 `alen9966.github.io` 有写权限） |
| 本机与 GitHub 不一致 | `git pull origin main` |
| 图片不显示 | 确认 lazysizes 已本地化（`source/js/vendor/`），见 main 历史修复 |

## 与写作 skill 的配合

- 文章/content 改动：先按 **`hexo-blog-writing`** 流程
- 提交与同步：按本 skill  push，并提醒本机 `git pull`
