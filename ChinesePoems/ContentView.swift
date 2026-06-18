//
//  ContentView.swift
//  ChinesePoems
//
//  Created by Carson Mulligan on 12/15/24.
//

import SwiftUI

// Dictionary entry model
struct DictionaryEntry: Codable {
    let pinyin: String
    let definition: String
    let pinyin_tone_lines: String
}

// A key-vocabulary item attached to a lesson
struct VocabEntry: Codable, Hashable {
    let char: String
    let pinyin: String
    let gloss: String
}

// Model for our poems / lessons
struct Poem: Identifiable, Codable, Hashable {
    let id: String
    let title_chinese: String
    let title: String
    let author_chinese: String
    let author: String
    let content: String
    let translation_english: String

    // Added for the graded course (all optional so existing JSON still decodes).
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
    var hasTranslation: Bool { !translation_english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

// MARK: - Course tiers

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

// MARK: - Progress store (completed lessons, saved words, script preference)

@MainActor
final class ProgressStore: ObservableObject {
    @Published var completedIDs: Set<String> { didSet { persist("completedIDs", completedIDs) } }
    @Published var savedWords: Set<String> { didSet { persist("savedWords", savedWords) } }
    @Published var useSimplified: Bool { didSet { UserDefaults.standard.set(useSimplified, forKey: "useSimplified") } }

    init() {
        completedIDs = Set(UserDefaults.standard.stringArray(forKey: "completedIDs") ?? [])
        savedWords = Set(UserDefaults.standard.stringArray(forKey: "savedWords") ?? [])
        useSimplified = UserDefaults.standard.object(forKey: "useSimplified") as? Bool ?? true
    }

    private func persist(_ key: String, _ set: Set<String>) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    func isComplete(_ id: String) -> Bool { completedIDs.contains(id) }
    func markComplete(_ id: String) { completedIDs.insert(id) }
    func toggleComplete(_ id: String) {
        if completedIDs.contains(id) { completedIDs.remove(id) } else { completedIDs.insert(id) }
    }

    func isSaved(_ word: String) -> Bool { savedWords.contains(word) }
    func toggleSaved(_ word: String) {
        if savedWords.contains(word) { savedWords.remove(word) } else { savedWords.insert(word) }
    }
}

// MARK: - Detail view for individual poems / lessons

struct PoemDetailView: View {
    let poem: Poem
    @EnvironmentObject var store: ProgressStore
    @State private var showTranslation = false
    @State private var showPinyin = false
    @State private var pinyinDictionary: [String: DictionaryEntry] = [:]
    @State private var showSpeedReader = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if showTranslation {
                    EnglishTextColumn(text: poem.translation_english)
                        .padding(.horizontal)
                } else {
                    ChineseTextColumn(
                        text: poem.content(simplified: store.useSimplified),
                        showPinyin: showPinyin,
                        pinyinDictionary: pinyinDictionary,
                        store: store
                    )

                    if let vocab = poem.vocab, !vocab.isEmpty {
                        VocabListView(vocab: vocab)
                            .padding(.top, 40)
                    }
                }

                completeButton
                    .padding(.top, 48)
            }
            .padding(.vertical, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTranslation ? poem.title : poem.titleChinese(simplified: store.useSimplified))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 12) {
                    if !showTranslation {
                        Button(store.useSimplified ? "繁" : "简") {
                            store.useSimplified.toggle()
                        }
                        Button(showPinyin ? "Hide Pinyin" : "Show Pinyin") {
                            showPinyin.toggle()
                        }
                    }
                    Button {
                        showSpeedReader = true
                    } label: {
                        Image(systemName: "play.circle")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(showTranslation ? "Show Chinese" : "Show English") {
                    showTranslation.toggle()
                }
            }
        }
        .fullScreenCover(isPresented: $showSpeedReader) {
            SpeedReaderView(poem: poem, pinyinDictionary: pinyinDictionary)
        }
        .onAppear {
            loadPinyinDictionary()
        }
    }

    private var completeButton: some View {
        let done = store.isComplete(poem.id)
        return Button {
            store.toggleComplete(poem.id)
        } label: {
            Label(done ? "已完成 · Completed" : "標記完成 · Mark Complete",
                  systemImage: done ? "checkmark.seal.fill" : "checkmark.seal")
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(done ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                .foregroundColor(done ? .accentColor : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadPinyinDictionary() {
        guard let url = Bundle.main.url(forResource: "chinese_to_pinyin_dictionary_with_tones", withExtension: "json") else {
            return
        }
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: DictionaryEntry].self, from: data) {
            pinyinDictionary = decoded
        }
    }
}

// MARK: - Vertical Chinese text (tap a character to save it)

struct ChineseTextColumn: View {
    let text: String
    let showPinyin: Bool
    let pinyinDictionary: [String: DictionaryEntry]
    @ObservedObject var store: ProgressStore

    var body: some View {
        VStack(spacing: 20) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                let charStr = String(char)
                let isHanzi = char.isLetter && !char.isWhitespace
                let saved = store.isSaved(charStr)

                HStack(alignment: .center, spacing: 8) {
                    Text(charStr)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(saved ? .accentColor : .primary)

                    if showPinyin, let entry = pinyinDictionary[charStr] {
                        Text(entry.pinyin_tone_lines)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isHanzi { store.toggleSaved(charStr) }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

struct EnglishTextColumn: View {
    let text: String

    var body: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "character.book.closed")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Translation coming soon")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text("暫無翻譯")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else {
            VStack(spacing: 12) {
                ForEach(text.split(separator: " ").enumerated().map { index, word in
                    (index, String(word))
                }, id: \.0) { _, word in
                    Text(word)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}

// MARK: - Per-lesson vocabulary

struct VocabListView: View {
    let vocab: [VocabEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生詞 · Vocabulary")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
            ForEach(vocab, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(item.char)
                        .font(.system(size: 22, weight: .medium))
                    Text(item.pinyin)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Text(item.gloss)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CourseHomeView()
        .environmentObject(ProgressStore())
}
