//
//  RootTabView.swift
//  ChinesePoems
//
//  Four tabs: 閱讀 (Read), 尋 (Browse), 字 (Dictionary), 我 (Me).
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ReadHomeView()
                .tabItem { Label("閱讀", systemImage: "book") }
            BrowseView()
                .tabItem { Label("尋", systemImage: "magnifyingglass") }
            DictionaryView()
                .tabItem { Label("字", systemImage: "character.book.closed") }
            MeView()
                .tabItem { Label("我", systemImage: "person") }
        }
        .tint(Theme.cinnabar)
    }
}
