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
    @State private var showTranslation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(poems) { poem in
                        NavigationLink(destination: PoemDetailView(poem: poem, showTranslation: $showTranslation)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(poem.title_chinese)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(poem.title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(poem.author_chinese)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                        Divider()
                    }
                }
                .padding()
            }
            .navigationTitle("Chinese Poems")
        }
        .onAppear {
            loadPoems()
        }
    }
    
    private func loadPoems() {
        print("DEBUG: Starting to load poems...")
        
        // Check if file exists in bundle
        let bundle = Bundle.main
        print("DEBUG: Bundle path: \(bundle.bundlePath)")
        
        if let path = bundle.path(forResource: "poems", ofType: "json") {
            print("DEBUG: Found poems.json at path: \(path)")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                print("DEBUG: Successfully read data, size: \(data.count) bytes")
                
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([String: Poem].self, from: data)
                poems = Array(decodedData.values).sorted { $0.title_chinese < $1.title_chinese }
                print("DEBUG: Successfully decoded \(poems.count) poems")
                
                // Print first poem as verification
                if let firstPoem = poems.first {
                    print("DEBUG: First poem - Title: \(firstPoem.title_chinese)")
                }
            } catch {
                print("DEBUG: Error loading poems: \(error)")
                print("DEBUG: Error details: \(error.localizedDescription)")
            }
        } else {
            print("DEBUG: Could not find poems.json in bundle")
            
            // List all files in bundle for debugging
            if let resources = try? FileManager.default.contentsOfDirectory(atPath: bundle.bundlePath) {
                print("DEBUG: Files in bundle:")
                resources.forEach { print("DEBUG: - \($0)") }
            }
        }
    }
}

// Detail view for individual poems
struct PoemDetailView: View {
    let poem: Poem
    @Binding var showTranslation: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if showTranslation {
                    EnglishTextColumn(text: poem.translation_english)
                        .padding(.horizontal)
                } else {
                    ChineseTextColumn(text: poem.content)
                }
            }
            .padding(.vertical, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTranslation ? poem.title : poem.title_chinese)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(showTranslation ? "Show Chinese" : "Show English") {
                    showTranslation.toggle()
                }
            }
        }
    }
}

struct ChineseTextColumn: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

struct EnglishTextColumn: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(text.split(separator: " ").enumerated().map { index, word in
                (index, String(word))
            }, id: \.0) { _, word in
                Text(word)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
