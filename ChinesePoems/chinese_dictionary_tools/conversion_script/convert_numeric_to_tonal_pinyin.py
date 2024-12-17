import json
import os

# Input and output file paths
input_path = "/Users/carsonmulligan/Desktop/Projects/XCode Projects/ChinesePoems/ChinesePoems/ChinesePoems/chinese_to_pinyin_dictionary.json"
output_path = "/Users/carsonmulligan/Desktop/Projects/XCode Projects/ChinesePoems/ChinesePoems/ChinesePoems/chinese_to_pinyin_dictionary_with_tones.json"

# Tone mappings for vowels
# The dictionary keys are vowels without tone, values are tuples of 
# (1st tone, 2nd tone, 3rd tone, 4th tone)
tone_map = {
    'a': ('ā', 'á', 'ǎ', 'à'),
    'e': ('ē', 'é', 'ě', 'è'),
    'i': ('ī', 'í', 'ǐ', 'ì'),
    'o': ('ō', 'ó', 'ǒ', 'ò'),
    'u': ('ū', 'ú', 'ǔ', 'ù'),
    'v': ('ǖ', 'ǘ', 'ǚ', 'ǜ')  # 'v' represents 'ü'
}

def numeric_to_tone(pinyin_numeric):
    # Determine if last char is a digit tone mark (1-4 or 5)
    tone = 0
    if pinyin_numeric and pinyin_numeric[-1].isdigit():
        tone = int(pinyin_numeric[-1])
        pinyin_base = pinyin_numeric[:-1]
    else:
        # No numeric tone at the end, treat as neutral tone
        pinyin_base = pinyin_numeric

    # Replace ü with v internally
    pinyin_base = pinyin_base.replace("ü", "v")

    # If neutral tone (tone 0 or 5), no accent needed
    if tone == 0 or tone == 5:
        return pinyin_base.replace("v", "ü")

    # According to standard rules:
    # 1) Mark 'a' or 'e' if present.
    # 2) If no 'a'/'e', mark 'o' in 'ou' if present.
    # 3) Otherwise mark the last vowel in the syllable.
    vowels = ['a', 'e', 'i', 'o', 'u', 'v']
    chosen_vowel_index = -1
    chosen_vowel = ''

    # Priority: a or e
    for i, ch in enumerate(pinyin_base):
        if ch in ['a', 'e']:
            chosen_vowel_index = i
            chosen_vowel = ch
            break

    # If still not found, check for 'ou'
    if chosen_vowel_index == -1:
        if 'ou' in pinyin_base:
            i = pinyin_base.index('o')
            chosen_vowel_index = i
            chosen_vowel = 'o'
        else:
            # Mark the last vowel in the syllable
            for i in range(len(pinyin_base)-1, -1, -1):
                if pinyin_base[i] in vowels:
                    chosen_vowel_index = i
                    chosen_vowel = pinyin_base[i]
                    break

    if chosen_vowel_index == -1:
        # No vowel found (unlikely in pinyin), just return original
        return pinyin_base.replace("v", "ü")

    # Map the chosen vowel to its toned equivalent
    toned_char = tone_map[chosen_vowel][tone - 1]

    # Rebuild the pinyin with the toned vowel
    pinyin_toned = pinyin_base[:chosen_vowel_index] + toned_char + pinyin_base[chosen_vowel_index+1:]
    pinyin_toned = pinyin_toned.replace("v", "ü")

    return pinyin_toned

# Load the original JSON
with open(input_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Process each entry, add pinyin_tone_lines
for char, info in data.items():
    pinyin_numeric = info.get("pinyin", "")
    pinyin_tone = numeric_to_tone(pinyin_numeric)
    info["pinyin_tone_lines"] = pinyin_tone

# Save the new data to another file
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
