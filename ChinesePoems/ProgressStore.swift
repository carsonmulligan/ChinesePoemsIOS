//
//  ProgressStore.swift
//  ChinesePoems
//
//  Reading state: read seals, favorites, saved words, script + resume pointer.
//

import SwiftUI

@MainActor
final class ProgressStore: ObservableObject {
    /// Texts the reader has sealed as 已讀 (read).
    @Published var completedIDs: Set<String> { didSet { persist("completedIDs", completedIDs) } }
    /// Texts the reader has hearted (收藏 / favorites).
    @Published var favoritedIDs: Set<String> { didSet { persist("favoritedIDs", favoritedIDs) } }
    /// Individual characters the reader tapped to save.
    @Published var savedWords: Set<String> { didSet { persist("savedWords", savedWords) } }
    /// Script preference (traditional vs. simplified).
    @Published var useSimplified: Bool { didSet { UserDefaults.standard.set(useSimplified, forKey: "useSimplified") } }
    /// Last-opened text, for the Continue card.
    @Published var lastOpenedID: String? {
        didSet { UserDefaults.standard.set(lastOpenedID, forKey: "lastOpenedID") }
    }

    init() {
        completedIDs = Set(UserDefaults.standard.stringArray(forKey: "completedIDs") ?? [])
        favoritedIDs = Set(UserDefaults.standard.stringArray(forKey: "favoritedIDs") ?? [])
        savedWords = Set(UserDefaults.standard.stringArray(forKey: "savedWords") ?? [])
        useSimplified = UserDefaults.standard.object(forKey: "useSimplified") as? Bool ?? true
        lastOpenedID = UserDefaults.standard.string(forKey: "lastOpenedID")
    }

    private func persist(_ key: String, _ set: Set<String>) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    // Read seals
    func isComplete(_ id: String) -> Bool { completedIDs.contains(id) }
    func markComplete(_ id: String) { completedIDs.insert(id) }
    func toggleComplete(_ id: String) {
        if completedIDs.contains(id) { completedIDs.remove(id) } else { completedIDs.insert(id) }
    }

    // Favorites
    func isFavorite(_ id: String) -> Bool { favoritedIDs.contains(id) }
    func toggleFavorite(_ id: String) {
        if favoritedIDs.contains(id) { favoritedIDs.remove(id) } else { favoritedIDs.insert(id) }
    }

    // Saved characters
    func isSaved(_ word: String) -> Bool { savedWords.contains(word) }
    func toggleSaved(_ word: String) {
        if savedWords.contains(word) { savedWords.remove(word) } else { savedWords.insert(word) }
    }

    func noteOpened(_ id: String) { lastOpenedID = id }
}
