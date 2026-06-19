//
//  WordCard.swift
//  ChinesePoems
//
//  A full-screen detail card for a character or word — pinyin, audio, full
//  definition, stroke order (single chars), per-character breakdown (words),
//  radical, and example sentences. Pushed in the 字 tab / radical browser and
//  openable from the reader's popover.
//

import SwiftUI

/// Navigation value for a word/character card (distinct from a radical String).
struct WordRef: Identifiable, Hashable {
    let term: String
    var id: String { term }
}

extension View {
    /// Register the word-card destination on an enclosing NavigationStack.
    func wordCardDestination() -> some View {
        navigationDestination(for: WordRef.self) { WordCardView(term: $0.term) }
    }
}

struct WordCardView: View {
    let term: String
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    @State private var strokeReplay = 0

    private var entry: DictionaryEntry? { repo.entry(for: term) }
    private var isSingleChar: Bool { term.count == 1 }
    private var breakdownChars: [String] {
        term.filter { $0.isLetter && !$0.isASCII }.map(String.init)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                definitionSection
                if isSingleChar { strokeSection }
                else { breakdownSection }
                examplesSection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paperBackground()
        .navigationTitle(term)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            repo.loadPinyinIfNeeded(); repo.loadWordsIfNeeded(); repo.loadStrokesIfNeeded()
            repo.loadRadicalsIfNeeded(); repo.loadSentencesIfNeeded()
        }
    }

    // MARK: Header

    private var header: some View {
        let saved = store.isSaved(term)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                Text(term)
                    .font(Theme.serif(isSingleChar ? 72 : 52, .semibold))
                    .foregroundColor(saved ? Theme.cinnabar : Theme.ink)
                VStack(alignment: .leading, spacing: 10) {
                    if let entry, !entry.pinyin_tone_lines.isEmpty {
                        Text(entry.pinyin_tone_lines)
                            .font(Theme.label(22))
                            .foregroundColor(Theme.inkFaded)
                    }
                    HStack(spacing: 18) {
                        SpeakButton(text: term, traditional: !store.useSimplified, size: 26)
                        Button { store.toggleSaved(term) } label: {
                            Image(systemName: saved ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(saved ? Theme.cinnabar : Theme.inkFaded)
                        }
                    }
                }
                Spacer()
            }
            if let radical = repo.radicals[term], !radical.r.isEmpty {
                Text("部首 \(radical.r)" + (radical.d.isEmpty || radical.d == "？" ? "" : "  ·  \(radical.d)"))
                    .font(Theme.label(13))
                    .foregroundColor(Theme.inkWhisper)
            }
        }
    }

    // MARK: Definition

    @ViewBuilder
    private var definitionSection: some View {
        if let entry, !entry.definition.isEmpty {
            let senses = glossSenses(entry.definition)
            if senses.count <= 1 {
                Text(senses.first ?? entry.definition)
                    .font(Theme.serif(18)).foregroundColor(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(senses.enumerated()), id: \.offset) { i, sense in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(i + 1)").font(Theme.label(14)).foregroundColor(Theme.cinnabar)
                                .frame(width: 18, alignment: .trailing)
                            Text(sense).font(Theme.serif(17)).foregroundColor(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        } else {
            Text("No dictionary entry · 暫無釋義")
                .font(Theme.serif(15)).foregroundColor(Theme.inkWhisper)
        }
    }

    // MARK: Stroke order (single character)

    @ViewBuilder
    private var strokeSection: some View {
        if let graphic = repo.strokes[term] {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("筆順 · \(graphic.s.count) strokes")
                HStack(alignment: .top, spacing: 16) {
                    StrokeOrderView(graphic: graphic)
                        .id(strokeReplay)
                        .frame(width: 180, height: 180)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.paperSunken))
                    Button { strokeReplay += 1 } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重播").font(Theme.serif(14, .medium))
                        }
                        .foregroundColor(Theme.cinnabar)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: Per-character breakdown (multi-character word)

    @ViewBuilder
    private var breakdownSection: some View {
        if breakdownChars.count > 1 {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("逐字 · characters")
                ForEach(Array(breakdownChars.enumerated()), id: \.offset) { _, char in
                    NavigationLink(value: WordRef(term: char)) {
                        charRow(char)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func charRow(_ char: String) -> some View {
        let e = repo.entry(for: char)
        return HStack(spacing: 14) {
            Text(char)
                .font(Theme.serif(30, .medium))
                .foregroundColor(store.isSaved(char) ? Theme.cinnabar : Theme.ink)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(e?.pinyin_tone_lines ?? "—")
                    .font(Theme.label(13)).foregroundColor(Theme.inkFaded)
                Text(e?.definition ?? "—")
                    .font(Theme.serif(14)).foregroundColor(Theme.ink).lineLimit(2)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.inkWhisper)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: Examples

    @ViewBuilder
    private var examplesSection: some View {
        let examples = repo.examples(for: term, limit: 6)
        if !examples.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("例句 · examples")
                ForEach(examples, id: \.self) { s in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(s.zh).font(Theme.serif(16)).foregroundColor(Theme.ink)
                        let py = pinyinLine(for: s.zh, using: repo.pinyin)
                        if !py.isEmpty {
                            Text(py).font(Theme.label(12)).foregroundColor(Theme.cinnabar)
                        }
                        Text(s.en).font(Theme.serif(13)).foregroundColor(Theme.inkFaded)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Theme.label(12))
            .foregroundColor(Theme.inkWhisper)
    }
}
