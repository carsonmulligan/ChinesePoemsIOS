//
//  MeView.swift
//  ChinesePoems
//
//  我 — the reader's progress (carp→dragon), saved characters, and settings.
//

import SwiftUI

struct MeView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var repo: PoemsRepository

    private var read: Int { repo.poems.filter { store.isComplete($0.id) }.count }
    private var total: Int { repo.totalCount }
    private var progress: Double { total == 0 ? 0 : Double(read) / Double(total) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    MascotView(progress: progress, completed: read, total: total)

                    statsRow

                    scriptToggle

                    if !store.savedWords.isEmpty { savedWordsSection }
                }
                .padding(.vertical, 16)
            }
            .paperBackground()
            .navigationTitle("我")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.cinnabar)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat("\(read)", "已讀 Read")
            stat("\(store.favoritedIDs.count)", "收藏 Saved")
            stat("\(store.savedWords.count)", "生字 Words")
        }
        .padding(.horizontal)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Theme.serif(28, .semibold))
                .foregroundColor(Theme.cinnabar)
            Text(label)
                .font(Theme.label(11))
                .foregroundColor(Theme.inkFaded)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.paperRaised))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
    }

    private var scriptToggle: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(chinese: "字體", english: "Script")
            HStack(spacing: 0) {
                scriptOption("繁體 Traditional", selected: !store.useSimplified) {
                    store.useSimplified = false
                }
                scriptOption("简体 Simplified", selected: store.useSimplified) {
                    store.useSimplified = true
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.paperSunken))
        }
        .padding(.horizontal)
    }

    private func scriptOption(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.serif(15, .medium))
                .foregroundColor(selected ? Color(hex: 0xFBF5E6) : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selected ? Theme.cinnabar : Color.clear)
                )
        }
        .padding(3)
    }

    private var savedWordsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(chinese: "生字簿", english: "Saved characters")
            let cols = [GridItem(.adaptive(minimum: 52), spacing: 10)]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(Array(store.savedWords).sorted(), id: \.self) { word in
                    Text(word)
                        .font(Theme.serif(24, .medium))
                        .foregroundColor(Theme.ink)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.paperRaised))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                        .onTapGesture { store.toggleSaved(word) }
                }
            }
        }
        .padding(.horizontal)
    }
}
