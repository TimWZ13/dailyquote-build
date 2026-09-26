import SwiftUI
import AppKit

/// 菜单栏视图 — 语录预览 + 聊天室内嵌
/// ©️Trigin
struct MenuBarView: View {
    @EnvironmentObject var store: QuoteStore
    @EnvironmentObject var windowOpener: WindowOpener
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @State private var showChat = false
    @StateObject private var chatViewModel = ChatWebViewModel()

    var body: some View {
        Group {
            if showChat {
                chatView
            } else {
                quoteView
            }
        }
        .onAppear {
            // 菜单栏常驻，捕获 openWindow 用于"显示主窗口"（即便主窗口已关闭也能重新打开）
            windowOpener.openMain = {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - 聊天室视图（内嵌在菜单栏中，不弹出独立窗口）

    private var chatView: some View {
        VStack(spacing: 0) {
            // 顶部返回栏 — 标准高度，标题完整居中显示
            HStack {
                Button {
                    showChat = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(AppTheme.accentText(for: colorScheme))
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)

                Spacer()

                Text("聊天室")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                Spacer()

                // 小提示 — info 图标，悬停显示提示信息
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .padding(.trailing, 14)
                    .help("公共聊天室 · 由 Chatango 提供 · 文明交流")
            }
            .frame(height: 40)
            .background(AppTheme.solidBackground(for: colorScheme))

            Divider()
                .overlay(AppTheme.cardBorder(for: colorScheme))

            // 聊天 WebView 区域
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)

                ChatWebView(viewModel: chatViewModel, isDark: colorScheme == .dark)

                // 加载遮罩
                if chatViewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppTheme.accent)
                        Text("正在连接聊天室...")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.solidBackground(for: colorScheme).opacity(0.92))
                    .allowsHitTesting(false)
                }

                // 错误提示
                if let error = chatViewModel.loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        Text("连接失败")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            chatViewModel.reload()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.solidBackground(for: colorScheme).opacity(0.95))
                }
            }
        }
        .frame(width: 420, height: 520)
        .background(AppTheme.backgroundGradient(for: colorScheme))
    }

    // MARK: - 语录视图

    private var quoteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 语录预览卡片
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(AppTheme.accent)
                    Text("今日6条")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Spacer()
                    Text(Date().shortDate)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Text(store.currentQuote.text)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(4)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let translation = store.currentQuote.translation, !translation.isEmpty {
                    Text(translation)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme).opacity(0.7))
                        .italic()
                        .lineLimit(2)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("—— \(store.currentQuote.author)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentText(for: colorScheme))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
            )

            Divider()
                .overlay(AppTheme.cardBorder(for: colorScheme))

            // 操作按钮
            VStack(spacing: 2) {
                MenuBarButton(icon: "heart", label: "收藏 / 取消收藏", scheme: colorScheme) {
                    store.toggleFavorite(store.currentQuote)
                }

                MenuBarButton(icon: "doc.on.doc", label: "复制语录", scheme: colorScheme) {
                    store.copyQuote(store.currentQuote)
                }

                MenuBarButton(icon: "arrow.right", label: "下一条", scheme: colorScheme) {
                    store.nextQuote()
                }
            }

            Divider()
                .overlay(AppTheme.cardBorder(for: colorScheme))

            // 聊天室入口 — 内嵌在菜单栏中，不弹独立窗口
            MenuBarButton(icon: "bubble.left.and.bubble.right", label: "打开聊天室", scheme: colorScheme) {
                showChat = true
            }

            Divider()
                .overlay(AppTheme.cardBorder(for: colorScheme))

            MenuBarButton(icon: "macwindow", label: "显示主窗口", scheme: colorScheme) {
                windowOpener.openMain?()
            }

            MenuBarButton(icon: "gearshape", label: "设置...", scheme: colorScheme) {
                openSettings()
            }

            Divider()
                .overlay(AppTheme.cardBorder(for: colorScheme))

            MenuBarButton(icon: "power.dotted", label: "退出 Trigin6Quote", scheme: colorScheme, role: .destructive) {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 320)
        .background(
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
        )
    }
}

struct MenuBarButton: View {
    let icon: String
    let label: String
    let scheme: ColorScheme
    var role: ButtonRole?
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                    .foregroundStyle(role == .destructive ? .red : AppTheme.textSecondary(for: scheme))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(role == .destructive ? .red : AppTheme.textPrimary(for: scheme))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovering ? AppTheme.buttonBackground(for: scheme, isHovering: true) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
