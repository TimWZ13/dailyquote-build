import Foundation

extension Date {
    // MARK: - 缓存的 DateFormatter（避免每次访问都新建，减少 UI 重绘开销）
    /// ©️Trigin
    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    var dayOfYear: Int {
        let calendar = Calendar.current
        return calendar.ordinality(of: .day, in: .year, for: self) ?? 1
    }

    var year: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: self)
    }

    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }

    var formattedDate: String {
        Self.longDateFormatter.string(from: self)
    }

    var shortDate: String {
        Self.shortDateFormatter.string(from: self)
    }
}

// MARK: - Collection Safe Subscript
// 注意：QuoteStore.swift 中已有 Collection 扩展，此处不再重复定义
