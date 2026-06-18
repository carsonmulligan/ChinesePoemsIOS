//
//  ChinesePoemsApp.swift
//  ChinesePoems
//
//  Created by Carson Mulligan on 12/15/24.
//

import SwiftUI

@main
struct ChinesePoemsApp: App {
    @StateObject private var store = ProgressStore()
    @StateObject private var repo = PoemsRepository()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(repo)
        }
    }
}
