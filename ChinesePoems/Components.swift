//
//  Components.swift
//  ChinesePoems
//
//  Shared list rows and cards used across the Read, Browse, and collection screens.
//

import SwiftUI

/// A single text in a list — read seal, title, author, length + favorite mark.
struct PoemRow: View {
    let poem: Poem
    @EnvironmentObject var store: ProgressStore

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Read status marker — a small cinnabar seal or an empty ring.
            if store.isComplete(poem.id) {
                SealMark(glyph: "讀", size: 30, filled: true)
            } else {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 1.5)
                    .frame(width: 30, height: 30)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(poem.titleChinese(simplified: store.useSimplified))
                    .font(Theme.serif(19, .medium))
                    .foregroundColor(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(poem.title)
                        .font(Theme.label(13))
                        .foregroundColor(Theme.inkFaded)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                if store.isFavorite(poem.id) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.cinnabar)
                }
                Text(poem.lengthLabel)
                    .font(Theme.serif(13))
                    .foregroundColor(Theme.inkWhisper)
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

/// The "pick up where you left off" hero card.
struct ContinueCard: View {
    let poem: Poem
    @EnvironmentObject var store: ProgressStore

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("繼續閱讀 · Continue")
                    .font(Theme.label(11))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(Theme.cinnabar)
                Text(poem.titleChinese(simplified: store.useSimplified))
                    .font(Theme.serif(26, .semibold))
                    .foregroundColor(Theme.ink)
                    .lineLimit(2)
                Text(poem.title)
                    .font(Theme.serif(14))
                    .foregroundColor(Theme.inkFaded)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(poem.collection.chinese)
                    Text("·")
                    Text(poem.resolvedTier.chinese)
                }
                .font(Theme.label(12))
                .foregroundColor(Theme.inkWhisper)
                .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(Theme.cinnabar)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.paperRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.cinnabar.opacity(0.25), lineWidth: 1)
        )
    }
}

/// A collection shelf card — Chinese name, count, read progress.
struct CollectionShelfCard: View {
    let collection: TextCollection
    let total: Int
    let read: Int

    private var progress: Double { total == 0 ? 0 : Double(read) / Double(total) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(collection.chinese)
                .font(Theme.serif(24, .semibold))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(collection.english)
                .font(Theme.label(11))
                .foregroundColor(Theme.inkFaded)
                .lineLimit(1)
            Spacer(minLength: 6)
            InkProgressBar(value: progress)
            HStack {
                Text("\(read) / \(total)")
                    .font(Theme.label(11))
                    .foregroundColor(Theme.inkWhisper)
                Spacer()
                Text("篇")
                    .font(Theme.serif(11))
                    .foregroundColor(Theme.inkWhisper)
            }
        }
        .padding(16)
        .frame(width: 152, height: 150, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Theme.paperRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1)
        )
    }
}
