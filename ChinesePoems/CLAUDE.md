# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a pure SwiftUI iOS app with no external dependencies. Open `ChinesePoems.xcodeproj` in Xcode 16.2+ and build.

- **Main app target:** ChinesePoems (select this scheme to run)
- **App Clip target:** VerticalChinese (stub/placeholder, not yet functional)
- **Deployment target:** iOS 18.2
- **Swift version:** 5.0

No package managers (SPM, CocoaPods) are used.

## Architecture

Single-file SwiftUI architecture in `ContentView.swift`:

- **Models:** `Poem` and `DictionaryEntry` (Codable structs)
- **Views:**
  - `ContentView` - NavigationStack with poem list
  - `PoemDetailView` - Individual poem with Chinese/English toggle and pinyin display
  - `ChineseTextColumn` - Vertical character-by-character layout with optional pinyin
  - `EnglishTextColumn` - Word-by-word English translation layout

Data is loaded from bundled JSON files at runtime using `Bundle.main` and `JSONDecoder`.

## Key Data Files

- `poems.json` - 185+ classical Chinese poems with translations (keyed by ID)
- `chinese_to_pinyin_dictionary_with_tones.json` - 73K character pinyin lookup dictionary

Poem structure: `id`, `title_chinese`, `title`, `author_chinese`, `author`, `content`, `translation_english`

## Development Notes

- Debug print statements exist in `loadPinyinDictionary()` - remove before App Store submission
- No test targets configured
- App Store metadata stored in `text.json`

## Roadmap (from notes/TODO.md)

Pending: remove debug lines, ship to main, add more poems, App Store submission
Future: save words function, read aloud, character stroke query
