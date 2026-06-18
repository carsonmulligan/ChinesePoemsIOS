//
//  BrowseView.swift
//  ChinesePoems
//
//  尋 — search all texts with difficulty + collection filters.
//

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    @State private var query = ""
    @State private var tier: CourseTier? = nil
    @State private var collection: TextCollection? = nil

    private var results: [Poem] {
        repo.search(query, tier: tier, collection: collection)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Rectangle().fill(Theme.hairline).frame(height: 0.5)

                if results.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { poem in
                                NavigationLink(value: poem) {
                                    PoemRow(poem: poem).padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 60)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .paperBackground()
            .navigationTitle("尋")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Poem.self) { ReadingView(poem: $0) }
            .searchable(text: $query, prompt: "搜尋 · title, author, text")
        }
        .tint(Theme.cinnabar)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("\(results.count) 篇")
                    .font(Theme.label(12))
                    .foregroundColor(Theme.inkWhisper)
                    .padding(.trailing, 4)

                ForEach(CourseTier.allCases) { t in
                    chip(t.chinese, active: tier == t) {
                        tier = (tier == t) ? nil : t
                    }
                }
                Rectangle().fill(Theme.hairline).frame(width: 1, height: 18)
                ForEach(repo.collections) { c in
                    chip(c.chinese, active: collection?.id == c.id) {
                        collection = (collection?.id == c.id) ? nil : c
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private func chip(_ text: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(Theme.serif(14, .medium))
                .foregroundColor(active ? Color(hex: 0xFBF5E6) : Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(active ? Theme.cinnabar : Theme.paperRaised)
                )
                .overlay(
                    Capsule().stroke(active ? Color.clear : Theme.hairline, lineWidth: 1)
                )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("無")
                .font(Theme.serif(44))
                .foregroundColor(Theme.inkWhisper)
            Text("No matching texts")
                .font(Theme.serif(15))
                .foregroundColor(Theme.inkFaded)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
