import json

# Tone mappings for vowels
# The dictionary keys are vowels without tone, values are a tuple of 
# (1st tone, 2nd tone, 3rd tone, 4th tone)
tone_map = {
    'a': ('ā', 'á', 'ǎ', 'à'),
    'e': ('ē', 'é', 'ě', 'è'),
    'i': ('ī', 'í', 'ǐ', 'ì'),
    'o': ('ō', 'ó', 'ǒ', 'ò'),
    'u': ('ū', 'ú', 'ǔ', 'ù'),
    'v': ('ǖ', 'ǘ', 'ǚ', 'ǜ')  # 'v' is often used to represent 'ü' in certain systems
}

def numeric_to_tone(pinyin_numeric):
    # Extract the tone number (if any)
    # Pinyin numeric is usually like "li3" for third tone.
    # We assume the pinyin always ends with a digit 1-4 or possibly 5 (no tone)
    tone = 0
    if pinyin_numeric[-1].isdigit():
        tone = int(pinyin_numeric[-1])
        pinyin_base = pinyin_numeric[:-1]
    else:
        # No tone number provided (neutral tone)
        pinyin_base = pinyin_numeric

    # Replace 'ü' with 'v' internally for easier mapping
    pinyin_base = pinyin_base.replace("ü", "v")

    # If no tone or tone = 5 (neutral), just return the base
    # without numeric. No accent needed for neutral tone.
    if tone == 0 or tone == 5:
        # Just return base with ü replaced back
        return pinyin_base.replace("v", "ü")

    # According to pinyin rules, place tone on:
    # 1) 'a' or 'e' if present
    # 2) If no 'a'/'e', if there's 'ou', place on 'o'
    # 3) Otherwise place on last vowel in the syllable
    vowels = ['a', 'e', 'i', 'o', 'u', 'v']

    # Find which vowel to mark
    # Priority: a or e first
    chosen_vowel_index = -1
    chosen_vowel = ''
    for i, ch in enumerate(pinyin_base):
        if ch in ['a', 'e']:
            chosen_vowel_index = i
            chosen_vowel = ch
            break

    if chosen_vowel_index == -1:
        # no 'a' or 'e'
        # check for 'ou'
        if 'ou' in pinyin_base:
            i = pinyin_base.index('o')
            chosen_vowel_index = i
            chosen_vowel = 'o'
        else:
            # place on the last vowel
            for i in range(len(pinyin_base)-1, -1, -1):
                if pinyin_base[i] in vowels:
                    chosen_vowel_index = i
                    chosen_vowel = pinyin_base[i]
                    break

    # Now apply the tone mark
    # tone - 1 because our tuples are zero-indexed but tone is 1-based
    toned_char = tone_map[chosen_vowel][tone - 1]

    # Replace the chosen vowel with the toned vowel
    pinyin_toned = pinyin_base[:chosen_vowel_index] + toned_char + pinyin_base[chosen_vowel_index+1:]

    # Replace 'v' back to 'ü'
    pinyin_toned = pinyin_toned.replace('v', 'ü')

    return pinyin_toned

# Example usage:
# Load the original JSON
with open('chinese_to_pinyin_dictionary.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Convert all entries
for char, info in data.items():
    pinyin_numeric = info.get("pinyin", "")
    pinyin_tone = numeric_to_tone(pinyin_numeric)
    info["pinyin_tone_lines"] = pinyin_tone

# Save to a new JSON with the extra field
with open('chhinese_to_pinyin_dictionary.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
