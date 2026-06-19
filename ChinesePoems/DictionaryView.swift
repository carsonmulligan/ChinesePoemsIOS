//
//  DictionaryView.swift
//  ChinesePoems
//
//  字 — a Pleco-style hub: look up any character or word (CC-CEDICT),
//  browse the characters you've saved, and launch spaced-repetition practice.
//

import SwiftUI

struct DictionaryView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    @State private var query = ""
    @State private var path = NavigationPath()
    @State private var showPractice = false
    @State private var showRadicals = false
    @State private var showHandwritingTip = false

    private let resultCap = 60

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if !store.savedWords.isEmpty { practiceBanner }

                    if isSearching && repo.wordsLoading && repo.words.isEmpty {
                        loadingState
                    } else {
                        let rows = currentRows
                        if rows.isEmpty {
                            emptyState
                        } else {
                            sectionLabel(isSearching ? "\(rows.count) 條 · results"
                                                      : "生字簿 · \(rows.count) saved")
                            ForEach(rows, id: \.self) { term in
                                entryRow(term)
                                Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 64)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
            .paperBackground()
            .navigationTitle("字")
            .navigationBarTitleDisplayMode(.inline)
            .wordCardDestination()
            .searchable(text: $query, prompt: "查字詞 · character, word, pinyin, or meaning")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHandwritingTip = true } label: {
                        Image(systemName: "hand.draw")
                    }
                    .tint(Theme.cinnabar)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showRadicals = true } label: {
                        Text("部").font(Theme.serif(18, .medium))
                    }
                    .tint(Theme.cinnabar)
                }
            }
            .alert("手寫輸入 · Handwriting", isPresented: $showHandwritingTip) {
                Button("好") { }
            } message: {
                Text("Tap the search box, then press 🌐 on the keyboard and choose Chinese Handwriting to draw characters.\n\nFirst time: enable it in Settings → General → Keyboard → Keyboards → Add New Keyboard → 中文(简体) or (繁體) → 手寫.")
            }
            .fullScreenCover(isPresented: $showPractice) {
                FlashcardView(words: practiceDeck, entries: repo.words, store: store)
            }
            .sheet(isPresented: $showRadicals) {
                RadicalIndexView()
            }
        }
        .tint(Theme.cinnabar)
        .onAppear {
            repo.loadWordsIfNeeded()
            repo.loadStrokesIfNeeded()
            repo.loadRadicalsIfNeeded()
            repo.loadSentencesIfNeeded()
        }
    }

    // MARK: Practice banner

    private var practiceBanner: some View {
        Button { showPractice = true } label: {
            HStack(spacing: 14) {
                SealMark(glyph: "練", size: 30, filled: store.dueCount > 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text("練習 · Practice")
                        .font(Theme.serif(18, .semibold))
                        .foregroundColor(Theme.ink)
                    Text(store.dueCount > 0
                         ? "\(store.dueCount) 到期 · due today"
                         : "全部複習完畢 · review all \(store.savedWords.count)")
                        .font(Theme.label(13))
                        .foregroundColor(Theme.inkFaded)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.inkWhisper)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.paperRaised))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: Entry row (character or multi-character word)

    private func entryRow(_ term: String) -> some View {
        let entry = repo.entry(for: term)
        let saved = store.isSaved(term)
        return HStack(spacing: 14) {
            Text(term)
                .font(Theme.serif(term.count > 2 ? 24 : 30, .medium))
                .foregroundColor(saved ? Theme.cinnabar : Theme.ink)
                .frame(minWidth: 40, alignment: .leading)
                .fixedSize()

            VStack(alignment: .leading, spacing: 3) {
                Text(entry?.pinyin_tone_lines ?? "—")
                    .font(Theme.label(14))
                    .foregroundColor(Theme.inkFaded)
                Text(entry?.definition ?? "No dictionary entry")
                    .font(Theme.serif(15))
                    .foregroundColor(Theme.ink)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)

            SpeakButton(text: term, traditional: !store.useSimplified)
                .padding(.trailing, 4)

            Button {
                store.toggleSaved(term)
            } label: {
                Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundColor(saved ? Theme.cinnabar : Theme.inkFaded)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { path.append(WordRef(term: term)) }
    }

    // MARK: Rows shown right now (search results, or the saved list)

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var currentRows: [String] {
        guard isSearching else { return store.savedWords.sorted() }
        let q = query.trimmingCharacters(in: .whitespaces)
        let hasHan = q.contains { $0.isLetter && !$0.isASCII }
        return hasHan ? hanResults(q) : latinResults(q.lowercased())
    }

    /// Chinese input: exact word → words that start with the query → the
    /// individual characters (a breakdown), so 自 surfaces 自由, 自然… and 自由
    /// shows the word itself plus 自 and 由.
    private func hanResults(_ q: String) -> [String] {
        var rows: [String] = []
        var seen = Set<String>()
        func push(_ s: String) { if seen.insert(s).inserted { rows.append(s) } }

        if repo.words[q] != nil { push(q) }

        let prefixed = repo.words.keys
            .filter { $0.hasPrefix(q) && $0 != q }
            .sorted { ($0.count, $0) < ($1.count, $1) }
            .prefix(resultCap)
        prefixed.forEach { push($0) }

        for ch in q where ch.isLetter && !ch.isASCII { push(String(ch)) }
        return rows
    }

    /// Latin input: substring match on pinyin or definition, with an early exit
    /// so a keystroke never scans the whole 198K-entry dictionary needlessly.
    private func latinResults(_ lower: String) -> [String] {
        guard lower.count >= 2 else { return [] }
        var hits: [String] = []
        for (key, entry) in repo.words {
            if entry.pinyin.lowercased().contains(lower)
                || entry.definition.lowercased().contains(lower) {
                hits.append(key)
                if hits.count >= resultCap * 4 { break }
            }
        }
        return Array(hits.sorted { ($0.count, $0) < ($1.count, $1) }.prefix(resultCap))
    }

    private var practiceDeck: [String] {
        let due = store.dueWords
        return due.isEmpty ? store.savedWords.sorted() : due
    }

    // MARK: Bits

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.label(12))
            .foregroundColor(Theme.inkWhisper)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 6)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("載入字典 · loading dictionary…")
                .font(Theme.label(13))
                .foregroundColor(Theme.inkFaded)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: isSearching ? "magnifyingglass" : "character.book.closed")
                .font(.title)
                .foregroundColor(Theme.inkWhisper)
            Text(isSearching ? "無結果 · no matches" : "尚無生字 · no saved characters yet")
                .font(Theme.serif(16))
                .foregroundColor(Theme.inkFaded)
            if !isSearching {
                Text("閱讀時輕點字即可收藏 · tap a character while reading to save it")
                    .font(Theme.label(13))
                    .foregroundColor(Theme.inkWhisper)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
}
