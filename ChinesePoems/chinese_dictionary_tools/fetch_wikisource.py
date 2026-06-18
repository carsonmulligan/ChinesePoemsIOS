#!/usr/bin/env python3
"""Fetch classical Chinese texts from zh.wikisource via the MediaWiki API.

Reliable, no nested agents. Cleans wikitext to space-separated classical
phrases (the form the app renders) and writes content_incoming/*.json.
Translations are left "" here — a later pass can fill public-domain Legge text.

Usage: python3 chinese_dictionary_tools/fetch_wikisource.py
"""
import json
import os
import re
import time
import urllib.parse
import urllib.request

UA = "ChinesePoemsApp/1.0 (educational; contact profiles.co@gmail.com)"
API = "https://zh.wikisource.org/w/api.php"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "content_incoming")

CJK = re.compile(r"[㐀-䶿一-鿿豈-﫿]")


def api(params):
    params = {**params, "format": "json"}
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except Exception as e:
            if attempt == 2:
                raise
            time.sleep(2)


def get_wikitext(title, host=None):
    base = API if host is None else f"https://{host}/w/api.php"
    params = {"action": "query", "prop": "revisions", "rvprop": "content",
              "rvslots": "main", "titles": title, "redirects": 1, "format": "json"}
    url = base + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.load(r)
            break
        except Exception:
            if attempt == 2:
                return None
            time.sleep(2)
    page = next(iter(data["query"]["pages"].values()))
    if "missing" in page:
        return None
    return page["revisions"][0]["slots"]["main"]["*"]


def clean_english(wikitext):
    """Clean en.wikisource wikitext to readable prose (keep latin + punctuation)."""
    if not wikitext:
        return ""
    s = wikitext
    s = re.sub(r"<ref[^>]*?/>", " ", s)
    s = re.sub(r"<ref[^>]*?>.*?</ref>", " ", s, flags=re.DOTALL)
    s = re.sub(r"<!--.*?-->", " ", s, flags=re.DOTALL)
    s = strip_templates(s)
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\[\[(?:[^\]|]*\|)?([^\]]+)\]\]", r"\1", s)
    s = re.sub(r"\[https?://[^\s\]]+\s*([^\]]*)\]", r"\1", s)
    s = re.sub(r"^[=*#:;].*$", " ", s, flags=re.MULTILINE)
    s = s.replace("'''", " ").replace("''", " ")
    s = re.sub(r"\s+", " ", s).strip()
    return s


ROMAN = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
         "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]


def search_title(query):
    r = api({"action": "query", "list": "search", "srsearch": query, "srlimit": 1})
    hits = r["query"]["search"]
    return hits[0]["title"] if hits else None


def resolve(title):
    """Return (resolved_title, wikitext) trying the title then a search fallback."""
    wt = get_wikitext(title)
    if wt is not None:
        return title, wt
    alt = search_title(title)
    if alt and alt != title:
        wt = get_wikitext(alt)
        if wt is not None:
            return alt, wt
    return title, None


def strip_templates(s):
    prev = None
    while prev != s:
        prev = s
        s = re.sub(r"\{\{[^{}]*\}\}", " ", s)
    return s


def clean(wikitext):
    s = wikitext
    s = re.sub(r"<ref[^>]*?/>", " ", s)
    s = re.sub(r"<ref[^>]*?>.*?</ref>", " ", s, flags=re.DOTALL)
    s = re.sub(r"<!--.*?-->", " ", s, flags=re.DOTALL)
    s = strip_templates(s)
    s = re.sub(r"<[^>]+>", " ", s)                       # html tags
    s = re.sub(r"\[\[(?:[^\]|]*\|)?([^\]]+)\]\]", r"\1", s)  # wiki links -> display
    s = re.sub(r"\[https?://[^\s\]]+\s*([^\]]*)\]", r"\1", s)  # ext links
    s = re.sub(r"^[=*#:;].*$", " ", s, flags=re.MULTILINE)  # headings/lists
    s = s.replace("'''", " ").replace("''", " ")
    # Keep only CJK; everything else becomes a separator.
    out = []
    for ch in s:
        out.append(ch if CJK.match(ch) else " ")
    s = "".join(out)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def fetch_work(out_name, entries):
    """entries: list of dicts with key/title_chinese/title/author_chinese/author/
       tier_suggestion/source and a 'page' (wikisource title)."""
    result = {}
    short = []
    for e in entries:
        title_used, wt = resolve(e["page"])
        if wt is None:
            print(f"  MISSING: {e['page']}")
            continue
        content = clean(wt)
        if len(content) < 12:
            short.append((e["page"], len(content)))
        translation = ""
        if e.get("english_page"):
            en_wt = get_wikitext(e["english_page"], host="en.wikisource.org")
            translation = clean_english(en_wt)
        result[e["key"]] = {
            "title_chinese": e["title_chinese"],
            "title": e["title"],
            "author_chinese": e["author_chinese"],
            "author": e["author"],
            "content": content,
            "translation_english": translation,
            "source": e["source"],
            "tier_suggestion": e["tier_suggestion"],
        }
        en_mark = f" en={len(translation)}" if e.get("english_page") else ""
        print(f"  ok {e['key']:16} {e['title_chinese']:10} chars={len(content):5}{en_mark} <- {title_used}")
        time.sleep(0.3)
    path = os.path.join(OUT, out_name)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(f"wrote {len(result)} -> {out_name}" + (f"  (short: {short})" if short else ""))
    return result


# ---- Analects (20 books) ----
ANALECTS_BOOKS = [
    ("學而第一", "學而"), ("為政第二", "為政"), ("八佾第三", "八佾"), ("里仁第四", "里仁"),
    ("公冶長第五", "公冶長"), ("雍也第六", "雍也"), ("述而第七", "述而"), ("泰伯第八", "泰伯"),
    ("子罕第九", "子罕"), ("鄉黨第十", "鄉黨"), ("先進第十一", "先進"), ("顏淵第十二", "顏淵"),
    ("子路第十三", "子路"), ("憲問第十四", "憲問"), ("衛靈公第十五", "衛靈公"), ("季氏第十六", "季氏"),
    ("陽貨第十七", "陽貨"), ("微子第十八", "微子"), ("子張第十九", "子張"), ("堯曰第二十", "堯曰"),
]
analects = []
for i, (page, short) in enumerate(ANALECTS_BOOKS, 1):
    analects.append({
        "key": f"lunyu_{i}", "page": f"論語/{page}",
        "title_chinese": f"論語 {short}", "title": f"Analects, Book {i} ({short})",
        "author_chinese": "孔子及弟子", "author": "Confucius and disciples",
        "source": "Analects", "tier_suggestion": "Foundations" if i <= 4 else "Intermediate",
        "english_page": f"The Analects/Book {ROMAN[i]}.",
    })

# ---- Mencius (14 parts) ----
MENCIUS_PARTS = ["梁惠王上", "梁惠王下", "公孫丑上", "公孫丑下", "滕文公上", "滕文公下",
                 "離婁上", "離婁下", "萬章上", "萬章下", "告子上", "告子下", "盡心上", "盡心下"]
mencius = []
for i, part in enumerate(MENCIUS_PARTS, 1):
    mencius.append({
        "key": f"mengzi_{i}", "page": f"孟子/{part}",
        "title_chinese": f"孟子 {part}", "title": f"Mencius: {part}",
        "author_chinese": "孟子", "author": "Mencius",
        "source": "Mencius", "tier_suggestion": "Intermediate",
        "english_page": f"The Chinese Classics/Volume 2/The Works of Mencius/chapter{i:02d}",
    })

# ---- Classical prose ----
PROSE = [
    ("prose_shishuo", "師說", "師說", "On the Teacher", "韓愈", "Han Yu", "Advanced"),
    ("prose_yuandao", "原道", "原道", "On the Original Way", "韓愈", "Han Yu", "Advanced"),
    ("prose_taohua", "桃花源記", "桃花源記", "Peach Blossom Spring", "陶淵明", "Tao Yuanming", "Intermediate"),
    ("prose_loushi", "陋室銘", "陋室銘", "Inscription on a Humble Dwelling", "劉禹錫", "Liu Yuxi", "Intermediate"),
    ("prose_ailian", "愛蓮說", "愛蓮說", "On the Love of the Lotus", "周敦頤", "Zhou Dunyi", "Intermediate"),
    ("prose_yueyang", "岳陽樓記", "岳陽樓記", "Yueyang Tower", "范仲淹", "Fan Zhongyan", "Advanced"),
    ("prose_lanting", "蘭亭集序", "蘭亭集序", "Orchid Pavilion Preface", "王羲之", "Wang Xizhi", "Advanced"),
    ("prose_chushi", "前出師表", "出師表", "Memorial on Dispatching the Troops", "諸葛亮", "Zhuge Liang", "Advanced"),
    ("prose_chibi", "前赤壁賦", "赤壁賦", "First Red Cliff Rhapsody", "蘇軾", "Su Shi", "Advanced"),
    ("prose_shaonian", "少年中國說", "少年中國說", "Ode to Young China", "梁啟超", "Liang Qichao", "Master"),
    ("prose_zhongyong", "禮記/中庸", "中庸", "The Doctrine of the Mean", "子思", "Zisi", "Intermediate"),
    ("prose_jianai", "墨子/兼愛上", "兼愛上", "Universal Love, Part I", "墨子", "Mozi", "Advanced"),
    ("prose_feigong", "墨子/非攻上", "非攻上", "Against Offensive Warfare, Part I", "墨子", "Mozi", "Advanced"),
]
prose = []
for key, page, tc, t, ac, a, tier in PROSE:
    prose.append({"key": key, "page": page, "title_chinese": tc, "title": t,
                  "author_chinese": ac, "author": a, "source": "Classical Prose",
                  "tier_suggestion": tier})


if __name__ == "__main__":
    print("== Analects ==");      fetch_work("analects.json", analects)
    print("== Mencius ==");       fetch_work("mencius.json", mencius)
    print("== Classical prose =="); fetch_work("classics_prose.json", prose)
