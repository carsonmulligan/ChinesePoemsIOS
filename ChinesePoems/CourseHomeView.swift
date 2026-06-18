//
//  CourseHomeView.swift
//  ChinesePoems
//
//  The carp→dragon mascot (鯉躍龍門) — a playful read-count progress emblem,
//  reused on the 我 (Me) tab. The old climbing-path home was replaced by the
//  3-tab library; only the mascot survives here.
//

import SwiftUI

// MARK: - Mascot (carp -> dragon)

struct MascotStage {
    let emoji: String
    let label: String

    static func forProgress(_ p: Double) -> MascotStage {
        switch p {
        case ..<0.25: return MascotStage(emoji: "🐟", label: "鯉魚 · Carp")
        case ..<0.50: return MascotStage(emoji: "🐠", label: "躍 · Leaping")
        case ..<0.85: return MascotStage(emoji: "🐉", label: "化龍 · Transforming")
        default:      return MascotStage(emoji: "🐲", label: "龍 · Dragon")
        }
    }
}

struct MascotView: View {
    let progress: Double
    let completed: Int
    let total: Int

    private var stage: MascotStage { MascotStage.forProgress(progress) }

    var body: some View {
        VStack(spacing: 14) {
            Text(stage.emoji)
                .font(.system(size: 72))
            Text(stage.label)
                .font(Theme.serif(16, .medium))
                .foregroundColor(Theme.inkFaded)

            InkProgressBar(value: progress, height: 5)
                .frame(maxWidth: 220)

            Text("\(completed) / \(total) 篇 完成")
                .font(Theme.label(13))
                .foregroundColor(Theme.inkWhisper)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
