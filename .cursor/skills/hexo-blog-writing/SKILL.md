---
name: hexo-blog-writing
description: 在本 Hexo 博客项目中协助写作、润色、配图与发布准备。用户提供项目资料、PDF、原理图或写作需求时使用；修改 source/_posts、文章配图或 AGENTS.md 写作约定时自动适用。
paths:
  - source/_posts/**
  - source/images/myimge/**
  - AGENTS.md
---

# Hexo 博客写作

本项目的完整约定在仓库根目录 **`AGENTS.md`**。执行写作任务前必须先阅读并遵守其中规则，尤其是：叙事视角、图片唯一性、Wallhaven 选图、PDF 截图、长期写作流程、作者表达习惯。

## 项目是什么

- Hexo 7 + Reimu 主题的技术博客，记录硬件/模拟/电源/测试测量等项目与原理学习。
- 文章 Markdown：`source/_posts/`
- 本地图片：`source/images/myimge/<文章目录>/`，正文引用 `/images/myimge/...`
- 站点路径示例：`/2026/08/18/phase-noise-definition-and-measurement-math/`

## 默认写作流程（必须遵守）

用户提供资料后，**不要立刻写正文**，按 `AGENTS.md`「长期写作流程」推进：

1. 整理已确定事实、设计目标、待验证内容、疑点、缺资料。
2. 必要时最多提 **3 个**会改变文章方向的问题。
3. 输出 **文章结构卡**（格式见 `AGENTS.md`）。
4. 与用户确认标题、摘要、分类、标签、截图清单。
5. 只有用户明确说「开始写正文」或同等意思后，才生成/修改完整文章。
6. 发布前自检：读者能否完成一次设计判断或排查；是否泄露未公开资料。

每篇文章只承担一种主任务：**项目记录** / **问题排查** / **原理学习**。

## 写作风格要点

- 用「我」「这次设计」等作者视角，禁止 AI 汇报口吻（「从你提供的原理图来看…」「等你后面测到…」）。
- 写给不了解项目的读者：新概念先解释「是什么 → 为什么需要 → 这里为何这样设计」。
- 写设计取舍与参数，不写原理图识别报告；区分已确定 / 设计目标 / 尚待验证。
- 参考《3+1 寒假培训 - 模拟调制解调》的叙事节奏，不照搬句子。

## 图片规则（摘要）

- 装饰/封面默认从 [Wallhaven](https://wallhaven.cc/) 选粉色或浅暖色动漫图，SFW。
- 每张图片全站**最多引用一次**；只用 `source/images/myimge/` 本地路径。
- 技术图来自 PDF/原理图截图或 MATLAB 仿真；仿真须保留 `.m` 脚本到 `matlab/<主题>/`。
- 未经用户同意：不生成无关图片、不删现有图片、不从 `source/images/` 其他子目录借图。

## 新建文章时的文件约定

Front Matter 常见字段（按现有文章对齐）：

```yaml
---
title:
date:
updated:
tags:
categories:
cover: /images/myimge/<目录>/wallhaven-xxx-cover.jpg
banner: /images/myimge/<目录>/wallhaven-xxx-banner.jpg
---
```

- `slug` 由文件名决定；文件名用英文 kebab-case。
- 改 Front Matter 或正文后，由 GitHub Actions 自动部署；无需本地 `hexo deploy`。

## 与本 skill 配合

- 改完文章并 push 后，按 **`hexo-github-sync`** skill 提醒用户同步本机 `F:\my_blog`。
- 需要 Wallhaven 封面时，下载到对应文章目录并记录作品页 URL（非搜索页）。

## 禁止

- 未确认前编造实测数据、BOM 参数或公司/客户信息。
- 把结构卡阶段直接扩成完整长文（除非用户明确要求）。
- 在 `AGENTS.md` 未允许时新建与文章无关的 Markdown 文档。
