//
//  ProgressStore.swift
//  ChinesePoems
//
//  Reading state: read seals, favorites, saved words, script + resume pointer.
//

import SwiftUI

/// Spaced-repetition state for one saved character (Leitner boxes).
struct ReviewState: Codable, Equatable {
    var box: Int        // 0...(intervals.count-1)
    var dueDate: Date   // next time this card should surface
}

@MainActor
final class ProgressStore: ObservableObject {
    /// Texts the reader has sealed as 已讀 (read).
    @Published var completedIDs: Set<String> { didSet { persist("completedIDs", completedIDs) } }
    /// Texts the reader has hearted (收藏 / favorites).
    @Published var favoritedIDs: Set<String> { didSet { persist("favoritedIDs", favoritedIDs) } }
    /// Individual characters the reader tapped to save.
    @Published var savedWords: Set<String> { didSet { persist("savedWords", savedWords) } }
    /// Spaced-repetition schedule, keyed by character. Stays in lock-step with `savedWords`.
    @Published var reviews: [String: ReviewState] { didSet { persistReviews() } }
    /// Script preference (traditional vs. simplified).
    @Published var useSimplified: Bool { didSet { UserDefaults.standard.set(useSimplified, forKey: "useSimplified") } }
    /// Last-opened text, for the Continue card.
    @Published var lastOpenedID: String? {
        didSet { UserDefaults.standard.set(lastOpenedID, forKey: "lastOpenedID") }
    }

    /// Leitner intervals in days, indexed by box.
    private static let boxDays = [1, 3, 7, 21, 60]

    init() {
        completedIDs = Set(UserDefaults.standard.stringArray(forKey: "completedIDs") ?? [])
        favoritedIDs = Set(UserDefaults.standard.stringArray(forKey: "favoritedIDs") ?? [])
        savedWords = Set(UserDefaults.standard.stringArray(forKey: "savedWords") ?? [])
        reviews = Self.loadReviews()
        useSimplified = UserDefaults.standard.object(forKey: "useSimplified") as? Bool ?? true
        lastOpenedID = UserDefaults.standard.string(forKey: "lastOpenedID")
        reconcileReviews()
    }

    private func persist(_ key: String, _ set: Set<String>) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    private func persistReviews() {
        if let data = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(data, forKey: "reviews")
        }
    }

    private static func loadReviews() -> [String: ReviewState] {
        guard let data = UserDefaults.standard.data(forKey: "reviews"),
              let decoded = try? JSONDecoder().decode([String: ReviewState].self, from: data)
        else { return [:] }
        return decoded
    }

    /// Keep `reviews` in lock-step with `savedWords`: seed missing cards (due now),
    /// drop orphans. Lets pre-existing saved characters enter the rotation immediately.
    private func reconcileReviews() {
        var next = reviews
        let now = Date()
        for word in savedWords where next[word] == nil {
            next[word] = ReviewState(box: 0, dueDate: now)
        }
        for key in next.keys where !savedWords.contains(key) {
            next[key] = nil
        }
        if next != reviews { reviews = next }
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
        if savedWords.contains(word) {
            savedWords.remove(word)
            reviews[word] = nil
        } else {
            savedWords.insert(word)
            reviews[word] = ReviewState(box: 0, dueDate: Date())
        }
    }

    // Spaced repetition
    func isDue(_ word: String) -> Bool {
        (reviews[word]?.dueDate ?? .distantPast) <= Date()
    }

    /// Saved characters that are due for review right now.
    var dueWords: [String] { savedWords.filter(isDue) }
    var dueCount: Int { dueWords.count }

    /// Correct recall — promote one Leitner box and push the due date out.
    func gradeGood(_ word: String) {
        let current = reviews[word]?.box ?? 0
        let next = min(current + 1, Self.boxDays.count - 1)
        schedule(word, box: next)
    }

    /// Missed — reset to the first box (review again tomorrow).
    func gradeAgain(_ word: String) {
        schedule(word, box: 0)
    }

    private func schedule(_ word: String, box: Int) {
        let days = Self.boxDays[box]
        let due = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        reviews[word] = ReviewState(box: box, dueDate: due)
    }

    func noteOpened(_ id: String) { lastOpenedID = id }
}
