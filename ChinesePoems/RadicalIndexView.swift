//
//  RadicalIndexView.swift
//  ChinesePoems
//
//  部首 — browse characters by radical, like Pleco's radical index. Radicals
//  are ordered by their own stroke count; tap one to see its characters.
//

import SwiftUI

struct RadicalGroup: Identifiable {
    let radical: String
    let chars: [String]
    var id: String { radical }
}

struct RadicalIndexView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository
    @Environment(\.dismiss) private var dismiss

    /// Radical groups ordered by the radical's own stroke count, then glyph.
    private var groups: [RadicalGroup] {
        var map: [String: [String]] = [:]
        for (char, info) in repo.radicals where !info.r.isEmpty {
            map[info.r, default: []].append(char)
        }
        var result: [RadicalGroup] = []
        for (radical, chars) in map {
            result.append(RadicalGroup(radical: radical, chars: chars.sorted()))
        }
        result.sort { lhs, rhs in
            let a = repo.strokes[lhs.radical]?.s.count ?? 99
            let b = repo.strokes[rhs.radical]?.s.count ?? 99
            return a != b ? a < b : lhs.radical < rhs.radical
        }
        return result
    }

    private let cols = [GridItem(.adaptive(minimum: 56), spacing: 10)]

    var body: some View {
        NavigationStack {
            grid
                .paperBackground()
                .navigationTitle("部首 · Radicals")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: String.self) { radical in
                    RadicalCharsView(radical: radical,
                                     chars: groups.first { $0.radical == radical }?.chars ?? [])
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { dismiss() }.tint(Theme.cinnabar)
                    }
                }
        }
        .tint(Theme.cinnabar)
        .onAppear {
            repo.loadRadicalsIfNeeded(); repo.loadStrokesIfNeeded()
            repo.loadWordsIfNeeded(); repo.loadSentencesIfNeeded()
        }
    }

    private var grid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(groups) { group in
                    NavigationLink(value: group.radical) {
                        radicalCell(group.radical, count: group.chars.count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func radicalCell(_ radical: String, count: Int) -> some View {
        VStack(spacing: 2) {
            Text(radical)
                .font(Theme.serif(26, .medium))
                .foregroundColor(Theme.ink)
            Text("\(count)")
                .font(Theme.label(10))
                .foregroundColor(Theme.inkWhisper)
        }
        .frame(width: 56, height: 56)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.paperRaised))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
    }
}

private struct RadicalCharsView: View {
    let radical: String
    let chars: [String]
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository
    @State private var selected: String?

    private let cols = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(chars, id: \.self) { char in
                    Text(char)
                        .font(Theme.serif(26, .medium))
                        .foregroundColor(store.isSaved(char) ? Theme.cinnabar : Theme.ink)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.paperRaised))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                        .onTapGesture { selected = char }
                        .popover(isPresented: Binding(
                            get: { selected == char },
                            set: { if !$0 { selected = nil } }
                        )) {
                            CharacterPopover(charStr: char, entry: repo.entry(for: char), store: store,
                                             graphic: repo.strokes[char], radical: repo.radicals[char],
                                             sentences: repo.sentences)
                                .presentationCompactAdaptation(.popover)
                        }
                }
            }
            .padding()
        }
        .paperBackground()
        .navigationTitle("\(radical) · \(chars.count)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
