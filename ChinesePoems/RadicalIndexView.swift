//
//  RadicalIndexView.swift
//  ChinesePoems
//
//  部首 — browse characters by radical, like Pleco's radical index. Radicals
//  are ordered by their own stroke count; tap one to see its characters.
//

import SwiftUI

struct RadicalIndexView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository
    @Environment(\.dismiss) private var dismiss

    /// (radical, characters) groups, radicals ordered by stroke count then glyph.
    private var groups: [(radical: String, chars: [String])] {
        var map: [String: [String]] = [:]
        for (char, info) in repo.radicals where !info.r.isEmpty {
            map[info.r, default: []].append(char)
        }
        return map
            .map { (radical: $0.key, chars: $0.value.sorted()) }
            .sorted {
                let a = repo.strokes[$0.radical]?.s.count ?? 99
                let b = repo.strokes[$1.radical]?.s.count ?? 99
                return a != b ? a < b : $0.radical < $1.radical
            }
    }

    private let cols = [GridItem(.adaptive(minimum: 56), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(groups, id: \.radical) { group in
                        NavigationLink(value: group.radical) {
                            VStack(spacing: 2) {
                                Text(group.radical)
                                    .font(Theme.serif(26, .medium))
                                    .foregroundColor(Theme.ink)
                                Text("\(group.chars.count)")
                                    .font(Theme.label(10))
                                    .foregroundColor(Theme.inkWhisper)
                            }
                            .frame(width: 56, height: 56)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.paperRaised))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
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
        .onAppear { repo.loadRadicalsIfNeeded(); repo.loadStrokesIfNeeded(); repo.loadWordsIfNeeded() }
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
                                             graphic: repo.strokes[char], radical: repo.radicals[char])
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
