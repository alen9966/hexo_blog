# Code Wiki - 硬件项目手记（Hexo 博客）

## 目录

1. [项目概述](#1-项目概述)
2. [整体架构](#2-整体架构)
3. [目录结构](#3-目录结构)
4. [核心配置文件](#4-核心配置文件)
5. [主题（Reimu）架构详解](#5-主题reimu架构详解)
6. [源码目录（source）结构](#6-源码目录source结构)
7. [脚手架（scaffolds）说明](#7-脚手架scaffolds说明)
8. [MATLAB 仿真脚本体系](#8-matlab-仿真脚本体系)
9. [关键工具函数与模块](#9-关键工具函数与模块)
10. [标签插件系统](#10-标签插件系统)
11. [Helper 辅助函数](#11-helper-辅助函数)
12. [Generator 生成器](#12-generator-生成器)
13. [依赖关系图](#13-依赖关系图)
14. [项目运行方式](#14-项目运行方式)
15. [写作规范与约定（AGENTS.md）](#15-写作规范与约定agentsmd)

---

## 1. 项目概述

### 1.1 项目简介

本项目是一个基于 **Hexo 7.3.0** 静态博客系统构建的硬件技术博客——**「硬件项目手记」**。博客主题为「按项目记录原理图、PCB、问题和调试」，专注于硬件设计、电源拓扑、通信原理、FPGA/Verilog、示波器校准等硬件工程领域的项目记录和技术学习笔记。

### 1.2 技术栈

| 层次 | 技术选型 | 版本 | 说明 |
|------|----------|------|------|
| 站点框架 | Hexo | 7.3.0 | 静态博客生成器 |
| 博客主题 | hexo-theme-reimu | 1.12.5 | 博丽灵梦风格的 Hexo 主题（开源） |
| 渲染引擎 | Markdown-it-plus | 1.2.4 | 支持 LaTeX、自定义容器的 Markdown 渲染器 |
| 模板引擎 | EJS / Pug | - | 主题模板渲染 |
| 样式预处理器 | Stylus | 3.0.1 | 主题样式编译 |
| 数学公式 | MathJax / KaTeX | - | 渲染 LaTeX 数学公式 |
| 部署方式 | hexo-deployer-git | 4.0.0 | Git Pages 部署 |
| 仿真工具 | MATLAB | - | 生成技术图表（波特图、波形图等） |

### 1.3 项目元信息

- **站点名称**: 硬件项目手记
- **副标题**: 按项目记录原理图、PCB、问题和调试
- **描述**: 从原理图到实测波形，记录硬件设计中的选择、失误与验证
- **作者**: Alen
- **语言**: 简体中文（zh-CN）
- **时区**: Asia/Shanghai
- **部署地址**: https://alen9966.github.io
- **部署分支**: main

---

## 2. 整体架构

### 2.1 系统分层图

```
┌──────────────────────────────────────────────────────────────┐
│                     部署层 (Deployment)                        │
│   GitHub Pages (alen9966.github.io)  ──  hexo-deployer-git   │
└──────────────────────────────────────────────────────────────┘
                              ▲
                              │ hexo generate (构建 public/)
┌──────────────────────────────────────────────────────────────┐
│                      构建层 (Build Layer)                      │
│                                                              │
│  ┌─────────────┐   ┌──────────────┐   ┌───────────────────┐ │
│  │  Hexo 核心  │──▶│  Renderer    │──▶│  Theme (Reimu)    │ │
│  │  (CLI/API)  │   │  (md/ejs/styl)│   │  模板/样式/脚本  │ │
│  └─────────────┘   └──────────────┘   └───────────────────┘ │
│         │                                                    │
│         ▼                                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   source/ (内容源)                    │    │
│  │  _posts/  about/  projects/  images/  _data/  css/  │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
                              ▲
                              │ 写作 / 编辑
┌──────────────────────────────────────────────────────────────┐
│                      内容层 (Content Layer)                    │
│  Markdown 博客文章 + MATLAB 仿真脚本 + PDF/原理图素材          │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 构建流程

```
用户写作 (.md) + 配置 (.yml) + 资源 (images)
         │
         ▼
   hexo generate (调用构建管线)
         │
         ├──▶ 读取 scaffolds 模板生成页面骨架
         ├──▶ Markdown-it-plus 渲染正文（支持 LaTeX 公式）
         ├──▶ EJS 渲染主题模板（layout/）
         ├──▶ Stylus 编译主题样式（source/css/）
         ├──▶ Helper 函数注入辅助逻辑
         ├──▶ Tag 标签插件处理自定义标签
         ├──▶ Generator 生成归档/搜索/404 等页面
         │
         ▼
    public/ 目录（静态 HTML/CSS/JS）
         │
         ▼
    hexo deploy → GitHub Pages
```

---

## 3. 目录结构

```
/workspace/
├── .github/
│   └── dependabot.yml                 # Dependabot 依赖自动更新配置
├── .trae-html-share-packages/         # Trae IDE 主题预览相关
│   └── themes/Sakura/                 # Sakura 主题备用资源（ZIP 包）
├── matlab/                            # MATLAB 仿真脚本（生成技术图表）
│   ├── am/
│   │   └── generate_am_blog_figures.m
│   ├── ldo/
│   │   ├── generate_ldo_stability_plots.m
│   │   └── ldo_stability_results.txt
│   └── transfer-function/
│       ├── generate_transfer_function_figures.m
│       └── transfer_function_results.txt
├── scaffolds/                         # Hexo 文章模板脚手架
│   ├── draft.md                       # 草稿模板
│   ├── page.md                        # 独立页面模板
│   └── post.md                        # 博客文章模板
├── source/                            # 内容源目录（核心）
│   ├── .nojekyll                      # 禁用 Jekyll 处理（GitHub Pages）
│   ├── _data/                         # 数据文件（被主题 scripts 读取）
│   │   ├── avatar/avatar.webp         # 作者头像
│   │   └── covers.yml                 # 文章封面 URL 列表
│   ├── _drafts/                       # 草稿目录
│   ├── _posts/                        # 博客文章目录（15 篇已发布）
│   ├── about/index.md                 # 关于页面
│   ├── css/                           # 自定义 CSS
│   │   ├── custom.css
│   │   └── site-home.css
│   ├── files/                         # 原始文件（PDF 等）
│   │   └── oscilloscope-power/SCH_Schematic1_1_2026-07-21.pdf
│   ├── images/                        # 图片资源
│   │   ├── anime/                     # 动漫风格装饰图（约 16 张）
│   │   ├── myimge/                    # 博客正文用图（按文章分子目录）
│   │   ├── projects/                  # 项目页专属图片（PCB、原理图 SVG）
│   │   ├── hero-banner.jpg
│   │   └── home-*.png / *.jpg
│   └── projects/index.md              # 项目列表页
├── themes/                            # Hexo 主题目录
│   ├── Sakura/                        # 备用主题（未启用，保留）
│   ├── reimu/                         # 当前启用主题（Reimu v1.12.5）
│   │   ├── _config.yml                # 主题内配置
│   │   ├── languages/                 # i18n 多语言文件（5 种语言）
│   │   ├── layout/                    # EJS 模板文件
│   │   ├── scripts/                   # 主题扩展脚本（Hexo 钩子）
│   │   ├── source/                    # 主题静态资源（CSS/JS/图片）
│   │   └── package.json
│   └── .gitkeep
├── tmp/pdfs/                          # 临时 PDF 切图缓存
├── .gitignore
├── AGENTS.md                          # AI 代理写作规范（详细规范见第 15 节）
├── _config.landscape.yml              # Landscape 主题备用配置
├── _config.reimu.yml                  # Reimu 主题外部配置（可覆盖内层配置）
├── _config.yml                        # Hexo 主配置文件（核心）
├── package-lock.json
└── package.json                       # npm 项目清单
```

---

## 4. 核心配置文件

### 4.1 `_config.yml` — Hexo 主配置

**路径**: [_config.yml](file:///workspace/_config.yml)

| 配置项 | 值 | 说明 |
|--------|----|------|
| `title` | 硬件项目手记 | 站点标题 |
| `subtitle` | 按项目记录原理图、PCB、问题和调试 | 副标题 |
| `description` | 从原理图到实测波形... | SEO 描述 |
| `author` | Alen | 作者名 |
| `language` | zh-CN | 默认语言 |
| `timezone` | Asia/Shanghai | 时区 |
| `url` | https://alen9966.github.io | 站点 URL |
| `root` | / | 根路径 |
| `permalink` | :year/:month/:day/:title/ | 永久链接格式 |
| `source_dir` | source | 内容源目录 |
| `public_dir` | public | 构建输出目录 |
| `theme` | reimu | **当前主题：reimu** |
| `syntax_highlighter` | highlight.js | 代码高亮方案 |
| `deploy.type` | git | 部署方式 |
| `deploy.repository` | git@github.com:alen9966/alen9966.github.io.git | 部署仓库 |
| `deploy.branch` | main | 部署分支 |
| `markdown_it_plus.rawLaTeX` | true | 保留 LaTeX 分隔符供 MathJax 渲染 |

### 4.2 `themes/reimu/_config.yml` — 主题内配置

**路径**: [themes/reimu/_config.yml](file:///workspace/themes/reimu/_config.yml)

核心配置分区：

1. **基础配置**：菜单导航、副标题打字效果、banner、favicon、avatar、cover、TOC、Open Graph
2. **侧边栏**：`position: right`、社交链接、小部件（category/tag/tagcloud/archive/recent_posts）
3. **页脚**：since 2020、powered、count（字数统计）、busuanzi（访客统计）、太极旋转图标
4. **Markdown 显示**：代码块展开/折叠、复制提示、Clipboard 版权追加、段落锚点
5. **评论系统**：支持 8 种评论系统（Valine/Waline/Twikoo/Gitalk/Giscus/Utterances/Beaudar/Disqus），默认 waline
6. **搜索**：Algolia 搜索 / 本地 generator_search（二选一）
7. **动画**：preloader（"少女祈祷中..."）、AOS 滚动动画、Firework 鼠标特效、Pace 进度条
8. **扩展功能**：回到顶部（太极图标）、暗黑模式（auto）、Reimu 鼠标指针、赞助商、ICP 备案、文章过期提醒、Live2D、PJAX、ServiceWorker
9. **数学公式**：KaTeX / MathJax3（二选一）
10. **Vendor CDN**：6 个 CDN 源可选，所有第三方 JS/CSS 支持 SRI SHA-384 校验
11. **内置主题色**：红色系（--red-0 ~ --red-6）、代码高亮色变量，light/dark 双模式

### 4.3 `package.json` — npm 项目清单

**路径**: [package.json](file:///workspace/package.json)

```json
{
  "name": "hexo-site",
  "hexo": { "version": "7.3.0" },
  "scripts": {
    "build": "hexo generate",     // 构建静态站点
    "clean": "hexo clean",         // 清理 public/ 和 .db.json
    "deploy": "hexo deploy",       // 部署到 GitHub Pages
    "server": "hexo server"        // 本地预览（默认 4000 端口）
  }
}
```

---

## 5. 主题（Reimu）架构详解

当前启用主题：**hexo-theme-reimu v1.12.5**（开源项目，D-Sketon 维护）。

主题完全遵循 Hexo 扩展规范，通过 `scripts/` 目录在构建生命周期中注入逻辑。

### 5.1 主题目录结构

```
themes/reimu/
├── _config.yml              # 主题配置（可被根目录 _config.reimu.yml 覆盖）
├── package.json             # 主题包元信息（MIT 协议）
├── README.md / README.en.md # 主题使用文档
├── languages/               # i18n 多语言字典
│   ├── en.yml
│   ├── zh-CN.yml
│   ├── zh-TW.yml
│   ├── ja.yml
│   └── pt-BR.yml
├── layout/                  # EJS 模板层
│   ├── layout.ejs           # **总布局模板**（所有页面入口）
│   ├── index.ejs            # 首页
│   ├── post.ejs             # 文章详情页
│   ├── page.ejs             # 独立页面（about/projects）
│   ├── archive.ejs          # 归档页
│   ├── category.ejs         # 分类页
│   ├── tag.ejs              # 标签页
│   ├── 404.ejs              # 404 页面
│   ├── _partial/            # 局部模板
│   │   ├── head.ejs         # <head> 标签内容（CSS/CDN/SEO）
│   │   ├── header.ejs       # 顶部导航栏
│   │   ├── footer.ejs       # 页脚
│   │   ├── loader.ejs       # 预加载动画
│   │   ├── article.ejs      # 文章主体渲染
│   │   ├── post.ejs         # 文章元信息（日期/分类/标签/TOC）
│   │   ├── sidebar.ejs      # 侧边栏容器
│   │   ├── mobile-nav.ejs   # 移动端导航
│   │   ├── after-footer.ejs # 底部脚本注入（JS 库）
│   │   ├── archive-post.ejs # 归档列表项
│   │   ├── analytics/       # 百度/谷歌/Clarity 统计脚本
│   │   ├── post/            # 文章页子部件（comment/share/sponsor/gallery/nav 等）
│   │   └── sidebar/         # 侧边栏子部件（common-sidebar/toc-sidebar）
│   └── _widget/             # 侧边栏小部件
│       ├── category.ejs
│       ├── tag.ejs
│       ├── tagcloud.ejs
│       ├── archive.ejs
│       └── recent_posts.ejs
├── scripts/                 # **主题扩展脚本**（构建时执行，分 5 类）
│   ├── util/                # 启动时工具（配置校验/版本检查）
│   ├── filter/              # Filter 钩子（stylus 编译）
│   ├── generator/           # Generator 钩子（生成额外页面）
│   ├── helper/              # Helper 函数（模板中可调用）
│   └── tag/                 # Tag 标签插件（Markdown 中可用）
└── source/                  # 主题静态资源（直接拷贝到 public/）
    ├── css/                 # 样式文件（Stylus 编译 + 预编译 CSS）
    │   ├── style.styl       # 主样式入口
    │   ├── _partial/*.styl  # 分模块样式（article/header/footer/sidebar/mobile...）
    │   ├── _variables.styl  # CSS 变量定义
    │   └── *.min.css        # 第三方库预编译 CSS
    ├── js/                  # JavaScript 文件
    │   ├── script.js        # 主题主脚本（暗黑模式/搜索/导航/Tab...）
    │   ├── pjax.js          # PJAX 无刷新导航
    │   ├── anchor.js        # 段落锚点
    │   └── *.min.js         # 第三方库（APlayer/fancybox/InsightSearch/zoom 等）
    ├── fonts/               # 字体文件（FontAwesome/iconfont）
    └── images/              # 主题图片（banner/favicon/cursor/太极/封面...）
```

### 5.2 布局渲染链

```
layout.ejs（总布局）
  ├─ head.ejs
  │   ├─ analytics/*（百度/谷歌/Clarity 统计）
  │   ├─ CSS：loader.css / style.css / vendor CDN CSS
  │   └─ SEO：meta/description/keywords/OpenGraph
  ├─ loader.ejs（预加载动画："少女祈祷中..."）
  ├─ header.ejs（顶部导航菜单 + banner）
  ├─ content 区
  │   ├─ sidebar.ejs（侧边栏）
  │   │   ├─ common-sidebar.ejs（作者信息/社交/widget）
  │   │   └─ toc-sidebar.ejs（文章目录 TOC）
  │   └─ <section id="main"> → 由具体页面填充（body）
  │       ├─ index.ejs → _widget/index-items.ejs
  │       ├─ post.ejs → article.ejs → _partial/post/*
  │       ├─ page.ejs → common-page.ejs
  │       ├─ archive.ejs → archive-post.ejs
  │       └─ ...
  ├─ footer.ejs（版权/ICP/统计/太极图标）
  ├─ 回到顶部按钮（太极）
  ├─ mobile-nav.ejs（移动端菜单）
  ├─ 搜索弹窗（algolia/generator_search）
  ├─ 音乐播放器（Aplayer/Meting）
  ├─ after-footer.ejs
  │   └─ vendor CDN JS：clipboard/lazysizes/photoswipe/waline/firework/pace...
  └─ injector.body_end（自定义代码注入）
```

---

## 6. 源码目录（source）结构

### 6.1 `_posts/` — 已发布博客文章

共 15 篇文章，全部围绕硬件工程主题：

| 文件名 | 主题领域 |
|--------|----------|
| `am-modulation-demodulation-basics.md` | 通信原理：AM 调制解调入门 |
| `linear-regulator-and-ldo-basics.md` | 电源：线性稳压器与 LDO 基础 |
| `llc-resonant-half-bridge-from-specs-to-parameters.md` | 电源拓扑：LLC 谐振半桥设计 |
| `power-topologies-selection-from-buck-to-psfb.md` | 电源拓扑选型：Buck 到 PSFB |
| `transfer-function-from-differential-equation.md` | 控制理论：微分方程到传递函数 |
| `100mhz-output-impedance-smith-chart-vna.md` | RF：100MHz 输出阻抗 Smith 图 VNA 测量 |
| `nanovna-s11-ocxo-impedance.md` | 仪器：NanoVNA S11 测 OCXO 阻抗 |
| `phase-noise-53100a-100mhz-ocxo.md` | 测试：53100A 相位噪声测量 |
| `time-synchronization-and-100mhz-clock-test-learning-log.md` | 时钟：时间同步与 100MHz 时钟测试 |
| `oscilloscope-calibrator-power.md` | 项目：示波器校准器电源设计 |
| `oscilloscope-time-interleaving-and-spectrum-slicing.md` | ADC/示波器：时间交织与频谱切片 |
| `tida-01028-schematic-deep-dive.md` | 方案拆解：TI TIDA-01028 原理图深度分析 |
| `verilog-from-module-to-always.md` | FPGA：Verilog 从 module 到 always 块入门 |
| `ultrasonic-flaw-detector-panel.md` | 项目：超声波探伤仪面板 |
| `project-writing-framework.md` | 方法论：项目写作框架 |

### 6.2 文章 Front Matter 示例

以 [am-modulation-demodulation-basics.md](file:///workspace/source/_posts/am-modulation-demodulation-basics.md#L1-L18) 为例：

```yaml
---
title: 从一段声音到无线电波：AM 调制与解调入门
slug: am-modulation-demodulation-basics
date: 2026-07-25 10:00:00
tags: [通信原理, 模拟电路, AM, 调制与解调]
categories: [学习记录]
description: 从低频基带信号为什么需要调制出发，理解 AM 的信号模型...
banner: /images/myimge/wallhaven-pink/wallhaven-3zl3e3.jpg   # 文章页头图
cover:  /images/myimge/wallhaven-pink/wallhaven-qz655l.jpg   # 列表卡片封面
author: Alen
authorLink: https://github.com/alen9966
authorAbout: 从原理图到实测波形，记录硬件设计中的选择、失误与验证。
---
```

### 6.3 `images/myimge/` — 文章配图目录

每篇文章对应一个独立子目录，图片按用途命名，全站单图只引用一次：

```
images/myimge/
├── am-modulation/              # AM 文章图（16 张：波形图+PDF裁剪）
├── ldo-basics/                 # LDO 文章图（12 张：控制环+波特图）
├── llc-resonant-half-bridge/   # LLC 文章图（10 张：拓扑+波形）
├── power-topologies/           # 电源拓扑文章图（30+ 张：各拓扑原理）
├── transfer-function/          # 传递函数文章图（7 张：阶跃+波特）
├── 100mhz-impedance-matching/  # 阻抗匹配文章图（4 张：Smith 图）
├── nanovna-s11-ocxo/           # NanoVNA 文章图（3 张 SVG+照片）
├── phase-noise-53100a-ocxo/    # 相位噪声文章图（5 张）
├── tida-01028/                 # TIDA-01028 原理图裁剪
│   ├── schematic-deep-dive/    # 5 张关键电路页
│   └── time-interleaving/      # 4 张讲解框图
├── time-sync-learning-log/     # 时间同步文章图（3 张 SVG）
├── verilog-basics/             # Verilog 文章图（4 张培训PPT）
├── wallhaven-pink/             # **公共装饰图库**（粉色二次元壁纸 18 张）
└── ...（散图）
```

### 6.4 `_data/` — 主题读取的数据文件

| 文件 | 被哪个脚本读取 | 作用 |
|------|----------------|------|
| `avatar/avatar.webp` | [scripts/generator/images.js](file:///workspace/themes/reimu/scripts/generator/images.js) | 拷贝到 `public/avatar/`，作为作者头像 |
| `covers.yml` | [scripts/generator/images.js](file:///workspace/themes/reimu/scripts/generator/images.js) | 解析 YAML 中的 URL 列表，加入封面随机池 |

---

## 7. 脚手架（scaffolds）说明

Hexo 在创建新内容时会使用 `scaffolds/` 中的模板作为 Front Matter 骨架。

### 7.1 `post.md` — 博客文章模板

**路径**: [scaffolds/post.md](file:///workspace/scaffolds/post.md)

```yaml
---
title: {{ title }}   # Hexo 会替换为用户传入的标题
date: {{ date }}     # 自动填入当前时间
tags:                # 空数组，写作时补
---
```

创建命令：
```bash
hexo new "文章标题"        # 使用 post 模板
hexo new post "文章标题"   # 同上，显式指定
```

### 7.2 `page.md` — 独立页面模板

**路径**: [scaffolds/page.md](file:///workspace/scaffolds/page.md)

```yaml
---
title: {{ title }}
date: {{ date }}
---
```

创建命令：
```bash
hexo new page "about"      # 生成 source/about/index.md
```

### 7.3 `draft.md` — 草稿模板

**路径**: [scaffolds/draft.md](file:///workspace/scaffolds/draft.md)

```yaml
---
title: {{ title }}
tags:
---
```

草稿默认不会被渲染发布（`render_drafts: false`）。

---

## 8. MATLAB 仿真脚本体系

### 8.1 脚本目录与职责

| 目录 | 脚本文件 | 对应文章 | 功能 |
|------|----------|----------|------|
| `matlab/am/` | `generate_am_blog_figures.m` | AM 调制解调入门 | 生成基带/载波/AM 波形、频谱、调制度对比、相干解调、包络检波理论示意图 |
| `matlab/ldo/` | `generate_ldo_stability_plots.m` | LDO 基础 | 生成 ESR 零极点、环路波特图、闭环极点稳定性分析图 |
| `matlab/transfer-function/` | `generate_transfer_function_figures.m` | 传递函数入门 | 生成 RLC 模型、RL 阶跃/波特图、反馈极点与阶跃响应图 |

### 8.2 脚本典型结构（以 AM 为例）

```matlab
% 1. 参数声明（物理量化）
fm = 1e3;    % 基带频率
fc = 20e3;   % 载波频率
fs = 2e6;    % 采样率
mu = 0.5;    % 调制度

% 2. 信号生成
t = 0:1/fs:3/fm;
baseband = cos(2*pi*fm*t);
carrier  = cos(2*pi*fc*t);
am = (1 + mu*baseband) .* carrier;

% 3. 调用绘图函数（每个图对应一个文章配图）
makeBasebandCarrier(outputDir, t, baseband, carrier, fm, fc);
makeAmWaveformSpectrum(outputDir, t, am, envelope, fm, fc, mu);
makePdfCrops(pdfPageDir, outputDir);  % 同时裁剪 PDF 局部
```

**设计约束**（来自 AGENTS.md）：
- 输出图片必须保存到 `source/images/myimge/<文章名>/`
- 保留可复现的 `.m` 脚本，写明参数、元件值、频率范围
- 图中必须标注坐标轴、单位、图例、转折频率
- 区分理论示意 / 软件仿真 / 硬件实测

---

## 9. 关键工具函数与模块

### 9.1 `util/checkConfig.js` — 配置一致性校验

**路径**: [themes/reimu/scripts/util/checkConfig.js](file:///workspace/themes/reimu/scripts/util/checkConfig.js)

**触发时机**：`hexo.on("generateBefore")`（构建开始前）

**核心函数**：
- `warnIf(condition, message)`：条件为真时输出警告日志
- `isModuleInstalled(moduleName)`：`require.resolve` 判断 npm 包是否安装

**校验项**（共 9 项）：

| 校验 | 冲突条件 | 警告 |
|------|----------|------|
| 1 | pjax.enable && relative_link | PJAX 与相对链接不兼容 |
| 2 | highlight 未启用 | 必须启用 highlight.js |
| 3 | math.katex && math.mathjax | KaTeX 和 MathJax 不能同时开 |
| 4 | algolia_search && generator_search | 两种搜索不能同时开 |
| 5 | 启用数学 + 安装了 hexo-renderer-marked | 需卸载 marked，改用 markdown-it-plus |
| 6 | 启用数学 + 未安装 @reimujs/hexo-renderer-markdown-it-plus | 缺少渲染器依赖 |
| 7 | live2d && live2d_widgets | 两种 Live2D 不能同时开 |
| 8 | player.aplayer && !pjax | 播放器建议开启 PJAX 防止中断 |
| 9 | player.meting && !player.aplayer | Meting 依赖 Aplayer |
| 10 | i18n 第一语言 ≠ site.language | 默认语言不一致 |

### 9.2 `util/checkVersion.js` — 主题版本检查

**路径**: [themes/reimu/scripts/util/checkVersion.js](file:///workspace/themes/reimu/scripts/util/checkVersion.js)

**触发时机**：
- `generateBefore`：打印 Reimu 主题 ASCII Logo
- `generateAfter`：HTTPS 请求 GitHub Releases API，对比最新版本

**关键函数**：
- `parseVersion(rawVersion)`：`"1.12.5"` → `[1, 12, 5]`（整型数组）
- `isVersionGreater(latest, current)`：逐位比较版本号，判断是否需要升级
- 8s 超时，超时/失败输出友好提示，不阻断构建

---

## 10. 标签插件系统

Reimu 主题通过 `scripts/tag/*.js` 注册了一批自定义 Markdown 标签，由 `hexo.extend.tag.register()` 注入 Hexo 渲染管线。

### 10.1 标签插件清单

| 标签文件 | 标签名 | 功能 | 用法示例 |
|----------|--------|------|----------|
| [link.js](file:///workspace/themes/reimu/scripts/tag/link.js) | `{% link %}` | **推荐**：统一内链/外链卡片 | `{% link slug "标题" /img/cover.jpg true %}` |
| [postLinkCard.js](file:///workspace/themes/reimu/scripts/tag/postLinkCard.js) | `{% postLinkCard %}` | 内链卡片（不推荐，已被 link 替代） | `{% postLinkCard slug auto %}` |
| [externalLinkCard.js](file:///workspace/themes/reimu/scripts/tag/externalLinkCard.js) | `{% externalLinkCard %}` | 外链卡片（不推荐，已被 link 替代） | `{% externalLinkCard "title" url auto %}` |
| [friendLink.js](file:///workspace/themes/reimu/scripts/tag/friendLink.js) | `{% friendsLink %}` | 批量渲染友情链接卡片（读取 YAML） | `{% friendsLink path/to/data.yml %}` |
| [tabs.js](file:///workspace/themes/reimu/scripts/tag/tabs.js) | `{% tabs %}...{% endtabs %}` | 创建标签页切换内容 | `{% tabs 1 "center" %}<!-- tab1 -->内容{% endtabs %}` |
| [gallery.js](file:///workspace/themes/reimu/scripts/tag/gallery.js) | `{% gallery %}...{% endgallery %}` | 照片墙自动排列 | `{% gallery %}![alt](url1)![alt](url2){% endgallery %}` |
| [grid.js](file:///workspace/themes/reimu/scripts/tag/grid.js) | `{% grid %}...{% endgrid %}` | 响应式网格布局 | `{% grid 300 col:3 %}<!-- cell -->内容{% endgrid %}` |
| [heatMapCard.js](file:///workspace/themes/reimu/scripts/tag/heatMapCard.js) | `{% heatMapCard %}` | 文章热力图（按字数分级配色） | `{% heatMapCard "1000,5000,10000" %}` |
| [tagRoulette.js](file:///workspace/themes/reimu/scripts/tag/tagRoulette.js) | `{% tagRoulette %}` | 标签轮盘（点击随机展示标签） | `{% tagRoulette "标签1,标签2" 🎲 %}` |
| [alertBlockquote.js](file:///workspace/themes/reimu/scripts/tag/alertBlockquote.js) | `{% alertBlockquote %}` | 警告引用块（5 种类型） | `{% alertBlockquote warning "注意" %}内容{% endalertBlockquote %}` |
| [details.js](file:///workspace/themes/reimu/scripts/tag/details.js) | `{% details %}` | 折叠详情块 | `{% details "点击展开" %}内容{% enddetails %}` |

### 10.2 `link` 标签核心逻辑

[tag/link.js](file:///workspace/themes/reimu/scripts/tag/link.js#L22-L123) 是最复杂的标签，其参数解析流程：

```
输入 args = [target, title?, cover?, escape?]
        │
        ├──▶ looksLikeExternalLink(target)?
        │      │ Yes → 外链模式：target 即 href，description = 链接图标+URL
        │      │ No  → 内链模式：target = slug#hash
        │                     ├── 查 Post 模型（by slug/title）
        │                     ├── 取 post.title / post.excerpt / post.lang
        │                     └── cover=="auto" → fallback 到全局 banner
        │
        ├──▶ escape = (lastArg == "true"/"false") ? args.pop() : "true"
        │
        └──▶ 输出 HTML 卡片结构
             <div class="post-link-card-wrap">
               <div class="post-link-card">
                 <a href="link" ...></a>
                 <div class="post-link-card-cover-wrap">封面图</div>
                 <div class="post-link-card-item-wrap">
                   <div class="post-link-card-title">标题</div>
                   <div class="post-link-card-excerpt">摘要</div>
                 </div>
               </div>
             </div>
```

---

## 11. Helper 辅助函数

所有 Helper 注册在 `scripts/helper/*.js`，通过 `hexo.extend.helper.register()` 注入，在 EJS 模板中可直接调用。

### 11.1 Helper 清单

| 文件 | 函数名 | 职责 |
|------|--------|------|
| [config.js](file:///workspace/themes/reimu/scripts/helper/config.js) | `themeConfig` | 注入主题配置到页面 `<script>` 中（前端可见） |
| [cache.js](file:///workspace/themes/reimu/scripts/helper/cache.js) | `tagCached` | 模板缓存（减少重复渲染） |
| [i18n.js](file:///workspace/themes/reimu/scripts/helper/i18n.js) | `partialLang` | 支持按语言局部渲染模板（多语言） |
| [vendorCdn.js](file:///workspace/themes/reimu/scripts/helper/vendorCdn.js) | `vendorCdn()` / `vendorCdnIntegrity()` | CDN 源解析 + SRI 哈希 |
| [vendorFont.js](file:///workspace/themes/reimu/scripts/helper/vendorFont.js) | `vendorFont` / `vendorGoogleFont` | 字体 CSS 预加载生成 |
| [asyncCss.js](file:///workspace/themes/reimu/scripts/helper/asyncCss.js) | `asyncCss` | 生成 `<link rel=preload>` 异步加载 CSS |
| [randomCover.js](file:///workspace/themes/reimu/scripts/helper/randomCover.js) | `randomCover` | Fisher-Yates 洗牌从封面池随机取图（不重复） |
| [articleCopyright.js](file:///workspace/themes/reimu/scripts/helper/articleCopyright.js) | `articleCopyright` | 生成文章页版权卡片 HTML |
| [copyright.js](file:///workspace/themes/reimu/scripts/helper/copyright.js) | `copyright` | Clipboard 复制时的版权追加逻辑 |
| [wordCount.js](file:///workspace/themes/reimu/scripts/helper/wordCount.js) | `wordcount` / `min2read` | 字数统计和阅读时长估算 |
| [outdate.js](file:///workspace/themes/reimu/scripts/helper/outdate.js) | `outdate` | 文章过期提醒（默认 >180 天） |
| [shareLink.js](file:///workspace/themes/reimu/scripts/helper/shareLink.js) | `shareLink` | 生成社交平台分享 URL（支持微信二维码卡片） |
| [stripHtml.js](file:///workspace/themes/reimu/scripts/helper/stripHtml.js) | `stripHTML` | 剥离 HTML 标签（配合 excerpt 生成） |
| [parseHomeCategories.js](file:///workspace/themes/reimu/scripts/helper/parseHomeCategories.js) | `parseHomeCategories` | 首页目录卡片解析 |
| [listCategories.js](file:///workspace/themes/reimu/scripts/helper/listCategories.js) | `listCategories` | 分类树 HTML 渲染 |
| [listTags.js](file:///workspace/themes/reimu/scripts/helper/listTags.js) | `listTags` | 标签列表 HTML 渲染 |
| [partialLang.js](file:///workspace/themes/reimu/scripts/helper/partialLang.js) | `partialLang` | 按语言渲染局部模板 |

### 11.2 `vendorCdn` 核心机制

[vendorCdn.js](file:///workspace/themes/reimu/scripts/helper/vendorCdn.js#L4-L46) 支持 3 种资源地址格式：

```
1. CDN 别名形式（推荐，可一键切换 CDN 源）：
   "webcache|clipboard@2.0.11/dist/clipboard.min.js"
   → vendor["webcache"] + "clipboard@2.0.11/..."
   → "https://npm.webcache.cn/clipboard@2.0.11/dist/clipboard.min.js"

   可用别名：cdn_jsdelivr_gh / cdn_jsdelivr_npm / fastly_jsdelivr_gh /
            fastly_jsdelivr_npm / unpkg / webcache

2. 绝对 URL：
   "https://cdn.jsdelivr.net/npm/..."

3. 本地资源：
   "/images/banner.webp"
   → 由 hexo-util.url_for() 处理（考虑 root 前缀）
```

同时支持从对象形式 `{src, integrity}` 中提取 SRI SHA-384 哈希，生成 `<link integrity="...">` 防止 CDN 篡改。

### 11.3 `randomCover` — 封面随机策略

[randomCover.js](file:///workspace/themes/reimu/scripts/helper/randomCover.js#L14-L29) 使用 Fisher-Yates 洗牌算法保证同一构建过程中不重复使用封面：

```
初始化 shuffledCovers = []
每次调用：
  if (shuffledCovers 空 或 已取完)
    shuffledCovers = 洗牌(covers)   // Fisher-Yates 原地打乱
    currentIndex = 0
  return shuffledCovers[currentIndex++]
```

封面池数据由 `generator/images.js` 预先读取并放入 `hexo.locals.covers`。

---

## 12. Generator 生成器

注册在 `scripts/generator/*.js`，由 `hexo.extend.generator.register()` 注入，在构建阶段额外生成页面文件。

### 12.1 Generator 清单

| 文件 | 注册名 | 功能 | 输出路径 |
|------|--------|------|----------|
| [images.js](file:///workspace/themes/reimu/scripts/generator/images.js) | `images` | 扫描 `_data/avatar/` 和 `_data/covers/` 目录，将图片拷入 public，解析 `covers.yml` 填充 `hexo.locals.covers` 随机池 | `public/avatar/*`, `public/covers/*` |
| [search.js](file:///workspace/themes/reimu/scripts/generator/search.js) | `json` | 生成本地搜索 JSON 索引（当 `generator_search.enable=true`） | `public/search.json` |
| [404.js](file:///workspace/themes/reimu/scripts/generator/404.js) | - | 生成 404 页面 | `public/404.html` |
| [i18n.js](file:///workspace/themes/reimu/scripts/generator/i18n.js) | `i18n` | 为多语言生成镜像页面（如 `/en/2024/.../`） | 各语言子目录 |
| [override.js](file:///workspace/themes/reimu/scripts/generator/override.js) | - | 覆盖 Hexo 默认归档/分类/标签生成器（兼容 reimu 特色） | - |
| [servicework.js](file:///workspace/themes/reimu/scripts/generator/servicework.js) | - | 生成 Service Worker 缓存清单（离线访问） | `public/sw.js` |

### 12.2 `images.js` 数据流图

```
source/_data/avatar/*.webp
        │
        ├─ walkFile(avatarDir, "avatar/")
        │      ├── 向 result 加 {path:"avatar/xxx.webp", data:ReadStream}
        │      └─ 拷贝到 public/avatar/xxx.webp
        │
source/_data/covers/*.jpg
        │
        ├─ walkFile(coverDir, "covers/")
        │      ├── 向 result 加 {path:"covers/xxx.jpg", data:ReadStream}
        │      ├── 拷贝到 public/covers/xxx.jpg
        │      └── 向 covers[] 推 "/covers/xxx.jpg"
        │
source/_data/covers.yml
        │
        └─ loadYaml()
               └── 解析 YAML 数组 → 每个 URL 推入 covers[]
        │
        ▼
hexo.locals.set("covers", covers)   → 被 randomCover() Helper 使用
```

### 12.3 `search.js` 索引结构

[search.js](file:///workspace/themes/reimu/scripts/generator/search.js#L1-L84) 生成 `search.json`，结构：

```jsonc
[
  {
    "title": "文章标题",
    "url": "/2026/07/25/am-modulation-demodulation-basics/",
    "content": "<Markdown 原文正文>",    // 当 config.content=true 时
    "tags": ["通信原理", "AM"],
    "categories": ["学习记录"]
  },
  // ... page 同理
]
```

前端由 `source/js/generator_search.js` 读取并检索。

---

## 13. 依赖关系图

### 13.1 npm 核心依赖

```
hexo@7.3.0
├─ hexo-generator-index@3          → 首页文章列表
├─ hexo-generator-archive@2        → 归档页
├─ hexo-generator-category@2       → 分类页
├─ hexo-generator-tag@2            → 标签页
├─ hexo-generator-feed@3           → RSS/Atom
├─ hexo-generator-json-content@4   → 内容 JSON
├─ hexo-deployer-git@4             → 部署到 git 仓库
├─ hexo-server@3                   → 本地开发服务器
├─ hexo-renderer-ejs@2             → .ejs 渲染
├─ hexo-renderer-pug@3             → .pug 渲染
├─ hexo-renderer-stylus@3          → .styl 样式编译
├─ @reimujs/hexo-renderer-markdown-it-plus@1  → .md 渲染（支持 LaTeX/容器）
├─ hexo-tag-bili@1                 → 嵌入 Bilibili 视频
├─ hexo-tag-fancybox_img@1         → Fancybox 图片灯箱
└─ hexo-theme-landscape@1          → 备用 landscape 主题

hexo-theme-reimu@1.12.5（themes/reimu/package.json）
```

### 13.2 主题 scripts 内部依赖链

```
scripts/util/
├── checkVersion.js （HTTPS 取 GitHub release）
│   └── 读取 themes/reimu/package.json
└── checkConfig.js （生成前校验）
    └── 检查 npm 包安装状态（hexo-renderer-marked 等）

scripts/generator/
├── images.js
│   ├── 读取 source/_data/avatar/, _data/covers/, covers.yml
│   └── 写入 hexo.locals.covers
│       └── 被 helper/randomCover.js 消费
└── search.js
    └── 输出 search.json
        └── 被 source/js/generator_search.js 前端消费

scripts/helper/
├── vendorCdn.js → EJS 模板中所有 CDN <script>/<link>
├── randomCover.js → _widget/index-items 等模板取封面
└── ...

scripts/tag/
└── link.js / tabs.js / ... → Markdown 正文渲染
```

---

## 14. 项目运行方式

### 14.1 前置环境

| 环境 | 版本要求 | 验证 |
|------|----------|------|
| Node.js | >= 14 (推荐 18+) | `node -v` |
| npm | 随 Node 安装 | `npm -v` |
| Git | 任意（用于部署） | `git -v` |
| MATLAB | 可选（仅需重新生成仿真图时） | `matlab -version` |

### 14.2 首次安装

```bash
# 克隆项目
git clone <repo-url> && cd <repo>

# 安装依赖（生成 node_modules/ 和 package-lock.json）
npm install
```

### 14.3 常用命令

| 命令 | npm script 等价 | 作用 |
|------|-----------------|------|
| `hexo server` | `npm run server` | **本地预览**：启动开发服务器（http://localhost:4000），热重载 |
| `hexo clean` | `npm run clean` | **清理**：删除 `public/` 目录和 `.db.json` 缓存 |
| `hexo generate` | `npm run build` | **构建**：生成 `public/` 静态站（所有 HTML/CSS/JS） |
| `hexo deploy` | `npm run deploy` | **部署**：将 `public/` 推到 GitHub Pages 的 main 分支 |
| `hexo new "标题"` | - | **新建文章**：基于 scaffolds/post.md 生成 `source/_posts/标题.md` |
| `hexo new page "名字"` | - | **新建页面**：生成 `source/名字/index.md` |
| `hexo new draft "标题"` | - | **新建草稿**：生成 `source/_drafts/标题.md`（默认不发布） |
| `hexo publish "标题"` | - | 把草稿从 `_drafts/` 移动到 `_posts/` |

### 14.4 标准开发-发布流程

```bash
# 1. 新建文章
hexo new "我的新项目记录"

# 2. 本地写作 + 实时预览
hexo server
# 浏览器打开 http://localhost:4000

# 3. （可选）如需重绘 MATLAB 仿真图
cd matlab/ldo
matlab -batch "generate_ldo_stability_plots"

# 4. 清理 + 构建
hexo clean
hexo generate

# 5. 部署到 GitHub Pages
hexo deploy
```

### 14.5 构建产物（`public/` 目录）

```
public/
├── index.html                  # 首页
├── archives/index.html         # 归档页
├── categories/*/index.html     # 各分类页
├── tags/*/index.html           # 各标签页
├── about/index.html            # 关于页
├── projects/index.html         # 项目页
├── 404.html                    # 404 页
├── 2026/07/25/<slug>/index.html  # 每篇文章的永久链接页面
├── css/                        # 编译后的样式文件
├── js/                         # 编译后脚本
├── images/                     # 图片资源
├── avatar/                     # 头像（来自 _data/avatar/）
├── covers/                     # 封面（来自 _data/covers/）
├── atom.xml                    # RSS Feed
├── search.json                 # 本地搜索索引（若开启）
└── sw.js / manifest.json       # Service Worker（若开启）
```

---

## 15. 写作规范与约定（AGENTS.md）

**路径**: [AGENTS.md](file:///workspace/AGENTS.md)

这是本项目最重要的「隐性架构」文件，约束了 AI 代理在撰写/修改博客时的行为边界。核心要点摘要如下（完整内容请直接阅读源文件）。

### 15.1 图片来源铁律

1. **唯一来源**：Wallhaven（粉色/浅暖/二次元/治愈/SFW）
2. **唯一保存位置**：`source/images/myimge/<文章名>/`
3. **唯一引用路径**：`/images/myimge/<文件名>`（站点路径，不含本地绝对路径）
4. **单图单引**：全站每张图最多被引用一次（banner/cover/正文插图互斥）
5. **PDF 截图**：截局部，标注资料名+页码，放对应段落旁，随后的文字必须讲「这是什么 + 为什么这样设计 + 哪些是确定/待验证」

### 15.2 技术博客写作铁律

| 禁止行为 | 正确做法 |
|----------|----------|
| 用 AI 口吻（"等你测到..."、"从你给的原理图..."） | 用作者视角（"后续实测会关注..."、"这里预留了测试点..."） |
| 写成"原理图识别报告"（"可以看到..."、"文字层显示..."） | 写设计思路（"它是什么 → 为什么需要 → 这里为什么这样设计"） |
| 把未测结论写成事实 | 明确标注：设计目标 / 已确定 / 尚待验证 |
| 每节末尾机械重复总结 | 信息原则上只完整解释一次 |
| 用"较高的开关频率"这类形容词 | 用量化参数："300kHz"、"10V dropout" |
| 强行套默认结构（背景→目标→...→总结） | 没有内容的章节直接省略 |

### 15.3 长期写作流程

用户提供素材后，按以下阶段推进，用户说「开始写正文」才动笔：

```
阶段 1：整理事实/目标/判断/待验证/疑点/缺资料
        ↓
阶段 2：最多提 3 个实质影响方向的问题
        ↓
阶段 3：输出「文章结构卡」
        文章要解决的问题 / 目标读者 / 读者收益
        / 建议章节+每节核心信息 / 图片和数据 / 待补资料 / 不写入内容
        ↓
阶段 4：与用户确认 标题/摘要/切入方式/结尾/分类/标签/PDF截图清单
        ↓
阶段 5：用户说「开始写正文」→ 生成完整文章
        ↓
阶段 6：发布前自检
  □ 删掉图后，陌生人仍知道「做什么、为什么、现在到哪一步」
  □ 没有一句话听起来像 AI 在对作者说话
```

### 15.4 作者表达风格

- **基调**：工程师给同学讲清一个刚弄明白的问题，直接朴素
- **节奏**：从实际需求 / 曾经没理解的问题切入；先直观后定义；先公式物理意义后公式
- **公式**：先讲式子描述的物理关系；推导保留关键中间步骤；推导后立即用普通语言解释每一项
- **段落**：短段落，普通结论直接说，不用论文长句
- **MATLAB 图**：保留可复现 `.m`；坐标轴/单位/图例/转折频率必须标清；区分理论示意 / 软件仿真 / 硬件实测

---

*本文档由项目代码结构自动分析生成。若目录、配置或脚本发生变更，应同步更新本 Wiki。*
