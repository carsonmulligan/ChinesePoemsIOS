# ChinesePoems Redesign — Design

Date: 2026-06-18

## Goal
Turn the app into a beautiful classical-Chinese reading library that gracefully
holds 257 texts across real source collections, while preserving the reading
experience users love (vertical characters + 繁/简 + pinyin + English toggles).

## Decisions (from brainstorming)
- **Home model:** Hybrid — Continue (resume last-opened) + Saved (hearted) +
  Collection shelves. Difficulty is a badge/filter, not the spine.
- **Pinyin layout:** Fixed pinyin gutter. Character sits in a fixed centered
  slot (straight column); pinyin sits in a fixed-width gutter, left-aligned
  (its own straight line). Toggling pinyin never moves the character axis.
- **Visual mood:** Rice paper & cinnabar (宣紙 + 朱紅). Warm cream ground,
  ink-black serif, single cinnabar accent used like a seal. Light-first with a
  warm dark mode. Refined literati minimalism.
- **Progress:** Manual only. A text is unread / 已讀 (cinnabar seal toggle).
  Collection progress bar = sealed count / total. No scroll-resume.

## Information architecture (3-tab TabView)
1. **閱讀 Read** — Continue card, Saved strip, Collection shelves.
2. **尋 Browse** — all texts, search (Chinese/English/author) + tier + collection filter.
3. **我 Me** — carp→dragon mascot + stats, saved-words list, script default toggle.

## Collections (derived)
`collection` derived from `source`, falling back to `author` for the 71
untagged texts (Wang Fanzhi Zen poems, stray Zhuangzi/Laozi). Stable id +
Chinese + English label. Curated display order, classics first.

## State (ProgressStore)
- Keep: `completedIDs` (= 已讀), `savedWords`, `useSimplified`.
- Add: `favoritedIDs: Set<String>` (hearts), `lastOpenedID: String?` (Continue).
- All persisted to UserDefaults.

## Data loading
New `PoemsRepository` (ObservableObject) loads `poems.json` once and the large
pinyin dictionary lazily on first reading view. Shared via `.environmentObject`.

## Files
- New: `Theme.swift`, `PoemsRepository.swift`, `RootTabView.swift`,
  `ReadHomeView.swift`, `CollectionDetailView.swift`, `BrowseView.swift`,
  `MeView.swift`, `ReadingView.swift`.
- Refactor: split `ContentView.swift` (models → `Models.swift`, store →
  `ProgressStore.swift`, detail → `ReadingView.swift` with the pinyin fix).
- `CourseHomeView.swift` reduced to reusable `MascotView` (used by Me tab).
- Preserve: `SpeedReaderView` (reachable from reading view).

## Out of scope (YAGNI)
Accounts/sync, scroll-position resume, user-authored tags, audio/stroke.
