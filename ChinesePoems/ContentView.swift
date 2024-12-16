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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Debug text to show we're getting the poem data
                    Text("Debug - Title: \(poem.title_chinese)")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("Debug - Content Length: \(poem.content.count) characters")
                        .font(.caption)
                        .foregroundColor(.red)
                        
                    if showTranslation {
                        HStack(alignment: .center, spacing: 40) {
                            ChineseTextColumn(text: poem.content)
                            EnglishTextColumn(text: poem.translation_english)
                        }
                        .padding(.horizontal)
                    } else {
                        ChineseTextColumn(text: poem.content)
                            .background(Color.gray.opacity(0.1)) // Debug background
                    }
                }
                .padding(.vertical, 40)
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
            .onAppear {
                print("Debug - PoemDetailView appeared")
                print("Debug - Poem content: \(poem.content.prefix(50))...")
            }
        }
    }
}

struct ChineseTextColumn: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Debug count
            Text("Debug - Characters: \(text.count)")
                .font(.caption)
                .foregroundColor(.red)
                
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primary)
                    .background(Color.yellow.opacity(0.1)) // Debug background
                    .onAppear {
                        if index == 0 {
                            print("Debug - First character appeared")
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .border(Color.blue, width: 1) // Debug border
    }
}

struct EnglishTextColumn: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Debug count
            Text("Debug - Words: \(text.split(separator: " ").count)")
                .font(.caption)
                .foregroundColor(.red)
                
            ForEach(text.split(separator: " ").enumerated().map { index, word in
                (index, String(word))
            }, id: \.0) { index, word in
                Text(word)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .fixedSize()
                    .background(Color.green.opacity(0.1)) // Debug background
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .border(Color.red, width: 1) // Debug border
    }
}

#Preview {
    ContentView()
}
