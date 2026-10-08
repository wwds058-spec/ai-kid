#!/usr/bin/env python3
"""Build the studio recording script for each language.

    python3 tools/build_recording_script.py

Writes docs/recording/script_{lang}.csv: one row per line with the emotion
(matching Aiko's animation state), acting direction, the English reference
and the text to read. Emotions come from docs/audio_script_en.csv, which
test/audio_emotion_test.dart keeps equal to what the app shows on screen.
"""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ["en", "hi", "te"]

# One direction per animation emotion (see AikoWidget.emotionIndex).
DIRECTION = {
    "normal": "Warm, calm, friendly. Conversational pace.",
    "happy": "Bright smile in the voice. Praise that feels earned, not shouted.",
    "excited": "High energy, wide pitch range, a little faster. Wonder, not screaming.",
    "curious": "Wondering, slightly slower, rising intonation on questions. Never confused-sad.",
    "celebrate": "Biggest energy of the episode. Cheerful, proud of the child.",
    "sad": "Gentle, soft and brief. Comforting, never upsetting.",
}


def read(lang):
    with (ROOT / "docs" / f"audio_script_{lang}.csv").open(newline="", encoding="utf-8") as f:
        return {r["line_id"]: r for r in csv.DictReader(f)}


def main():
    en = read("en")
    out_dir = ROOT / "docs" / "recording"
    out_dir.mkdir(parents=True, exist_ok=True)
    for lang in LANGS:
        rows = read(lang)
        path = out_dir / f"script_{lang}.csv"
        with path.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["line_id", "file", "episode", "step", "emotion",
                        "direction", "english_reference", "text", "notes"])
            for line_id, ref in en.items():
                emotion = ref["emotion"]
                notes = [n for n in (ref["notes"], rows[line_id].get("notes", "")) if n]
                w.writerow([
                    line_id, f"{line_id}.wav", ref["episode"], ref["step"], emotion,
                    DIRECTION[emotion], ref["text_en"], rows[line_id][f"text_{lang}"],
                    " | ".join(dict.fromkeys(notes)),
                ])
        print(f"wrote {path.relative_to(ROOT)} ({len(en)} lines)")


if __name__ == "__main__":
    main()
