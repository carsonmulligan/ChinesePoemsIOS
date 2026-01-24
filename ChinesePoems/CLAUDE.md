# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Pure SwiftUI iOS app with no external dependencies. Open `ChinesePoems.xcodeproj` in Xcode 16.2+ and build.

- **Main app target:** ChinesePoems
- **App Clip target:** VerticalChinese (in `/VerticalChinese/`, stub/placeholder)
- **Deployment target:** iOS 18.2
- **Swift version:** 5.0

No package managers (SPM, CocoaPods) are used.

## Architecture

Single-file SwiftUI architecture in `ContentView.swift`:

- **Models:** `Poem` and `DictionaryEntry` (Codable structs, lines 11-26)
- **Views:**
  - `ContentView` - NavigationStack with poem list, loads from `poems.json`
  - `PoemDetailView` - Chinese/English toggle and pinyin display
  - `ChineseTextColumn` - Vertical character-by-character layout with optional pinyin
  - `EnglishTextColumn` - Word-by-word English translation layout

Data is loaded from bundled JSON files at runtime using `Bundle.main` and `JSONDecoder`.

## Key Data Files

- `poems.json` - 185+ classical Chinese poems (keyed by ID)
- `chinese_to_pinyin_dictionary_with_tones.json` - 73K character pinyin lookup

Poem structure: `id`, `title_chinese`, `title`, `author_chinese`, `author`, `content`, `translation_english`

## Development Notes

- Debug print statements in `loadPinyinDictionary()` (ContentView.swift:120-145) - remove before App Store submission
- No test targets configured
- App Store metadata in `text.json`

## Roadmap (notes/TODO.md)

Pending: remove debug lines, add more poems, App Store submission
Future: save words function, read aloud, character stroke query
