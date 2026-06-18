# Graded Course Spine + Reading UX — Design

**Date:** 2026-06-18
**Status:** Approved (user said "start coding")
**Workstream:** 1 of 4 (Product spine + reading UX). Content ingestion runs in parallel; full visual redesign + mascot artwork is a later workstream.

## Problem

The app is a flat list of 71 classical texts. A new buyer opens it, sees an undifferentiated list, and has no reason to stay or pay (one purchase → refund). Target user: advanced foreign learner of Mandarin (USA/Japan) who wants to *enjoy* classical Chinese / wenyanwen in the original. They need direction, more content, and Simplified-Chinese support.

## Decisions (locked)

- **Core loop:** a *graded course* — a climbing path through classical texts, easy → hard.
- **Mascot:** 鯉→龍 (carp leaps the dragon gate, 鯉躍龍門). Evolves from carp to dragon as the learner ascends. v1 ships with emoji/SF-Symbol placeholders; real art later.
- **Homepage:** a vertical **climbing path** of lesson nodes. Mascot sits at current position. Nodes: ● done / ○ not yet / → suggested next. One prominent **Continue**. Progress bar + level at top.
- **Progression:** **free-roam + track** — everything tappable, no gating; path shows suggested order and marks completion; mascot advances as nodes complete.
- **Reading screen:** keep as-is (vertical, tap-to-toggle). Add **Simplified Chinese**, **default Simplified**, per-reading toggle, remembers choice. Pinyin lookup works for both scripts.
- **Lesson contents:** original text + vocab list / **save words** (global deck) + English translation (toggle). No heavy grammar notes in v1.
- **Content:** keep ALL existing texts + ingest the classics (Daodejing, Analects, Mencius, Zhuangzi, Shiji 項羽/高祖 narratives) and Shadick's full selection; arrange into our own tiers.

## Tiers

`Foundations → Intermediate → Advanced → Master`. Each text has a `tier` and an `order` (position on path).

## Data model

`Poem` (Codable) gains optional fields so existing JSON still decodes:
- `content_simplified: String?` — generated from Traditional `content` via zhconv at content-prep time.
- `tier: String?` — one of the four tiers.
- `order: Int?` — position on the climbing path.
- `vocab: [VocabEntry]?` — `{char, pinyin, gloss}`, optional.
- `source: String?` — origin work (Daodejing, Analects, …).

Progress persisted locally (UserDefaults): set of completed ids, set of saved-word chars, script preference, default-script onboarding flag.

## Components

- `CourseHomeView` — climbing path (root view, replaces flat list). Reads poems, groups/sorts by `tier`+`order`, renders path nodes + mascot + progress header + Continue.
- `ProgressStore` (ObservableObject) — completed ids, saved words, script pref; persisted to UserDefaults.
- `MascotView` — carp→dragon stage from completion %.
- `PoemDetailView` — add trad/simp toggle (default simp), vocab section, save-word; mark-complete on appear/read.
- Content prep script (`chinese_dictionary_tools/prep_content.py`) — merges `content_incoming/*.json` into `poems.json`, generates `content_simplified`, assigns `tier`/`order`.

## Out of scope (later)

Bulk ingest pipeline polish; full aesthetic redesign + mascot art; read-aloud audio; SRS review; stroke order.
