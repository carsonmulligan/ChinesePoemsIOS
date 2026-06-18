//
//  Models.swift
//  ChinesePoems
//
//  Core data models + collection derivation.
//

import SwiftUI

// MARK: - Dictionary

struct DictionaryEntry: Codable {
    let pinyin: String
    let definition: String
    let pinyin_tone_lines: String
}

// MARK: - Per-lesson vocabulary

struct VocabEntry: Codable, Hashable {
    let char: String
    let pinyin: String
    let gloss: String
}

// MARK: - Poem / text

struct Poem: Identifiable, Codable, Hashable {
    let id: String
    let title_chinese: String
    let title: String
    let author_chinese: String
    let author: String
    let content: String
    let translation_english: String

    // Optional (so existing JSON still decodes).
    var content_simplified: String? = nil
    var title_chinese_simplified: String? = nil
    var author_chinese_simplified: String? = nil
    var tier: String? = nil
    var order: Int? = nil
    var source: String? = nil
    var vocab: [VocabEntry]? = nil

    // Script-aware accessors.
    func content(simplified: Bool) -> String {
        if simplified, let s = content_simplified, !s.isEmpty { return s }
        return content
    }
    func titleChinese(simplified: Bool) -> String {
        if simplified, let s = title_chinese_simplified, !s.isEmpty { return s }
        return title_chinese
    }
    func authorChinese(simplified: Bool) -> String {
        if simplified, let s = author_chinese_simplified, !s.isEmpty { return s }
        return author_chinese
    }

    var resolvedTier: CourseTier { CourseTier(rawValue: tier ?? "") ?? .foundations }
    var sortOrder: Int { order ?? Int.max }
    var hasTranslation: Bool {
        !translation_english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Character count of the traditional content, ignoring whitespace — used for
    /// the "length" hint on a text (a 4,000-char Shiji chapter vs. a 24-char poem).
    var characterCount: Int { content.filter { !$0.isWhitespace }.count }

    var lengthLabel: String {
        switch characterCount {
        case ..<60:  return "短"   // short
        case ..<300: return "中"   // medium
        default:     return "長"   // long
        }
    }

    /// The source collection this text belongs to. Derived from `source`,
    /// falling back to `author` for texts that were ingested without a source.
    var collection: TextCollection {
        if let s = source, let c = TextCollection.bySource[s] { return c }
        // Fallbacks for the untagged texts.
        let a = author.lowercased()
        if a.contains("wang fanzhi") { return .wangFanzhi }
        if a.contains("zhuangzi")    { return .zhuangzi }
        if a.contains("laozi")       { return .daodejing }
        if a.contains("li bai") || a.contains("du fu") { return .poetry }
        return .other
    }
}

// MARK: - Course tiers (difficulty)

enum CourseTier: String, CaseIterable, Identifiable {
    case foundations = "Foundations"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case master = "Master"

    var id: String { rawValue }
    var rank: Int { CourseTier.allCases.firstIndex(of: self)! }
    var chinese: String {
        switch self {
        case .foundations: return "築基"
        case .intermediate: return "進階"
        case .advanced: return "登堂"
        case .master: return "入室"
        }
    }
}

// MARK: - Collections (source works)

struct TextCollection: Identifiable, Hashable {
    let id: String
    let chinese: String
    let english: String
    /// Curated display order — foundational classics first.
    let order: Int

    static let daodejing  = TextCollection(id: "daodejing",  chinese: "道德經",   english: "Daodejing",            order: 0)
    static let analects   = TextCollection(id: "analects",   chinese: "論語",     english: "Analects",             order: 1)
    static let mencius     = TextCollection(id: "mencius",    chinese: "孟子",     english: "Mencius",              order: 2)
    static let zhuangzi   = TextCollection(id: "zhuangzi",   chinese: "莊子",     english: "Zhuangzi",             order: 3)
    static let shiji      = TextCollection(id: "shiji",      chinese: "史記",     english: "Records of the Historian", order: 4)
    static let prose      = TextCollection(id: "prose",      chinese: "古文",     english: "Classical Prose",      order: 5)
    static let fables     = TextCollection(id: "fables",     chinese: "寓言",     english: "Fables",               order: 6)
    static let wangFanzhi = TextCollection(id: "wangfanzhi", chinese: "王梵志詩", english: "Wang Fanzhi · Zen Poems", order: 7)
    static let poetry     = TextCollection(id: "poetry",     chinese: "詩",       english: "Poetry",               order: 8)
    static let other      = TextCollection(id: "other",      chinese: "其他",     english: "Other",                order: 9)

    static let all: [TextCollection] = [
        daodejing, analects, mencius, zhuangzi, shiji, prose, fables, wangFanzhi, poetry, other
    ]

    /// Maps the raw `source` field from poems.json to a collection.
    static let bySource: [String: TextCollection] = [
        "Daodejing": daodejing,
        "Analects": analects,
        "Mencius": mencius,
        "Zhuangzi": zhuangzi,
        "Shiji": shiji,
        "Classical Prose": prose,
        "Fables": fables,
    ]
}
