import SwiftUI

/// 主内容视图 - 侧边栏 + 内容区
/// 根据选中 Tab 切换不同的功能模块
/// ©️Trigin
struct ContentView: View {
    @EnvironmentObject var store: QuoteStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: SidebarTab = .quotes
    @State private var showFavorites = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            mainContentView
                .frame(minWidth: 600, minHeight: 500)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - 主内容切换
    @ViewBuilder
    private var mainContentView: some View {
        switch selectedTab {
        case .quotes:
            QuoteView(
                store: store,
                showFavorites: $showFavorites
            )
        case .chat:
            ChatMainView()
        case .favorites:
            FavoritesView(store: store)
        }
    }
}

// MARK: - 语录视图（从原 ContentView 抽取）

struct QuoteView: View {
    @ObservedObject var store: QuoteStore
    @Binding var showFavorites: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var copiedAnimation = false
    @State private var cardHover = false

    private var scheme: ColorScheme { colorScheme }
    private var categories: [String] { QuoteData.allCategories }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 44)
                    .padding(.top, 28)

                // 语录分类筛选 chip 栏
                // ©️Trigin — v1.1.0 新增
                categoryChipBar
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                Spacer()

                dailyIndicator
                    .padding(.bottom, 20)

                quoteCardView
                    .padding(.horizontal, 60)
                    .scaleEffect(cardHover ? 1.012 : 1.0)
                    .animation(.easeInOut(duration: 0.35), value: cardHover)
                    .onHover { cardHover = $0 }

                Spacer()

                actionButtonsView
                    .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showFavorites) { FavoritesView(store: store) }
        .overlay(alignment: .center) {
            if copiedAnimation { CopyToastView(scheme: scheme).transition(.opacity.combined(with: .scale)) }
        }
    }

    // MARK: - 分类 Chip 栏（主界面用）

    private var categoryChipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "全部",
                    isSelected: store.selectedDailyCategory == nil,
                    scheme: scheme
                ) {
                    store.selectedDailyCategory = nil
                }

                ForEach(categories, id: \.self) { cat in
                    CategoryChip(
                        label: cat,
                        isSelected: store.selectedDailyCategory == cat,
                        scheme: scheme
                    ) {
                        store.selectedDailyCategory = cat
                    }
                }
            }
            .padding(.horizontal, 44)
        }
    }

    // MARK: - 顶部栏
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formattedDate)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.textTertiary(for: scheme))
                    .tracking(0.5)
                Text("Trigin6Quote")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
            }

            Spacer()

            HStack(spacing: 10) {
                HeaderButton(
                    icon: "bookmark.fill",
                    tooltip: "我的收藏",
                    color: AppTheme.accent,
                    scheme: scheme
                ) { showFavorites = true }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 每日指示器
    private var dailyIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { idx in
                Circle()
                    .fill(idx == store.currentIndex ? AppTheme.accent : AppTheme.textTertiary(for: scheme).opacity(0.25))
                    .frame(width: idx == store.currentIndex ? 10 : 6, height: idx == store.currentIndex ? 10 : 6)
                    .animation(.easeInOut(duration: 0.25), value: store.currentIndex)
            }
        }
    }

    // MARK: - 语录卡片
    private var quoteCardView: some View {
        VStack(spacing: 32) {
            Image(systemName: "quote.opening")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AppTheme.accent.opacity(0.6))

            Text(store.currentQuote.text)
                .font(.system(size: store.quoteFontSize, weight: .medium, design: .serif))
                .foregroundStyle(AppTheme.textPrimary(for: scheme))
                .multilineTextAlignment(.center)
                .lineSpacing(16)
                .frame(maxWidth: 540)
                .fixedSize(horizontal: false, vertical: true)

            if let translation = store.currentQuote.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundStyle(AppTheme.textSecondary(for: scheme).opacity(0.9))
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .frame(maxWidth: 480)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Image(systemName: "quote.closing")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AppTheme.accent.opacity(0.6))

            VStack(spacing: 10) {
                Rectangle()
                    .fill(AppTheme.accent.opacity(0.4))
                    .frame(width: 36, height: 1)

                Text(store.currentQuote.author)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(AppTheme.accentText(for: scheme))

                Text(QuoteData.normalizedCategory(for: store.currentQuote))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.textTertiary(for: scheme))
                    .tracking(1.5)
                    .textCase(.uppercase)
            }
        }
        .padding(56)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground(for: scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.cardBorder(for: scheme), lineWidth: 1)
        )
        .shadow(
            color: scheme == .light
                ? Color.black.opacity(0.06)
                : Color.black.opacity(0.45),
            radius: scheme == .light ? 40 : 56,
            y: scheme == .light ? 16 : 20
        )
    }

    // MARK: - 操作按钮
    private var actionButtonsView: some View {
        HStack(spacing: 20) {
            ActionButton(
                icon: store.isFavorite(store.currentQuote) ? "heart.fill" : "heart",
                label: "收藏",
                color: store.isFavorite(store.currentQuote) ? AppTheme.accentText(for: scheme) : AppTheme.textSecondary(for: scheme),
                scheme: scheme
            ) { store.toggleFavorite(store.currentQuote) }

            ActionButton(
                icon: "doc.on.doc",
                label: "复制",
                color: AppTheme.textSecondary(for: scheme),
                scheme: scheme
            ) {
                store.copyQuote(store.currentQuote)
                triggerCopyAnimation()
            }

            ActionButton(
                icon: "square.and.arrow.up",
                label: "分享",
                color: AppTheme.textSecondary(for: scheme),
                scheme: scheme
            ) {
                showShareSheet()
            }

            ActionButton(
                icon: "arrow.left",
                label: "上一条",
                color: AppTheme.textSecondary(for: scheme),
                scheme: scheme
            ) {
                store.previousQuote()
            }

            ActionButton(
                icon: "arrow.right",
                label: "下一条",
                color: AppTheme.textSecondary(for: scheme),
                scheme: scheme
            ) {
                store.nextQuote()
            }
        }
    }

    private func triggerCopyAnimation() {
        withAnimation(.easeOut(duration: 0.2)) { copiedAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) { copiedAnimation = false }
        }
    }

    private func showShareSheet() {
        let text = store.shareText(for: store.currentQuote)
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else {
            // 回退方案：如果无法获取窗口，复制到剪贴板
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            triggerCopyAnimation()
            return
        }
        // 弹出系统分享菜单（AirDrop、备忘录、邮件等）
        let picker = NSSharingServicePicker(items: [text])
        picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
    }
}

// MARK: - 顶部按钮

struct HeaderButton: View {
    let icon: String
    let tooltip: String
    var color: Color? = nil
    let scheme: ColorScheme
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color ?? AppTheme.textSecondary(for: scheme))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.buttonBackground(for: scheme, isHovering: hovering))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppTheme.buttonBorder(for: scheme, isHovering: hovering), lineWidth: 1)
                )
                .scaleEffect(hovering ? 1.08 : 1.0)
                .animation(.easeOut(duration: 0.15), value: hovering)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering = $0 }
    }
}

// MARK: - 操作按钮组件

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let scheme: ColorScheme
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(hovering ? AppTheme.accent : color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary(for: scheme))
            }
            .frame(width: 72, height: 72)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.buttonBackground(for: scheme, isHovering: hovering))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .strokeBorder(
                        hovering ? AppTheme.accent.opacity(0.30) : AppTheme.buttonBorder(for: scheme, isHovering: false),
                        lineWidth: 1
                    )
            )
            .scaleEffect(hovering ? 1.06 : 1.0)
            .animation(.easeOut(duration: 0.15), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - 复制提示

struct CopyToastView: View {
    let scheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text("已复制到剪贴板")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary(for: scheme))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.accent.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(
            color: scheme == .light ? Color.black.opacity(0.08) : Color.black.opacity(0.3),
            radius: 20, y: 8
        )
    }
}

// MARK: - 预览

#Preview {
    ContentView()
        .environmentObject(QuoteStore())
        .frame(width: 900, height: 650)
}
