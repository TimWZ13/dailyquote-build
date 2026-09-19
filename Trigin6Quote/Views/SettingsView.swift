import SwiftUI
import AppKit
import ServiceManagement

/// 设置视图 — 外观、字号、分享等实际可配置项
/// ©️Trigin
struct SettingsView: View {
    @EnvironmentObject var store: QuoteStore
    @Environment(\.colorScheme) private var colorScheme

    // 外观模式：0=跟随系统 1=浅色 2=深色
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    // 字号：0=小 1=中 2=大
    @AppStorage("quoteFontSize") private var quoteFontSize: Int = 1
    // 分享时附带应用签名
    @AppStorage("shareWithSignature") private var shareWithSignature: Bool = true
    // 开机自启动 — 通过 SMAppService 注册（macOS 13+，沙盒/App Store 兼容）
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    // v1.1.0 新增
    @State private var showChangelog = false
    @State private var expandCategoryBreakdown = false

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            aboutSettings
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 520)
        .sheet(isPresented: $showChangelog) {
            ChangelogView(scheme: colorScheme)
        }
    }

    // MARK: - 通用设置

    private var generalSettings: some View {
        Form {
            Section("外观") {
                Picker("显示模式", selection: $appearanceMode) {
                    Text("跟随系统").tag(0)
                    Text("浅色模式").tag(1)
                    Text("深色模式").tag(2)
                }
                .pickerStyle(.segmented)
                .onChange(of: appearanceMode) { _, newValue in
                    // 通知 App 重新应用配色
                    NotificationCenter.default.post(name: .appearanceDidChange, object: nil)
                }

                Picker("语录字号", selection: $quoteFontSize) {
                    Text("小").tag(0)
                    Text("中").tag(1)
                    Text("大").tag(2)
                }
                .pickerStyle(.segmented)
                .onChange(of: quoteFontSize) { _, _ in
                    NotificationCenter.default.post(name: .fontSizeDidChange, object: nil)
                }
            }

            Section("分享") {
                Toggle("分享时附带应用签名", isOn: $shareWithSignature)
                    .onChange(of: shareWithSignature) { _, _ in
                        NotificationCenter.default.post(name: .sharePreferenceDidChange, object: nil)
                    }
            }

            Section("启动") {
                Toggle("开机自启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        guard AppInfo.isProperlyBundled else {
                            print("开机自启动仅在打包为 .app 后可用（当前为调试模式）")
                            return
                        }
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                            print("开机自启动设置失败: \(error.localizedDescription)")
                        }
                    }
                    .onAppear {
                        guard AppInfo.isProperlyBundled else { return }
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
            }

            Section("语录数据") {
                HStack {
                    Text("总语录数")
                    Spacer()
                    Text("\(store.totalQuoteCount) 条")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                HStack {
                    Text("每日展示")
                    Spacer()
                    Text("6 条")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                HStack {
                    Text("已收藏")
                    Spacer()
                    Text("\(store.favorites.count) 条")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                // v1.1.0 新增：分类计数（可折叠）
                DisclosureGroup(isExpanded: $expandCategoryBreakdown) {
                    VStack(spacing: 6) {
                        ForEach(store.categoryCounts, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                Spacer()
                                Text("\(item.count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.accentText(for: colorScheme))
                            }
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    HStack {
                        Text("分类分布")
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Text("\(store.categoryCounts.count) 类")
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - 关于

    private var aboutSettings: some View {
        VStack(spacing: 16) {
            Image(systemName: "6.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent)

            Text("Trigin6Quote")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text("每天六句精选语录，激励你不断前行")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("共 \(store.totalQuoteCount) 条精选语录 · \(store.categoryCounts.count) 个分类")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Spacer()
                .frame(height: 4)

            // v1.1.0 新增：版本更新日志按钮
            Button {
                showChangelog = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                    Text("版本更新日志 (CHANGELOG)")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.buttonBackground(for: colorScheme, isHovering: false))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.buttonBorder(for: colorScheme, isHovering: false), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("查看当前版本与历史版本的更新说明")

            Spacer()

            Text("\(AppInfo.copyright)  v\(AppInfo.version)")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - CHANGELOG 弹窗视图
// ©️Trigin

struct ChangelogView: View {
    let scheme: ColorScheme
    @Environment(\.dismiss) private var dismiss

    /// 版本更新记录（最新在最前）
    private let entries: [(version: String, date: String, title: String, items: [String])] = [
        (
            version: "v1.2.0",
            date: "2026-09-02",
            title: "功能更新：首次启动欢迎页",
            items: [
                "【新功能】首次启动时弹出动画欢迎页，展示品牌形象",
                "【动画】幕布拉开 → 文字浮现 → 流光溢彩 → 开始按钮，完整开场序列",
                "【技术】原生 SwiftUI Canvas + TimelineView 实现流光和条纹动画",
                "【体验】仅在首次启动时显示，之后不再打扰；用户可随时在设置中重置"
            ]
        ),
        (
            version: "v1.1.0",
            date: "2026-07-29",
            title: "功能更新：收藏导出/导入 + 分类筛选",
            items: [
                "【新功能】收藏页新增 JSON 导出 / 导入，支持「合并」和「替换」两种策略",
                "【新功能】主界面顶部新增分类 Chip 筛选栏，可按分类查看今日 6 条",
                "【新功能】收藏页新增收藏内分类 Chip 筛选，带每类数量显示",
                "【新功能】设置页「通用」新增分类分布统计（可折叠查看每类语录数）",
                "【新功能】设置页「关于」新增 CHANGELOG 版本更新日志入口",
                "【体验】导入/导出结果、写入失败等操作统一使用底部 Toast 提示",
                "【优化】用户选择的主界面分类筛选偏好会持久化，下次启动自动恢复",
                "【规范】版本号规则确定：第1位=界面大更新，第2位=功能更新，第3位=修复问题"
            ]
        ),
        (
            version: "v1.0.0",
            date: "2026-07-29",
            title: "首个正式版本发布",
            items: [
                "每天随机 6 条精选语录卡片浏览，每日结果固定",
                "收藏 / 取消收藏、复制、系统分享（AirDrop/备忘录等）",
                "侧边栏：每日语录、聊天室、我的收藏、全部语录（搜索+分类筛选）",
                "菜单栏扩展：快捷打开主窗口 / 聊天室 / 下一条 / 收藏",
                "设置：外观（跟随/浅色/深色）、语录字号、开机自启动、分享签名",
                "聊天室 WebView：遮挡右上角系统关闭按钮，防止误关",
                "每日语录与收藏状态自动持久化到 UserDefaults"
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("版本更新日志")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: scheme))
                    Text("©️Trigin · 版本编号：界面.功能.修复")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary(for: scheme))
                }
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)

            Divider().overlay(AppTheme.cardBorder(for: scheme))

            // 列表
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(entries, id: \.version) { entry in
                        versionEntry(entry)
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 560, height: 540)
        .background(AppTheme.solidBackground(for: scheme))
    }

    private func versionEntry(_ entry: (version: String, date: String, title: String, items: [String])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(entry.version)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(scheme == .light ? .black : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(AppTheme.accent)
                    )
                Text(entry.date)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary(for: scheme))
                Spacer()
            }

            Text(entry.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(for: scheme))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("·")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary(for: scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.cardBorder(for: scheme), lineWidth: 1)
        )
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let appearanceDidChange = Notification.Name("appearanceDidChange")
    static let fontSizeDidChange = Notification.Name("fontSizeDidChange")
    static let sharePreferenceDidChange = Notification.Name("sharePreferenceDidChange")
}
