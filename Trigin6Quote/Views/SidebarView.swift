import SwiftUI

/// 侧边栏导航视图
/// 提供语录展示和聊天室的切换入口
/// ©️Trigin
struct SidebarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openSettings) private var openSettings
    @Binding var selectedTab: SidebarTab

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo / 品牌区
                brandSection
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                // 导航项
                navigationSection
                    .padding(.horizontal, 10)

                Spacer()

                // 底部版权
                footerSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 200)
    }

    // MARK: - 品牌区
    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Logo 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.14, green: 0.14, blue: 0.15),
                                    Color(red: 0.08, green: 0.08, blue: 0.09)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 36, height: 36)

                    Text("T6")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trigin6Quote")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text("每日6条励志语录")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
    }

    // MARK: - 导航区
    private var navigationSection: some View {
        VStack(spacing: 6) {
            // 语录首页
            SidebarItem(
                icon: "quote.opening",
                title: "每日语录",
                isSelected: selectedTab == .quotes,
                scheme: colorScheme
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .quotes
                }
            }

            // 聊天室
            SidebarItem(
                icon: "bubble.left.and.bubble.right",
                title: "聊天室",
                isSelected: selectedTab == .chat,
                scheme: colorScheme
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .chat
                }
            }

            // 收藏
            SidebarItem(
                icon: "bookmark",
                title: "我的收藏",
                isSelected: selectedTab == .favorites,
                scheme: colorScheme
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .favorites
                }
            }
        }
    }

    // MARK: - 底部版权
    private var footerSection: some View {
        VStack(spacing: 6) {
            Divider()
                .overlay(AppTheme.cardBorder(for: colorScheme).opacity(0.5))

            // 设置按钮
            SidebarItem(
                icon: "gearshape",
                title: "设置",
                isSelected: false,
                scheme: colorScheme
            ) {
                openSettings()
            }

            Text("©️Trigin 2026")
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 侧边栏 Tab 枚举

enum SidebarTab: String, CaseIterable, Identifiable {
    case quotes = "quotes"
    case chat = "chat"
    case favorites = "favorites"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quotes: return "每日语录"
        case .chat: return "聊天室"
        case .favorites: return "我的收藏"
        }
    }
}

// MARK: - 侧边栏单项

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let scheme: ColorScheme
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? Color(red: 0.12, green: 0.11, blue: 0.10)
                            : AppTheme.textSecondary(for: scheme)
                    )
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected
                            ? Color(red: 0.12, green: 0.11, blue: 0.10)
                            : AppTheme.textPrimary(for: scheme)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? AppTheme.accent
                            : (hovering
                                ? AppTheme.buttonBackground(for: scheme, isHovering: true)
                                : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? AppTheme.accent.opacity(0.8) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

// MARK: - 预览

#Preview {
    SidebarView(selectedTab: .constant(.quotes))
        .frame(width: 200)
}

#Preview {
    SidebarView(selectedTab: .constant(.chat))
        .frame(width: 200)
        .colorScheme(.dark)
}
