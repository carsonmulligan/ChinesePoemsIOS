//
//  FlashcardView.swift
//  ChinesePoems
//
//  練習 — a spaced-repetition flashcard session over saved characters.
//  Tap a card to flip (character → pinyin + definition), then grade it
//  再 (Again) / 識 (Got it). "Again" recycles the card to the end of the
//  session; "Got it" promotes its Leitner box and removes it from the deck.
//

import SwiftUI

struct FlashcardView: View {
    /// The characters/words to review this session (already chosen by the caller).
    let words: [String]
    let entries: [String: DictionaryEntry]
    @ObservedObject var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [String] = []
    @State private var flipped = false
    @State private var reviewed = 0   // count graded "Got it" — also the progress numerator
    @State private var total = 0
    @State private var loaded = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if let word = queue.first {
                Spacer()
                card(for: word)
                    .padding(.horizontal, 28)
                Spacer()
                controls(for: word)
            } else {
                Spacer()
                summary
                Spacer()
            }
        }
        .paperBackground()
        .onAppear {
            guard !loaded else { return }
            loaded = true
            queue = words.shuffled()
            total = queue.count
        }
    }

    // MARK: Header (progress + close)

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.inkFaded)
            }
            Spacer()
            if total > 0 {
                Text("\(reviewed) / \(total)")
                    .font(Theme.label(14))
                    .foregroundColor(Theme.inkFaded)
            }
            Spacer()
            // Balance the close button so the count stays centered.
            Image(systemName: "xmark").font(.system(size: 16, weight: .medium)).opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: Card

    private func card(for word: String) -> some View {
        let entry = entries[word]
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { flipped.toggle() }
        } label: {
            VStack(spacing: 18) {
                Text(word)
                    .font(Theme.serif(96, .medium))
                    .foregroundColor(Theme.ink)

                if flipped {
                    if let entry {
                        Text(entry.pinyin_tone_lines)
                            .font(Theme.label(22))
                            .foregroundColor(Theme.cinnabar)
                        Text(entry.definition.isEmpty ? "—" : entry.definition)
                            .font(Theme.serif(18))
                            .foregroundColor(Theme.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("No dictionary entry · 暫無釋義")
                            .font(Theme.serif(15))
                            .foregroundColor(Theme.inkWhisper)
                    }
                } else {
                    Text("輕點翻面 · tap to reveal")
                        .font(Theme.label(13))
                        .foregroundColor(Theme.inkWhisper)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 44)
            .padding(.horizontal, 24)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.paperRaised))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Grade buttons

    @ViewBuilder
    private func controls(for word: String) -> some View {
        if flipped {
            HStack(spacing: 14) {
                gradeButton("再 · Again", filled: false) {
                    store.gradeAgain(word)
                    advance(word, recycle: true)
                }
                gradeButton("識 · Got it", filled: true) {
                    store.gradeGood(word)
                    reviewed += 1
                    advance(word, recycle: false)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        } else {
            Text("輕點卡片查看讀音與釋義")
                .font(Theme.label(13))
                .foregroundColor(Theme.inkWhisper)
                .padding(.bottom, 44)
        }
    }

    private func gradeButton(_ label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.serif(17, .medium))
                .foregroundColor(filled ? Color(hex: 0xFBF5E6) : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(filled ? Theme.cinnabar : Theme.paperRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.hairline, lineWidth: filled ? 0 : 1)
                )
        }
    }

    // MARK: Deck control

    private func advance(_ word: String, recycle: Bool) {
        flipped = false
        if !queue.isEmpty { queue.removeFirst() }
        if recycle { queue.append(word) }
    }

    // MARK: Done

    private var summary: some View {
        VStack(spacing: 14) {
            SealMark(glyph: "識", size: 44, filled: true)
            Text("完成")
                .font(Theme.serif(28, .semibold))
                .foregroundColor(Theme.ink)
            Text("\(reviewed) 字複習完畢 · reviewed")
                .font(Theme.serif(15))
                .foregroundColor(Theme.inkFaded)
            Button { dismiss() } label: {
                Text("完成 · Done")
                    .font(Theme.serif(16, .medium))
                    .foregroundColor(Color(hex: 0xFBF5E6))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.cinnabar))
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}
