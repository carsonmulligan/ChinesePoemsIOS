#!/usr/bin/env python3
"""Prepare poems.json for the graded course.

- Merges every content_incoming/*.json file into poems.json (idempotent; re-run
  freely as content-gathering agents deliver more files).
- Generates `content_simplified` (and simplified titles) from Traditional via zhconv.
- Assigns `tier` and a global `order` so the climbing-path homepage has a sequence.

Run from the project root:
    python3 chinese_dictionary_tools/prep_content.py
"""
import json
import glob
import os

import zhconv  # pip install zhconv

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POEMS = os.path.join(ROOT, "poems.json")
INCOMING_DIR = os.path.join(ROOT, "content_incoming")

TIER_RANK = {"Foundations": 0, "Intermediate": 1, "Advanced": 2, "Master": 3}
DEFAULT_TIER = "Foundations"

# Known classics already in poems.json get a sensible tier.
TITLE_TIER = {
    "大學": "Foundations",
    "中庸": "Intermediate",
    "論語": "Foundations",
}


def to_simplified(text):
    if not text:
        return text
    return zhconv.convert(text, "zh-hans")


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    poems = load_json(POEMS)
    print(f"loaded {len(poems)} existing entries")

    # 1. Merge incoming files.
    merged = 0
    for path in sorted(glob.glob(os.path.join(INCOMING_DIR, "*.json"))):
        try:
            incoming = load_json(path)
        except Exception as e:
            print(f"  skip {os.path.basename(path)}: {e}")
            continue
        for key, entry in incoming.items():
            entry.setdefault("id", key)
            poems[key] = {**poems.get(key, {}), **entry}
            merged += 1
        print(f"  merged {len(incoming):>4} from {os.path.basename(path)}")
    if merged:
        print(f"merged {merged} incoming entries; total {len(poems)}")

    # 2. Simplified + tier per entry.
    for key, p in poems.items():
        content = p.get("content", "")
        p["content_simplified"] = to_simplified(content)
        p["title_chinese_simplified"] = to_simplified(p.get("title_chinese", ""))
        p["author_chinese_simplified"] = to_simplified(p.get("author_chinese", ""))
        if "tier" not in p:
            tier = p.get("tier_suggestion")
            if not tier:
                tier = TITLE_TIER.get(p.get("title_chinese", "").strip(), DEFAULT_TIER)
            p["tier"] = tier if tier in TIER_RANK else DEFAULT_TIER
        p.pop("tier_suggestion", None)

    # 3. Global order: by tier, then by content length (shorter == easier), then key.
    def sort_key(item):
        key, p = item
        return (
            TIER_RANK.get(p.get("tier", DEFAULT_TIER), 0),
            len(p.get("content", "")),
            key,
        )

    for order, (key, p) in enumerate(sorted(poems.items(), key=sort_key)):
        p["order"] = order

    with open(POEMS, "w", encoding="utf-8") as f:
        json.dump(poems, f, ensure_ascii=False, indent=2)

    by_tier = {}
    for p in poems.values():
        by_tier[p["tier"]] = by_tier.get(p["tier"], 0) + 1
    print(f"wrote {len(poems)} entries")
    for tier in TIER_RANK:
        print(f"  {tier}: {by_tier.get(tier, 0)}")


if __name__ == "__main__":
    main()
