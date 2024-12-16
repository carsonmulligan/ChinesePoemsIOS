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
            List(poems) { poem in
                VStack(alignment: .leading) {
                    Text(poem.title_chinese)
                        .font(.headline)
                    Text(poem.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(poem.author_chinese)
                        .font(.caption)
                }
                .onTapGesture {
                    selectedPoem = poem
                    showingDetail = true
                }
            }
            .navigationTitle("Chinese Poems")
            .sheet(isPresented: $showingDetail) {
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
        if let url = Bundle.main.url(forResource: "poems", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decodedData = try JSONDecoder().decode([String: Poem].self, from: data)
                poems = Array(decodedData.values)
            } catch {
                print("Error loading poems: \(error)")
            }
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
            ScrollView {
                VStack {
                    if showTranslation {
                        HStack(spacing: 40) {
                            VerticalText(text: poem.content)
                                .frame(maxHeight: .infinity)
                            VerticalText(text: poem.translation_english)
                                .frame(maxHeight: .infinity)
                        }
                    } else {
                        VerticalText(text: poem.content)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
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

// Custom view for vertical text
struct VerticalText: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(text), id: \.self) { character in
                Text(String(character))
                    .font(.system(size: 24))
                    .rotationEffect(.degrees(String(character).containsEnglish() ? 0 : 90))
            }
        }
    }
}

// Helper extension to check if a string contains English characters
extension String {
    func containsEnglish() -> Bool {
        let pattern = "[A-Za-z]"
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    ContentView()
}
