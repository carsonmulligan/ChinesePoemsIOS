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

    var body: some Scene {
        WindowGroup {
            CourseHomeView()
                .environmentObject(store)
        }
    }
}
