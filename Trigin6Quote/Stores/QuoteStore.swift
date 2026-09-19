import Foundation
import SwiftUI
import AppKit

@MainActor
final class QuoteStore: ObservableObject {
    @Published var currentQuote: Quote
    @Published var dailyQuotes: [Quote] = []
    @Published var currentIndex: Int = 0
    @Published var favorites: [Quote] = []
    @Published var viewedDates: [Date: Quote] = [:]
    @Published private(set) var quoteFontSize: CGFloat

    /// 用户当前选中的「每日分类」。nil 表示跨全部分类（默认）。
    /// 用于主界面顶部的分类 chip 筛选。©️Trigin
    @Published var selectedDailyCategory: String? {
        didSet {
            UserDefaults.standard.set(selectedDailyCategory, forKey: "selectedDailyCategory")
            regenerateDailyQuotes(keepingIndex: true)
        }
    }

    private let allQuotes: [Quote]
    private let favoritesKey = "favoriteQuotes"
    private let currentIndexKey = "currentTrigin6Index"

    init() {
        let allQ = QuoteData.uniqueQuotes
        let favs = Self.loadFavoritesStatic()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "lastTrigin6Date") as? Date
        let savedIndices = UserDefaults.standard.array(forKey: "dailyTrigin6Indices") as? [Int]
        let savedIndex = UserDefaults.standard.integer(forKey: "currentTrigin6Index")
        // 恢复上次选中的分类筛选（如果有）
        let restoredCategory = UserDefaults.standard.string(forKey: "selectedDailyCategory")

        var daily: [Quote] = []
        var idx: Int = 0

        if restoredCategory == nil,
           let savedDate = savedDate,
           calendar.isDate(savedDate, inSameDayAs: today),
           let savedIndices = savedIndices,
           savedIndices.count == 6,
           savedIndex < 6 {
            // 同一天 + 未启用分类筛选，恢复跨分类结果
            daily = savedIndices.compactMap { i in allQ[safe: i] }
            idx = savedIndex
        } else {
            // 新的一天、数据损坏或已启用分类筛选，重新生成
            let pool = restoredCategory.flatMap { QuoteData.quotesInCategory($0) } ?? allQ
            daily = Self.generateTrigin6Quotes(from: pool, for: today)
            idx = 0
            if restoredCategory == nil {
                // 只在无分类筛选时保存为"今日默认6条"
                let indices = daily.compactMap { q in allQ.firstIndex { $0.id == q.id } }
                UserDefaults.standard.set(indices, forKey: "dailyTrigin6Indices")
                UserDefaults.standard.set(today, forKey: "lastTrigin6Date")
                UserDefaults.standard.set(0, forKey: "currentTrigin6Index")
            }
        }

        let quote = (idx < daily.count) ? daily[idx] : (daily.first ?? Quote(text: "今日语录加载中...", author: "", category: ""))

        self.allQuotes = allQ
        self.favorites = favs
        self.dailyQuotes = daily
        self.currentIndex = idx
        self.currentQuote = quote
        self._selectedDailyCategory = Published(initialValue: restoredCategory)
        // 启动时读一次字号缓存，避免每次渲染都访问 UserDefaults
        self.quoteFontSize = Self.computeFontSize()

        // 监听字号变更通知，刷新缓存（由 SettingsView 发出）
        NotificationCenter.default.addObserver(
            forName: .fontSizeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshFontSize() }
        }
    }

    /// 根据当前 selectedDailyCategory 重新抽取 dailyQuotes。
    /// - Parameter keepingIndex: true 时尽量保持 currentIndex 不变，否则归零
    private func regenerateDailyQuotes(keepingIndex: Bool) {
        let pool = selectedDailyCategory.flatMap { QuoteData.quotesInCategory($0) } ?? allQuotes
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let newDaily = Self.generateTrigin6Quotes(from: pool, for: today)
        guard !newDaily.isEmpty else { return }
        dailyQuotes = newDaily
        let newIdx = keepingIndex ? min(currentIndex, newDaily.count - 1) : 0
        currentIndex = newIdx
        currentQuote = newDaily[newIdx]
    }

    private static func computeFontSize() -> CGFloat {
        switch UserDefaults.standard.integer(forKey: "quoteFontSize") {
        case 0: return 22  // 小
        case 2: return 34  // 大
        default: return 28 // 中（默认）
        }
    }

    private func refreshFontSize() {
        quoteFontSize = Self.computeFontSize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var totalQuoteCount: Int {
        allQuotes.count
    }

    var currentDisplayIndex: Int {
        currentIndex + 1
    }

    // MARK: - 收藏导出 / 导入（JSON）
    // ©️Trigin

    /// 将当前收藏导出为 JSON Data，附带元信息（版本、导出时间、总数）
    func exportFavoritesData() -> Data? {
        let exportInfo = FavoritesExport(
            appVersion: AppInfo.version,
            exportedAt: Date(),
            count: favorites.count,
            quotes: favorites
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(exportInfo)
    }

    /// 从 JSON Data 导入收藏，默认策略：合并（skip 已存在的），并返回导入摘要
    @discardableResult
    func importFavorites(from data: Data, strategy: ImportStrategy = .merge) -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let payload = try decoder.decode(FavoritesExport.self, from: data)
            let incoming = payload.quotes
            guard !incoming.isEmpty else {
                return ImportSummary(imported: 0, skipped: 0, total: 0, message: "文件中无收藏数据")
            }
            switch strategy {
            case .merge:
                var inserted = 0
                for q in incoming where !isFavorite(q) {
                    favorites.append(q)
                    inserted += 1
                }
                saveFavorites()
                return ImportSummary(
                    imported: inserted,
                    skipped: incoming.count - inserted,
                    total: incoming.count,
                    message: "合并完成：新增 \(inserted) 条，跳过 \(incoming.count - inserted) 条重复"
                )
            case .replace:
                favorites = incoming
                saveFavorites()
                return ImportSummary(
                    imported: incoming.count,
                    skipped: 0,
                    total: incoming.count,
                    message: "已替换为导入文件中的 \(incoming.count) 条收藏"
                )
            }
        } catch {
            return ImportSummary(imported: 0, skipped: 0, total: 0, message: "解析失败：\(error.localizedDescription)")
        }
    }

    enum ImportStrategy {
        case merge    // 合并：跳过已存在的（默认）
        case replace  // 替换：清空当前收藏后导入
    }

    struct ImportSummary {
        let imported: Int
        let skipped: Int
        let total: Int
        let message: String
    }

    // MARK: - 分类统计

    /// 返回各归一化分类的语录数量（供设置页展示）
    var categoryCounts: [(category: String, count: Int)] {
        var dict: [String: Int] = [:]
        for q in allQuotes {
            let cat = QuoteData.normalizedCategory(for: q)
            dict[cat, default: 0] += 1
        }
        return dict.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    func nextQuote() {
        guard !dailyQuotes.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentIndex = (currentIndex + 1) % dailyQuotes.count
            currentQuote = dailyQuotes[currentIndex]
        }
        UserDefaults.standard.set(currentIndex, forKey: currentIndexKey)
    }

    func previousQuote() {
        guard !dailyQuotes.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentIndex = (currentIndex - 1 + dailyQuotes.count) % dailyQuotes.count
            currentQuote = dailyQuotes[currentIndex]
        }
        UserDefaults.standard.set(currentIndex, forKey: currentIndexKey)
    }

    func isFavorite(_ quote: Quote) -> Bool {
        favorites.contains { $0.id == quote.id }
    }

    func toggleFavorite(_ quote: Quote) {
        if isFavorite(quote) {
            favorites.removeAll { $0.id == quote.id }
        } else {
            favorites.append(quote)
        }
        saveFavorites()
    }

    func copyQuote(_ quote: Quote) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        var text = quote.text
        if let translation = quote.translation, !translation.isEmpty {
            text += "\n\n\(translation)"
        }
        text += "\n\n—— \(quote.author)"
        pasteboard.setString(text, forType: .string)
    }

    func shareText(for quote: Quote) -> String {
        var text = quote.text
        if let translation = quote.translation, !translation.isEmpty {
            text += "\n\n\(translation)"
        }
        text += "\n\n—— \(quote.author)"
        // 根据用户设置决定是否附带应用签名
        if UserDefaults.standard.bool(forKey: "shareWithSignature") {
            text += "\n\n来自 Trigin6Quote"
        }
        return text
    }

    /// 根据用户设置返回语录字号（缓存版，见上方 @Published quoteFontSize）
    /// 字号变更由 .fontSizeDidChange 通知触发 refreshFontSize()

    private static func generateTrigin6Quotes(from quotes: [Quote], for date: Date) -> [Quote] {
        guard quotes.count >= 6 else { return quotes }

        var seededRandom = SeededRandom(seed: date.dayOfYear + date.year * 366)
        var indices = Set<Int>()

        while indices.count < 6 {
            let idx = seededRandom.nextInt(upperBound: quotes.count)
            indices.insert(idx)
        }

        return indices.sorted().compactMap { quotes[safe: $0] }
    }

    private static func loadFavoritesStatic() -> [Quote] {
        guard let data = UserDefaults.standard.data(forKey: "favoriteQuotes") else { return [] }
        do {
            return try JSONDecoder().decode([Quote].self, from: data)
        } catch {
            return []
        }
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("保存收藏失败: \(error)")
        }
    }
}

// MARK: - 种子随机数（保证同一天结果一致）

private struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed))
        if state == 0 { state = 1 }
    }

    mutating func nextInt(upperBound: Int) -> Int {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return Int(z % UInt64(upperBound))
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 收藏导出容器（带元信息）
// ©️Trigin

/// 收藏导出 JSON 结构：附带版本/时间/数量元信息，便于后续兼容与校验
struct FavoritesExport: Codable {
    let appVersion: String
    let exportedAt: Date
    let count: Int
    let quotes: [Quote]
}
