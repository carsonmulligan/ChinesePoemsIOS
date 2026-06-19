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
    /// CC-CEDICT word dictionary (≈198K entries, single chars + multi-char words).
    @Published private(set) var words: [String: DictionaryEntry] = [:]
    @Published private(set) var wordsLoading = false
    /// Make Me a Hanzi stroke graphics (corpus characters only).
    @Published private(set) var strokes: [String: HanziGraphic] = [:]
    /// Radical + decomposition per character (Make Me a Hanzi dictionary).
    @Published private(set) var radicals: [String: RadicalInfo] = [:]

    private var pinyinLoaded = false
    private var wordsLoaded = false
    private var strokesLoaded = false
    private var radicalsLoaded = false

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

    /// The CC-CEDICT word dictionary is ~25MB; decode it off the main thread so
    /// the 字 tab stays responsive, then publish on the main actor.
    func loadWordsIfNeeded() {
        guard !wordsLoaded else { return }
        wordsLoaded = true
        wordsLoading = true
        Task.detached(priority: .userInitiated) {
            var decoded: [String: DictionaryEntry] = [:]
            if let url = Bundle.main.url(forResource: "cedict_words", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let d = try? JSONDecoder().decode([String: DictionaryEntry].self, from: data) {
                decoded = d
            }
            await MainActor.run {
                self.words = decoded
                self.wordsLoading = false
            }
        }
    }

    /// Stroke graphics are ~12MB; decode off the main thread.
    func loadStrokesIfNeeded() {
        guard !strokesLoaded else { return }
        strokesLoaded = true
        Task.detached(priority: .userInitiated) {
            var decoded: [String: HanziGraphic] = [:]
            if let url = Bundle.main.url(forResource: "stroke_data", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let d = try? JSONDecoder().decode([String: HanziGraphic].self, from: data) {
                decoded = d
            }
            await MainActor.run { self.strokes = decoded }
        }
    }

    /// Radical/decomposition data is small (~320KB); load synchronously.
    func loadRadicalsIfNeeded() {
        guard !radicalsLoaded else { return }
        radicalsLoaded = true
        guard let url = Bundle.main.url(forResource: "radicals", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: RadicalInfo].self, from: data) else {
            return
        }
        radicals = decoded
    }

    /// Definition for a term, preferring the word dictionary (covers both
    /// multi-character words and single characters) and falling back to the
    /// reader's character dictionary.
    func entry(for term: String) -> DictionaryEntry? {
        words[term] ?? pinyin[term]
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
