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

                    credits
                }
                .padding(.vertical, 16)
            }
            .paperBackground()
            .navigationTitle("我")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.cinnabar)
    }

    private var credits: some View {
        VStack(spacing: 4) {
            Text("詞典 · CC-CEDICT (CC BY-SA 4.0) · MDBG")
            Text("筆順 · Make Me a Hanzi (MIT / Arphic PL)")
            Text("例句 · Tatoeba (CC BY 2.0 FR)")
        }
        .font(Theme.label(11))
        .foregroundColor(Theme.inkWhisper)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
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

}
