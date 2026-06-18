//
//  PoemsRepository.swift
//  ChinesePoems
//
//  Loads poems.json once and the large pinyin dictionary lazily. Shared across
//  all tabs via the environment so JSON is decoded a single time.
//

import SwiftUI

@MainActor
final class PoemsRepository: ObservableObject {
    @Published private(set) var poems: [Poem] = []
    @Published private(set) var pinyin: [String: DictionaryEntry] = [:]

    private var pinyinLoaded = false

    init() { loadPoems() }

    // MARK: Loading

    private func loadPoems() {
        guard let url = Bundle.main.url(forResource: "poems", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: Poem].self, from: data) else {
            return
        }
        poems = decoded.values.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// The pinyin dictionary is ~1.8MB; load it only when a reader first needs it.
    func loadPinyinIfNeeded() {
        guard !pinyinLoaded else { return }
        pinyinLoaded = true
        guard let url = Bundle.main.url(forResource: "chinese_to_pinyin_dictionary_with_tones", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: DictionaryEntry].self, from: data) else {
            return
        }
        pinyin = decoded
    }

    // MARK: Queries

    var totalCount: Int { poems.count }

    /// Collections that actually contain texts, in curated order.
    var collections: [TextCollection] {
        let present = Set(poems.map { $0.collection.id })
        return TextCollection.all.filter { present.contains($0.id) }
    }

    func poems(in collection: TextCollection) -> [Poem] {
        poems.filter { $0.collection.id == collection.id }
    }

    func poem(id: String) -> Poem? { poems.first { $0.id == id } }

    /// Free-text search across Chinese/English titles, author, and content.
    func search(_ query: String, tier: CourseTier?, collection: TextCollection?) -> [Poem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return poems.filter { poem in
            if let tier, poem.resolvedTier != tier { return false }
            if let collection, poem.collection.id != collection.id { return false }
            guard !q.isEmpty else { return true }
            return poem.title.lowercased().contains(q)
                || poem.title_chinese.contains(query)
                || (poem.title_chinese_simplified ?? "").contains(query)
                || poem.author.lowercased().contains(q)
                || poem.author_chinese.contains(query)
                || poem.content.contains(query)
        }
    }
}
