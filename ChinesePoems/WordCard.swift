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
    @State private var strokeFullscreen: WordRef?   // tap a diagram to enlarge
    @State private var showSaved = false

    private var entry: DictionaryEntry? { repo.entry(for: term) }
    private var isSingleChar: Bool { term.count == 1 }
    private var breakdownChars: [String] {
        term.filter { $0.isLetter && !$0.isASCII }.map(String.init)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                if isSingleChar { strokeSection }
                else { wordStrokesSection }
                definitionSection
                if !isSingleChar { breakdownSection }
                examplesSection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paperBackground()
        .navigationTitle(term)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSaved = true } label: {
                    Image(systemName: "books.vertical")
                }
                .tint(Theme.cinnabar)
            }
        }
        .fullScreenCover(item: $strokeFullscreen) { ref in
            if let g = repo.strokes[ref.term] {
                StrokeFullScreenView(term: ref.term, graphic: g)
            }
        }
        .sheet(isPresented: $showSaved) { SavedWordsSheet() }
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
                let comps = decompositionComponents(radical.d)
                HStack(spacing: 14) {
                    Text("部首 · \(radical.r)")
                    if comps.count > 1 {
                        Text("組成 · " + comps.joined(separator: " + "))
                    }
                }
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
                    strokeTile(term, graphic: graphic, size: 200)
                    VStack(alignment: .leading, spacing: 12) {
                        Button { strokeReplay += 1 } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("重播").font(Theme.serif(14, .medium))
                            }
                            .foregroundColor(Theme.cinnabar)
                        }
                        Button { strokeFullscreen = WordRef(term: term) } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                Text("放大 · Enlarge").font(Theme.serif(14, .medium))
                            }
                            .foregroundColor(Theme.cinnabar)
                        }
                    }
                    Spacer()
                }
            }
        } else if repo.strokes.isEmpty {
            // Data still decoding (12MB, off-main) — show a placeholder, not nothing.
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("筆順 · stroke order")
                HStack(spacing: 10) {
                    ProgressView()
                    Text("載入筆順 · loading…").font(Theme.label(13)).foregroundColor(Theme.inkFaded)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.paperSunken))
            }
        }
    }

    // MARK: Stroke order for each character (multi-character word)

    @ViewBuilder
    private var wordStrokesSection: some View {
        let chars = breakdownChars.filter { repo.strokes[$0] != nil }
        if !chars.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("筆順 · stroke order")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(chars.enumerated()), id: \.offset) { _, char in
                            if let g = repo.strokes[char] {
                                strokeTile(char, graphic: g, size: 130)
                            }
                        }
                    }
                }
            }
        } else if repo.strokes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("筆順 · stroke order")
                HStack(spacing: 10) {
                    ProgressView()
                    Text("載入筆順 · loading…").font(Theme.label(13)).foregroundColor(Theme.inkFaded)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.paperSunken))
            }
        }
    }

    /// A stroke diagram tile that replays on the card and enlarges on tap.
    private func strokeTile(_ char: String, graphic: HanziGraphic, size: CGFloat) -> some View {
        StrokeOrderView(graphic: graphic)
            .id(strokeReplay)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.paperSunken))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.inkWhisper)
                    .padding(6)
            }
            .contentShape(Rectangle())
            .onTapGesture { strokeFullscreen = WordRef(term: char) }
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

// MARK: - Saved words sheet (browse / jump to other saved entries)

struct SavedWordsSheet: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository
    @Environment(\.dismiss) private var dismiss

    private let cols = [GridItem(.adaptive(minimum: 64), spacing: 10)]

    var body: some View {
        NavigationStack {
            Group {
                if store.savedWords.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "books.vertical").font(.title).foregroundColor(Theme.inkWhisper)
                        Text("尚無生字 · no saved words yet")
                            .font(Theme.serif(15)).foregroundColor(Theme.inkFaded)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: cols, spacing: 10) {
                            ForEach(store.savedWords.sorted(), id: \.self) { word in
                                NavigationLink(value: WordRef(term: word)) {
                                    Text(word)
                                        .font(Theme.serif(word.count > 1 ? 18 : 26, .medium))
                                        .foregroundColor(Theme.cinnabar)
                                        .lineLimit(1).minimumScaleFactor(0.6)
                                        .frame(minWidth: 64, minHeight: 56)
                                        .padding(.horizontal, 6)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.paperRaised))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .paperBackground()
            .navigationTitle("生字簿 · \(store.savedWords.count) saved")
            .navigationBarTitleDisplayMode(.inline)
            .wordCardDestination()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.tint(Theme.cinnabar)
                }
            }
        }
        .tint(Theme.cinnabar)
        .onAppear {
            repo.loadPinyinIfNeeded(); repo.loadWordsIfNeeded()
            repo.loadStrokesIfNeeded(); repo.loadRadicalsIfNeeded(); repo.loadSentencesIfNeeded()
        }
    }
}
