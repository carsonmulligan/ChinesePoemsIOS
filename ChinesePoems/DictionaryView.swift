//
//  DictionaryView.swift
//  ChinesePoems
//
//  字 — a Pleco-style hub: look up any character (pinyin + definition),
//  browse the characters you've saved, and launch spaced-repetition practice.
//

import SwiftUI

struct DictionaryView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    @State private var query = ""
    @State private var selected: String?      // drives the lookup popover
    @State private var showPractice = false

    private let resultCap = 60

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if !store.savedWords.isEmpty { practiceBanner }

                    let rows = currentRows
                    if rows.isEmpty {
                        emptyState
                    } else {
                        if isSearching {
                            sectionLabel("\(rows.count) 條 · results")
                        } else {
                            sectionLabel("生字簿 · \(rows.count) saved")
                        }
                        ForEach(rows, id: \.self) { word in
                            entryRow(word)
                            Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 64)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .paperBackground()
            .navigationTitle("字")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "查字 · character, pinyin, or meaning")
            .fullScreenCover(isPresented: $showPractice) {
                FlashcardView(words: practiceDeck, pinyin: repo.pinyin, store: store)
            }
        }
        .tint(Theme.cinnabar)
        .onAppear { repo.loadPinyinIfNeeded() }
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
                         ? "\(store.dueCount) 字到期 · due today"
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

    // MARK: Entry row

    private func entryRow(_ word: String) -> some View {
        let entry = repo.pinyin[word]
        let saved = store.isSaved(word)
        return HStack(spacing: 14) {
            Text(word)
                .font(Theme.serif(30, .medium))
                .foregroundColor(saved ? Theme.cinnabar : Theme.ink)
                .frame(width: 40, alignment: .center)

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

            Button {
                store.toggleSaved(word)
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
        .onTapGesture { selected = word }
        .popover(isPresented: Binding(
            get: { selected == word },
            set: { if !$0 { selected = nil } }
        )) {
            CharacterPopover(charStr: word, entry: entry, store: store)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: Rows shown right now (search results, or the saved list)

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var currentRows: [String] {
        guard isSearching else { return store.savedWords.sorted() }
        let q = query.trimmingCharacters(in: .whitespaces)

        // Chinese input → look up each distinct Han character in the query.
        let hanChars = q.filter { $0.isLetter && !$0.isASCII }
        if !hanChars.isEmpty {
            var seen = Set<String>(); var ordered: [String] = []
            for ch in hanChars {
                let s = String(ch)
                if seen.insert(s).inserted { ordered.append(s) }
            }
            return ordered
        }

        // Latin input → substring match on pinyin or definition.
        let lower = q.lowercased()
        return repo.pinyin
            .filter { $0.value.pinyin.lowercased().contains(lower)
                   || $0.value.definition.lowercased().contains(lower) }
            .map(\.key)
            .sorted()
            .prefix(resultCap)
            .map { $0 }
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
