//
//  CourseHomeView.swift
//  ChinesePoems
//
//  The graded-course home: a climbing path from carp to dragon (鯉躍龍門).
//  Texts are ordered easiest -> hardest; the mascot evolves as lessons complete.
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
        VStack(spacing: 12) {
            Text(stage.emoji)
                .font(.system(size: 64))
            Text(stage.label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            ProgressView(value: progress)
                .tint(.accentColor)
                .frame(maxWidth: 220)

            Text("\(completed) / \(total) 篇 完成")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - A single node on the climbing path

struct PathNodeRow: View {
    let poem: Poem
    let isComplete: Bool
    let isCurrent: Bool
    let simplified: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Connector + node marker
            ZStack {
                if isCurrent {
                    Text("🐟").font(.system(size: 26))
                } else {
                    Circle()
                        .fill(isComplete ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: 14, height: 14)
                }
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(poem.titleChinese(simplified: simplified))
                    .font(.system(size: 19, weight: isCurrent ? .semibold : .regular))
                    .foregroundColor(.primary)
                Text(poem.title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isCurrent {
                Text("繼續")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
            } else if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(isCurrent ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Course home (climbing path)

struct CourseHomeView: View {
    @EnvironmentObject var store: ProgressStore
    @State private var poems: [Poem] = []
    @State private var path: [Poem] = []

    private var sorted: [Poem] { poems.sorted { $0.sortOrder < $1.sortOrder } }
    private var currentPoem: Poem? { sorted.first { !store.isComplete($0.id) } ?? sorted.last }
    private var completedCount: Int { poems.filter { store.isComplete($0.id) }.count }
    private var progress: Double { poems.isEmpty ? 0 : Double(completedCount) / Double(poems.count) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        MascotView(progress: progress, completed: completedCount, total: poems.count)

                        if let current = currentPoem {
                            Button {
                                path.append(current)
                            } label: {
                                Label("繼續 · Continue", systemImage: "arrow.right.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }

                        ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, poem in
                            if idx == 0 || sorted[idx - 1].resolvedTier != poem.resolvedTier {
                                tierHeader(poem.resolvedTier)
                            }
                            NavigationLink(value: poem) {
                                PathNodeRow(
                                    poem: poem,
                                    isComplete: store.isComplete(poem.id),
                                    isCurrent: poem.id == currentPoem?.id,
                                    simplified: store.useSimplified
                                )
                            }
                            .buttonStyle(.plain)
                            .id(poem.id)
                        }

                        dragonGate
                    }
                    .padding()
                }
                .onAppear {
                    if poems.isEmpty { loadPoems(proxy) }
                }
            }
            .navigationTitle("文言文 · Classical Chinese")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Poem.self) { poem in
                PoemDetailView(poem: poem)
            }
        }
    }

    private func tierHeader(_ tier: CourseTier) -> some View {
        HStack(spacing: 8) {
            Text(tier.chinese)
                .font(.system(size: 17, weight: .bold))
            Text(tier.rawValue)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    private var dragonGate: some View {
        VStack(spacing: 8) {
            Text("🐉")
                .font(.system(size: 48))
            Text("龍門")
                .font(.system(size: 22, weight: .bold))
            Text("Dragon Gate · Mastery")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.bottom, 24)
    }

    private func loadPoems(_ proxy: ScrollViewProxy) {
        guard let url = Bundle.main.url(forResource: "poems", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: Poem].self, from: data) else {
            return
        }
        poems = Array(decoded.values)
        // Scroll to the learner's current node once content is laid out.
        if let current = currentPoem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { proxy.scrollTo(current.id, anchor: .center) }
            }
        }
    }
}

#Preview {
    CourseHomeView()
        .environmentObject(ProgressStore())
}
