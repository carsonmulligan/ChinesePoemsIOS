//
//  ReadingView.swift
//  ChinesePoems
//
//  The reading experience: vertical one-character-per-row Chinese with
//  繁/简, pinyin (fixed gutter — never wobbles the character axis), and English.
//

import SwiftUI

struct ReadingView: View {
    let poem: Poem
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    @State private var showTranslation = false
    @State private var showPinyin = false
    @State private var showSpeedReader = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                titleBlock

                if showTranslation {
                    EnglishTextColumn(text: poem.translation_english)
                        .padding(.horizontal)
                        .padding(.top, 28)
                } else {
                    ChineseTextColumn(
                        text: poem.content(simplified: store.useSimplified),
                        showPinyin: showPinyin,
                        pinyinDictionary: repo.pinyin,
                        store: store
                    )
                    .padding(.top, 28)

                    if let vocab = poem.vocab, !vocab.isEmpty {
                        VocabListView(vocab: vocab).padding(.top, 44)
                    }
                }

                sealButton.padding(.top, 52)
            }
            .padding(.vertical, 36)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(showTranslation ? poem.title : poem.titleChinese(simplified: store.useSimplified))
                    .font(Theme.serif(17, .semibold))
                    .foregroundColor(Theme.ink)
            }
            ToolbarItem(placement: .topBarTrailing) { favoriteButton }
        }
        .safeAreaInset(edge: .bottom) { controlBar }
        .fullScreenCover(isPresented: $showSpeedReader) {
            SpeedReaderView(poem: poem, pinyinDictionary: repo.pinyin)
        }
        .tint(Theme.cinnabar)
        .onAppear {
            repo.loadPinyinIfNeeded()
            store.noteOpened(poem.id)
        }
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(poem.titleChinese(simplified: store.useSimplified))
                .font(Theme.serif(27, .semibold))
                .foregroundColor(Theme.ink)
                .multilineTextAlignment(.center)
            Text(poem.authorChinese(simplified: store.useSimplified))
                .font(Theme.serif(15))
                .foregroundColor(Theme.inkFaded)
            HStack(spacing: 8) {
                TierBadge(tier: poem.resolvedTier)
                Text(poem.collection.chinese)
                    .font(Theme.label(12))
                    .foregroundColor(Theme.inkWhisper)
            }
            .padding(.top, 2)

            Rectangle()
                .fill(Theme.cinnabar)
                .frame(width: 28, height: 2)
                .padding(.top, 10)
        }
        .padding(.horizontal)
    }

    // MARK: Bottom control bar (繁/简 · pinyin · English · speed)

    private var controlBar: some View {
        HStack(spacing: 0) {
            if !showTranslation {
                controlButton(store.useSimplified ? "繁" : "简", active: false) {
                    store.useSimplified.toggle()
                }
                controlButton("拼", active: showPinyin) { showPinyin.toggle() }
            }
            controlButton(showTranslation ? "中" : "英", active: showTranslation) {
                showTranslation.toggle()
            }
            controlButton("讀", active: false, system: "play.circle") {
                repo.loadPinyinIfNeeded()
                showSpeedReader = true
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 0.5), alignment: .top)
    }

    private func controlButton(_ glyph: String, active: Bool, system: String? = nil,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let system {
                    Image(systemName: system).font(.system(size: 18))
                } else {
                    Text(glyph).font(Theme.serif(19, .medium))
                }
            }
            .foregroundColor(active ? Theme.cinnabar : Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(active ? Theme.cinnabarSoft : Color.clear)
            )
        }
    }

    private var favoriteButton: some View {
        Button {
            store.toggleFavorite(poem.id)
        } label: {
            Image(systemName: store.isFavorite(poem.id) ? "heart.fill" : "heart")
                .foregroundColor(store.isFavorite(poem.id) ? Theme.cinnabar : Theme.inkFaded)
        }
    }

    private var sealButton: some View {
        let done = store.isComplete(poem.id)
        return Button {
            store.toggleComplete(poem.id)
        } label: {
            HStack(spacing: 10) {
                SealMark(glyph: "讀", size: 24, filled: done)
                Text(done ? "已讀 · Read" : "標記已讀 · Mark as read")
                    .font(Theme.serif(15, .medium))
                    .foregroundColor(done ? Theme.cinnabar : Theme.ink)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(done ? Theme.cinnabarSoft : Theme.paperRaised)
            )
            .overlay(
                Capsule().stroke(Theme.hairline, lineWidth: done ? 0 : 1)
            )
        }
    }
}

// MARK: - Vertical Chinese column (fixed pinyin gutter)

struct ChineseTextColumn: View {
    let text: String
    let showPinyin: Bool
    let pinyinDictionary: [String: DictionaryEntry]
    @ObservedObject var store: ProgressStore

    // The character lives in a fixed-width centered slot so the column never
    // wobbles; pinyin lives in its own fixed-width gutter to the right.
    private let charSlot: CGFloat = 40
    private let pinyinGutter: CGFloat = 88
    private let gutterSpacing: CGFloat = 12

    // Tap opens the lookup popover anchored to this row; tracked by index so
    // repeated characters (e.g. two 不) don't all open at once.
    @State private var selectedIndex: Int?
    // Bumped on every long-press save to fire a light haptic.
    @State private var saveHaptic = 0

    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                row(for: char, at: index)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .sensoryFeedback(.impact(weight: .light), trigger: saveHaptic)
    }

    @ViewBuilder
    private func row(for char: Character, at index: Int) -> some View {
        let charStr = String(char)
        let isHanzi = char.isLetter && !char.isWhitespace
        let saved = store.isSaved(charStr)
        let entry = pinyinDictionary[charStr]

        HStack(spacing: gutterSpacing) {
            // Mirror the pinyin gutter on the left so the character slot stays
            // centered on screen whether or not pinyin is showing.
            if showPinyin {
                Color.clear.frame(width: pinyinGutter, height: 1)
            }

            // Character — fixed centered slot keeps the vertical line dead straight.
            Text(charStr)
                .font(Theme.serif(30, .medium))
                .foregroundColor(saved ? Theme.cinnabar : Theme.ink)
                .frame(width: charSlot, alignment: .center)

            // Pinyin — its own fixed-width gutter, left-aligned -> straight line.
            if showPinyin {
                Text(entry?.pinyin_tone_lines ?? "")
                    .font(Theme.label(15))
                    .foregroundColor(Theme.inkFaded)
                    .frame(width: pinyinGutter, alignment: .leading)
            }
        }
        // Center the whole row group; because both slots are fixed width the
        // character axis stays in the same place for every row.
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // Tap → look up (pinyin + definition + save). Long-press → quick-save.
        .onTapGesture { if isHanzi { selectedIndex = index } }
        .onLongPressGesture(minimumDuration: 0.4) {
            if isHanzi {
                store.toggleSaved(charStr)
                saveHaptic += 1
            }
        }
        .popover(isPresented: Binding(
            get: { selectedIndex == index },
            set: { if !$0 { selectedIndex = nil } }
        )) {
            CharacterPopover(charStr: charStr, entry: entry, store: store)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Character lookup popover (tap a character)

private struct CharacterPopover: View {
    let charStr: String
    let entry: DictionaryEntry?
    @ObservedObject var store: ProgressStore

    var body: some View {
        let saved = store.isSaved(charStr)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(charStr)
                    .font(Theme.serif(40, .medium))
                    .foregroundColor(saved ? Theme.cinnabar : Theme.ink)
                if let entry, !entry.pinyin_tone_lines.isEmpty {
                    Text(entry.pinyin_tone_lines)
                        .font(Theme.label(18))
                        .foregroundColor(Theme.inkFaded)
                }
            }

            if let entry, !entry.definition.isEmpty {
                Text(entry.definition)
                    .font(Theme.serif(15))
                    .foregroundColor(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No dictionary entry · 暫無釋義")
                    .font(Theme.serif(14))
                    .foregroundColor(Theme.inkWhisper)
            }

            Rectangle().fill(Theme.hairline).frame(height: 0.5)

            Button {
                store.toggleSaved(charStr)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: saved ? "heart.fill" : "heart")
                    Text(saved ? "已存 · Saved" : "存 · Save character")
                        .font(Theme.serif(15, .medium))
                }
                .foregroundColor(saved ? Theme.cinnabar : Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .frame(width: 248)
        .presentationBackground(Theme.paperRaised)
    }
}

// MARK: - English translation column

struct EnglishTextColumn: View {
    let text: String

    var body: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "character.book.closed")
                    .font(.title)
                    .foregroundColor(Theme.inkWhisper)
                Text("Translation coming soon")
                    .font(Theme.serif(16))
                    .foregroundColor(Theme.inkFaded)
                Text("暫無翻譯")
                    .font(Theme.serif(14))
                    .foregroundColor(Theme.inkWhisper)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else {
            // One word per row, stacked vertically and centered — mirrors the
            // vertical Chinese column so the two readers feel like a pair.
            VStack(spacing: 12) {
                ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, word in
                    Text(String(word))
                        .font(Theme.serif(18))
                        .foregroundColor(Theme.ink)
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
            SectionHeader(chinese: "生詞", english: "Vocabulary")
            ForEach(vocab, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(item.char).font(Theme.serif(22, .medium)).foregroundColor(Theme.ink)
                    Text(item.pinyin).font(Theme.label(14)).foregroundColor(Theme.inkFaded)
                    Text(item.gloss).font(Theme.serif(15)).foregroundColor(Theme.ink)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
