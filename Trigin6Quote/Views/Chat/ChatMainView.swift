import SwiftUI

/// 聊天室主入口视图
/// 嵌入 Chatango 聊天室，支持主题自动适配
/// ©️Trigin
struct ChatMainView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var chatViewModel = ChatWebViewModel()
    @State private var showInfoSheet = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 44)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                chatArea
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                footerView
                    .padding(.horizontal, 44)
                    .padding(.bottom, 16)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .sheet(isPresented: $showInfoSheet) {
            ChatInfoView(scheme: colorScheme)
        }
    }

    // MARK: - 顶部栏
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trigin6Quote · 聊天室")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                HStack(spacing: 6) {
                    Circle()
                        .fill(chatViewModel.isLoading ? AppTheme.textTertiary(for: colorScheme) : AppTheme.accent)
                        .frame(width: 6, height: 6)
                    Text(chatViewModel.isLoading ? "连接中..." : "已连接")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }

            Spacer()

            HStack(spacing: 10) {
                HeaderButton(
                    icon: "info.circle",
                    tooltip: "关于聊天室",
                    scheme: colorScheme
                ) { showInfoSheet = true }

                HeaderButton(
                    icon: "arrow.clockwise",
                    tooltip: "重新加载",
                    scheme: colorScheme
                ) {
                    reloadChat()
                }
            }
        }
    }

    // MARK: - 聊天区域
    private var chatArea: some View {
        ZStack {
            // 卡片容器
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .light
                        ? Color.black.opacity(0.06)
                        : Color.black.opacity(0.45),
                    radius: colorScheme == .light ? 40 : 56,
                    y: colorScheme == .light ? 16 : 20
                )

            // WebView
            ChatWebView(viewModel: chatViewModel, isDark: colorScheme == .dark)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .padding(12)

            // 加载遮罩
            if chatViewModel.isLoading {
                loadingOverlay
            }

            // 错误提示
            if let error = chatViewModel.loadError {
                errorOverlay(error: error)
            }
        }
    }

    // MARK: - 加载遮罩
    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.regular)
                .tint(AppTheme.accent)
            Text("正在连接聊天室...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme).opacity(0.85))
        )
        .allowsHitTesting(false)
    }

    // MARK: - 错误遮罩
    private func errorOverlay(error: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Text("连接失败")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text(error)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button(action: reloadChat) {
                Text("重试")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.buttonBackground(for: colorScheme, isHovering: true))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme).opacity(0.92))
        )
        .allowsHitTesting(true)
    }

    // MARK: - 底部信息栏
    private var footerView: some View {
        HStack {
            Text("Powered by Chatango")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Spacer()

            Text("与全球 Trigin6Quote 用户实时交流")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    // MARK: - 方法
    private func reloadChat() {
        chatViewModel.reload()
    }
}

// MARK: - 聊天室信息弹窗

struct ChatInfoView: View {
    let scheme: ColorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accent)
                Text("Trigin6Quote 聊天室")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
            }

            VStack(alignment: .leading, spacing: 12) {
                infoRow(icon: "person.2", title: "公共聊天室", desc: "所有 Trigin6Quote 用户均可加入")
                infoRow(icon: "lock.open", title: "无需注册", desc: "直接以访客身份参与对话")
                infoRow(icon: "text.bubble", title: "实时消息", desc: "发送的消息将实时展示给所有在线用户")
                infoRow(icon: "hand.raised", title: "文明交流", desc: "请遵守社区规范，友善交流")
            }

            Spacer()

            Button("知道了") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: scheme))
        )
    }

    private func infoRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary(for: scheme))
            }
        }
    }
}

// MARK: - 预览

#Preview {
    ChatMainView()
        .frame(width: 800, height: 600)
}
