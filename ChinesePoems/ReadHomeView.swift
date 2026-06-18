//
//  ReadHomeView.swift
//  ChinesePoems
//
//  Home (閱讀): Continue card, Saved strip, and Collection shelves.
//

import SwiftUI

struct ReadHomeView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    private var continuePoem: Poem? {
        if let id = store.lastOpenedID, let p = repo.poem(id: id) { return p }
        return repo.poems.first
    }
    private var saved: [Poem] {
        repo.poems.filter { store.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    masthead

                    if let poem = continuePoem {
                        NavigationLink(value: poem) {
                            ContinueCard(poem: poem)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    if !saved.isEmpty { savedStrip }

                    collectionsSection
                }
                .padding(.vertical, 16)
            }
            .paperBackground()
            .navigationDestination(for: Poem.self) { ReadingView(poem: $0) }
            .navigationDestination(for: TextCollection.self) { CollectionDetailView(collection: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Theme.cinnabar)
    }

    // MARK: Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("文言")
                .font(Theme.serif(40, .bold))
                .foregroundColor(Theme.ink)
            HStack(spacing: 8) {
                Rectangle().fill(Theme.cinnabar).frame(width: 22, height: 2)
                Text("CLASSICAL CHINESE")
                    .font(Theme.label(11))
                    .tracking(3)
                    .foregroundColor(Theme.inkFaded)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: Saved strip

    private var savedStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(chinese: "收藏", english: "Saved")
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(saved) { poem in
                        NavigationLink(value: poem) {
                            savedCard(poem)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func savedCard(_ poem: Poem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.cinnabar)
            Spacer(minLength: 0)
            Text(poem.titleChinese(simplified: store.useSimplified))
                .font(Theme.serif(20, .medium))
                .foregroundColor(Theme.ink)
                .lineLimit(2)
            Text(poem.title)
                .font(Theme.label(11))
                .foregroundColor(Theme.inkFaded)
                .lineLimit(1)
        }
        .frame(width: 140, height: 120, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.paperRaised))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
    }

    // MARK: Collections

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(chinese: "典籍", english: "Collections")
                .padding(.horizontal)

            let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(repo.collections) { collection in
                    let texts = repo.poems(in: collection)
                    let read = texts.filter { store.isComplete($0.id) }.count
                    NavigationLink(value: collection) {
                        CollectionShelfCard(collection: collection, total: texts.count, read: read)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
