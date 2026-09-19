# Trigin6Quote · 每日六语录

> 每天六句精选语录，激励你不断前行。
> macOS 菜单栏常驻 · 主窗口沉浸阅读 · 内嵌公共聊天室

![macOS 14+](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/version-1.2.0-brightgreen)

---

## ✨ 功能特性

- **每日六条精选语录** — 基于日期种子确定性生成，同一天内容稳定，次日自动刷新
- **多分类语录库** — 古典、现代、哲思、励志等多分类，支持分类筛选与全文搜索
- **主界面分类筛选** — 顶部 Chip 栏按分类筛选今日 6 条，偏好自动持久化
- **收藏管理** — 一键收藏/取消，收藏数据持久化于 UserDefaults
- **收藏导出 / 导入** — 支持 JSON 导出与导入，可选「合并（跳过重复）」或「替换」两种策略
- **收藏内分类筛选** — 收藏页按分类 Chip 过滤，每类带数量统计
- **菜单栏常驻** — `MenuBarExtra` 实现，点击图标即可预览今日语录、快速操作
- **内嵌聊天室** — 基于 WKWebView 内嵌公共聊天室（由 [Chatango](https://chatango.com) 提供），无需开浏览器即可交流
- **主窗口沉浸阅读** — `NavigationSplitView` 三栏布局：侧边栏 / 语录正文 / 详情
- **首次启动欢迎页** — 动画开场序列：幕布拉开 → 文字浮现 → 流光溢彩 → 开始按钮
- **外观自适应** — 跟随系统深浅色，也可在设置中强制指定
- **字号调节** — 小 / 中 / 大 三档，实时生效
- **开机自启动** — 基于 `SMAppService.mainApp`（macOS 13+ 官方 API，沙盒兼容）
- **键盘快捷键** — `⌘R` 下一条 / `⌘L` 上一条 / `⌘F` 收藏 / `⌘⇧C` 复制 / `⌘0` 显示主窗口
- **分类分布统计** — 设置页可折叠查看各分类语录数量
- **CHANGELOG 入口** — 设置页内置版本更新日志，随时查看历史变更

## 📸 截图

> _TODO: 启动后补充主窗口、菜单栏、聊天室、欢迎页截图_

## 🚀 构建

### 方式一：SwiftPM 命令行（调试用）

```bash
git clone https://github.com/TimWZ13/Trigin6Quote.git
cd Trigin6Quote
swift build
```

产物：`.build/debug/Trigin6Quote`（裸可执行文件，**非 `.app` 包**）。

### 方式二：生成 `.app` 包（推荐分发用）

```bash
swift build -c release
# 生成 .app 包结构
mkdir -p Trigin6Quote.app/Contents/MacOS
cp .build/release/Trigin6Quote Trigin6Quote.app/Contents/MacOS/
# 补 Info.plist 与图标（见下方模板）
```

最小 `Info.plist` 模板：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Trigin6Quote</string>
    <key>CFBundleIdentifier</key>
    <string>com.trigin.trigin6quote</string>
    <key>CFBundleVersion</key>
    <string>1.2.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
```

### 方式三：Xcode（推荐开发用）

```bash
open Package.swift
```

Xcode 会识别 `Package.swift` 自动创建项目，`⌘R` 直接运行调试。

## 📁 项目结构

```
Trigin6Quote/
├── Package.swift                  # SwiftPM 清单
├── README.md
├── LICENSE
└── Trigin6Quote/
    ├── Trigin6QuoteApp.swift      # App 入口、Scene、AppDelegate
    ├── QuoteData.swift            # 语录数据库（内置数百条）
    ├── Models/
    │   └── Quote.swift            # 数据模型
    ├── Stores/
    │   └── QuoteStore.swift       # 状态管理（每日生成、收藏、导出/导入、分类筛选、字号缓存）
    ├── Support/
    │   ├── AppTheme.swift         # 主题配色（深浅色自适应）
    │   ├── ChatWebView.swift      # WKWebView 聊天室封装
    │   └── Date+Extensions.swift  # 日期工具（缓存 DateFormatter）
    └── Views/
        ├── ContentView.swift      # 主窗口根视图 + 分类 Chip 筛选栏
        ├── SidebarView.swift      # 侧边栏
        ├── FavoritesView.swift    # 收藏 / 全部语录（导出/导入 + 收藏内分类筛选）
        ├── WelcomeView.swift      # 首次启动动画欢迎页
        ├── MenuBarView.swift      # 菜单栏视图（语录预览 + 聊天室）
        ├── SettingsView.swift     # 设置面板（分类分布 + CHANGELOG）
        └── Chat/
            └── ChatMainView.swift # 主窗口内聊天室视图
```

## 🎨 设计理念

- **米黄 + 冷白 / 深炭** 的克制配色，避免纯黑纯白的廉价感
- 衬线字体承载语录正文，无衬线字体承载 UI 文案，形成阅读层次
- `MenuBarExtra` 让应用常驻而不打扰，需要时一点即开
- 欢迎页动画序列：黑色幕布拉开 → 文字浮现 → 流光溢彩（Canvas + TimelineView 原生实现）→ 开始按钮

## 🔖 版本编号规则

| 位置 | 含义 | 示例 |
|------|------|------|
| 第 1 位 | 界面大更新 | 主窗口重构、主题重做 |
| 第 2 位 | 功能更新 | 新增导出/导入、分类筛选、欢迎页 |
| 第 3 位 | 修复问题 | Bug 修复、小优化 |

## 📝 版本历史

- **v1.2.0** — 首次启动动画欢迎页（幕布拉开 + 流光溢彩 + 开始按钮）
- **v1.1.0** — 收藏 JSON 导出/导入 + 主界面分类筛选 Chip + 收藏内分类筛选 + 分类分布统计 + CHANGELOG 入口
- **v1.0.0** — 首个正式版本：每日六语录、收藏、复制、分享、菜单栏、聊天室、设置面板

## ⚠️ 关于聊天室

本应用内嵌的聊天室由第三方服务 **Chatango** 提供，聊天室内容、稳定性、 moderation 均由 Chatango 平台负责，本项目不维护聊天室后端。请在聊天室内遵守相关法律法规，文明交流。

## 📜 版权

```
©️Trigin 2026
MIT License
```

本项目采用 [MIT License](./LICENSE) 开源。代码中的 `©️Trigin` 版权声明用于标识原作者，不影响 MIT 协议授予的使用、修改、分发权利。
