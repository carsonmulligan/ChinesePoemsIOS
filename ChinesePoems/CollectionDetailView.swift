//
//  CollectionDetailView.swift
//  ChinesePoems
//
//  One source work (道德經, 論語 …) with its texts and read progress.
//

import SwiftUI

struct CollectionDetailView: View {
    let collection: TextCollection
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    private var texts: [Poem] { repo.poems(in: collection) }
    private var read: Int { texts.filter { store.isComplete($0.id) }.count }
    private var progress: Double { texts.isEmpty ? 0 : Double(read) / Double(texts.count) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                LazyVStack(spacing: 0) {
                    ForEach(texts) { poem in
                        NavigationLink(value: poem) {
                            PoemRow(poem: poem).padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 60)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 12)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(collection.chinese)
                    .font(Theme.serif(17, .semibold))
                    .foregroundColor(Theme.ink)
            }
        }
        .tint(Theme.cinnabar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(collection.chinese)
                .font(Theme.serif(34, .bold))
                .foregroundColor(Theme.ink)
            Text(collection.english.uppercased())
                .font(Theme.label(12))
                .tracking(2)
                .foregroundColor(Theme.inkFaded)
            VStack(alignment: .leading, spacing: 6) {
                InkProgressBar(value: progress)
                Text("\(read) / \(texts.count) 篇 已讀")
                    .font(Theme.label(12))
                    .foregroundColor(Theme.inkWhisper)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
