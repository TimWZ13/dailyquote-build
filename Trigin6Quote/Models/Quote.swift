import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let author: String
    let category: String
    /// 英文原文（可选）。为空表示当前 text 已是唯一语言版本。
    var translation: String? = nil

    init(id: UUID = UUID(), text: String, author: String, category: String, translation: String? = nil) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
        self.translation = translation
    }
}
