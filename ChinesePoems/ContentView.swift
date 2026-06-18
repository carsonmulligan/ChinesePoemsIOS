//
//  ContentView.swift
//  ChinesePoems
//
//  The app was refactored into focused files:
//    • Models.swift          — Poem, DictionaryEntry, VocabEntry, CourseTier, TextCollection
//    • ProgressStore.swift   — reading state (read seals, favorites, saved words)
//    • PoemsRepository.swift — JSON loading + queries
//    • Theme.swift           — "rice paper & cinnabar" design system
//    • RootTabView.swift     — 閱讀 / 尋 / 我 tabs
//    • ReadHomeView / CollectionDetailView / BrowseView / MeView
//    • ReadingView.swift     — the reading experience (fixed pinyin gutter)
//
//  This file is intentionally a thin entry alias so older references resolve.
//

import SwiftUI

struct ContentView: View {
    var body: some View { RootTabView() }
}

#Preview {
    RootTabView()
        .environmentObject(ProgressStore())
        .environmentObject(PoemsRepository())
}
