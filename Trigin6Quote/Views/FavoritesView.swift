import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FavoritesView: View {
    @ObservedObject var store: QuoteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isPresented) private var isPresented

    // 收藏内分类筛选
    @State private var selectedCategory: String? = nil
    // 导入策略选择（导入前弹窗用）
    @State private var pendingImportData: Data? = nil
    @State private var showImportStrategyAlert = false
    // 结果提示
    @State private var toastMessage: String? = nil
    @State private var toastTask: DispatchWorkItem? = nil

    /// 收藏中出现过的所有归一化分类
    private var favoriteCategories: [String] {
        let cats = Set(store.favorites.map { QuoteData.normalizedCategory(for: $0) })
        return cats.sorted()
    }

    /// 按分类筛选后的收藏
    private var filteredFavorites: [Quote] {
        guard let selectedCategory else { return store.favorites }
        return store.favorites.filter { QuoteData.normalizedCategory(for: $0) == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if !store.favorites.isEmpty {
                        categoryChipBar
                        Divider().overlay(AppTheme.cardBorder(for: colorScheme))
                    }

                    Group {
                        if store.favorites.isEmpty {
                            ContentUnavailableView(
                                "暂无收藏",
                                systemImage: "bookmark",
                                description: Text("点击语录卡片下方的收藏按钮来保存喜欢的语录")
                            )
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        } else if filteredFavorites.isEmpty {
                            ContentUnavailableView(
                                "该分类暂无收藏",
                                systemImage: "tag.slash",
                                description: Text("试试切换其他分类或选择「全部」")
                            )
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredFavorites) { quote in
                                        QuoteRowView(quote: quote, store: store, scheme: colorScheme)
                                    }
                                }
                                .padding(24)
                            }
                        }
                    }
                }

                // Toast
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: message.contains("失败") || message.contains("解析") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(message.contains("失败") || message.contains("解析") ? Color.orange : AppTheme.accent)
                            Text(message)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 16, y: 6)
                        .padding(.bottom, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: toastMessage)
                }
            }
            .navigationTitle(store.favorites.isEmpty ? "我的收藏" : "我的收藏 (\(store.favorites.count))")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            exportFavorites()
                        } label: {
                            Label("导出收藏…", systemImage: "square.and.arrow.up")
                        }
                        .disabled(store.favorites.isEmpty)

                        Button {
                            chooseImportFile()
                        } label: {
                            Label("导入收藏…", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 32)
                    .help("收藏管理（导出 / 导入）")
                }
                if isPresented {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
            }
            .alert("导入收藏", isPresented: $showImportStrategyAlert, presenting: pendingImportData) { data in
                Button("合并（跳过重复）") {
                    let summary = store.importFavorites(from: data, strategy: .merge)
                    showToast(summary.message)
                    pendingImportData = nil
                }
                Button("替换（清空后导入）", role: .destructive) {
                    let summary = store.importFavorites(from: data, strategy: .replace)
                    showToast(summary.message)
                    pendingImportData = nil
                }
                Button("取消", role: .cancel) {
                    pendingImportData = nil
                }
            } message: { _ in
                Text("选择导入策略：\n• 合并：保留当前收藏，新增不重复的条目\n• 替换：清空当前收藏，完全以文件内容替代")
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    // MARK: - 分类 Chip 栏

    private var categoryChipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "全部 (\(store.favorites.count))",
                    isSelected: selectedCategory == nil,
                    scheme: colorScheme
                ) { selectedCategory = nil }

                ForEach(favoriteCategories, id: \.self) { cat in
                    let count = store.favorites.filter { QuoteData.normalizedCategory(for: $0) == cat }.count
                    CategoryChip(
                        label: "\(cat) (\(count))",
                        isSelected: selectedCategory == cat,
                        scheme: colorScheme
                    ) { selectedCategory = cat }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    // MARK: - 导出

    private func exportFavorites() {
        guard let data = store.exportFavoritesData() else {
            showToast("导出失败：无法生成数据")
            return
        }
        let savePanel = NSSavePanel()
        savePanel.title = "导出收藏"
        savePanel.prompt = "导出"
        savePanel.nameFieldStringValue = defaultExportFilename()
        savePanel.allowedContentTypes = [UTType.json]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try data.write(to: url, options: .atomic)
                showToast("已导出 \(store.favorites.count) 条收藏")
            } catch {
                showToast("写入失败：\(error.localizedDescription)")
            }
        }
    }

    private func defaultExportFilename() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN_POSIX")
        fmt.dateFormat = "yyyyMMdd"
        return "Trigin6Quote-Favorites-\(fmt.string(from: Date())).json"
    }

    // MARK: - 导入

    private func chooseImportFile() {
        let panel = NSOpenPanel()
        panel.title = "选择收藏文件"
        panel.prompt = "导入"
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                pendingImportData = data
                showImportStrategyAlert = true
            } catch {
                showToast("读取失败：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Toast

    private func showToast(_ msg: String) {
        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = msg
        }
        let task = DispatchWorkItem {
            withAnimation(.easeIn(duration: 0.25)) {
                toastMessage = nil
            }
        }
        toastTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: task)
    }
}

struct AllQuotesView: View {
    @ObservedObject var store: QuoteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedCategory: String?

    private var categories: [String] {
        QuoteData.allCategories
    }

    private var filteredQuotes: [Quote] {
        var quotes = QuoteData.quotesInCategory(selectedCategory)

        if !searchText.isEmpty {
            quotes = quotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        return quotes
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                label: "全部",
                                isSelected: selectedCategory == nil,
                                scheme: colorScheme
                            ) { selectedCategory = nil }

                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    label: category,
                                    isSelected: selectedCategory == category,
                                    scheme: colorScheme
                                ) { selectedCategory = category }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }

                    Divider()
                        .overlay(AppTheme.cardBorder(for: colorScheme))

                    if filteredQuotes.isEmpty {
                        ContentUnavailableView("未找到匹配语录", systemImage: "magnifyingglass")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredQuotes) { quote in
                                    QuoteRowView(quote: quote, store: store, scheme: colorScheme)
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
            .navigationTitle("全部语录 (\(QuoteData.uniqueQuotes.count) 条)")
            .searchable(text: $searchText, prompt: "搜索语录或作者")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(width: 640, height: 720)
    }
}

// MARK: - 分类标签

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isSelected
                        ? (scheme == .light ? Color(red: 0.15, green: 0.14, blue: 0.13) : Color.black)
                        : AppTheme.textSecondary(for: scheme)
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? AppTheme.accent
                                : AppTheme.buttonBackground(for: scheme, isHovering: false)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : AppTheme.buttonBorder(for: scheme, isHovering: false),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 语录行

struct QuoteRowView: View {
    let quote: Quote
    @ObservedObject var store: QuoteStore
    let scheme: ColorScheme
    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(quote.text)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                if let translation = quote.translation, !translation.isEmpty {
                    Text(translation)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary(for: scheme).opacity(0.7))
                        .italic()
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Text(quote.author)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.accentText(for: scheme))

                    Spacer()

                    Text(QuoteData.normalizedCategory(for: quote))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary(for: scheme))
                }
            }

            VStack(spacing: 10) {
                Button(action: { store.toggleFavorite(quote) }) {
                    Image(systemName: store.isFavorite(quote) ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(store.isFavorite(quote) ? AppTheme.accent : AppTheme.textTertiary(for: scheme))
                }
                .buttonStyle(.plain)

                Button(action: {
                    store.copyQuote(quote)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showCopied = false
                    }
                }) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundStyle(showCopied ? AppTheme.accent : AppTheme.textTertiary(for: scheme))
                }
                .buttonStyle(.plain)
            }
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
