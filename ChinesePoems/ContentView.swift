//
//  ContentView.swift
//  ChinesePoems
//
//  Created by Carson Mulligan on 12/15/24.
//

import SwiftUI

// Model for our poems
struct Poem: Identifiable, Codable {
    let id: String
    let title_chinese: String
    let title: String
    let author_chinese: String
    let author: String
    let content: String
    let translation_english: String
}

// Main content view
struct ContentView: View {
    @State private var poems: [Poem] = []
    @State private var selectedPoem: Poem?
    @State private var showingDetail = false
    @State private var showTranslation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(poems) { poem in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(poem.title_chinese)
                                .font(.headline)
                            Text(poem.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(poem.author_chinese)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPoem = poem
                            showingDetail = true
                        }
                        Divider()
                    }
                }
                .padding()
            }
            .navigationTitle("Chinese Poems")
            .fullScreenCover(isPresented: $showingDetail) {
                if let poem = selectedPoem {
                    PoemDetailView(poem: poem, showTranslation: $showTranslation)
                }
            }
        }
        .onAppear {
            loadPoems()
        }
    }
    
    private func loadPoems() {
        if let path = Bundle.main.path(forResource: "poems", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([String: Poem].self, from: data)
                poems = Array(decodedData.values).sorted { $0.title_chinese < $1.title_chinese }
                print("Loaded \(poems.count) poems")
            } catch {
                print("Error loading poems: \(error)")
            }
        } else {
            print("Could not find poems.json in bundle")
        }
    }
}

// Detail view for individual poems
struct PoemDetailView: View {
    let poem: Poem
    @Binding var showTranslation: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        if showTranslation {
                            HStack(alignment: .top, spacing: 40) {
                                VerticalPoemText(text: poem.content)
                                    .frame(width: geometry.size.width / 2 - 30)
                                VerticalPoemText(text: poem.translation_english, isEnglish: true)
                                    .frame(width: geometry.size.width / 2 - 30)
                            }
                        } else {
                            VerticalPoemText(text: poem.content)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding(.horizontal)
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle(poem.title_chinese)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showTranslation ? "Hide Translation" : "Show Translation") {
                        showTranslation.toggle()
                    }
                }
            }
        }
    }
}

// Improved vertical text view
struct VerticalPoemText: View {
    let text: String
    var isEnglish: Bool = false
    
    var body: some View {
        VStack(spacing: isEnglish ? 8 : 20) {
            ForEach(Array(text), id: \.self) { character in
                Text(String(character))
                    .font(.system(size: isEnglish ? 18 : 24, weight: .medium))
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
