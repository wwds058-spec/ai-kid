#!/usr/bin/env python3
"""Generate PLACEHOLDER mp3s for every line in docs/audio_script_{lang}.csv.

    python3 tools/gen_placeholder_audio.py [--lang en|hi|te|all]
                                           [--engine auto|edge|espeak] [--force]

Output: assets/audio/{lang}/{line_id}.mp3   (placeholders only - NOT for release)

Engines
  edge    edge-tts (needs internet; `pip install edge-tts`), voices
          en-IN-NeerjaNeural, hi-IN-SwaraNeural, te-IN-ShrutiNeural
  espeak  espeak-ng -> wav -> ffmpeg mp3 (offline; needs espeak-ng and ffmpeg)
  auto    (default) try edge-tts once; if it is unreachable use espeak for the
          whole run so all lines share one voice.

Re-running skips existing files unless --force is given. A PLACEHOLDER.txt is
written next to the mp3s; delete the placeholders and the note when real
recordings replace them (the release check in test/release_audio_test.dart
fails while PLACEHOLDER.txt exists and RELEASE=1).
"""
import argparse
import asyncio
import csv
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ["en", "hi", "te"]
EDGE_VOICES = {
    "en": "en-IN-NeerjaNeural",
    "hi": "hi-IN-SwaraNeural",
    "te": "te-IN-ShrutiNeural",
}
ESPEAK_VOICES = {"en": "en-us+f3", "hi": "hi+f3", "te": "te+f3"}
ESPEAK_RATE = ["-s", "150", "-p", "65"]


def csv_path(lang):
    return ROOT / "docs" / f"audio_script_{lang}.csv"


def out_dir(lang):
    return ROOT / "assets" / "audio" / lang


def read_lines(lang):
    with csv_path(lang).open(newline="", encoding="utf-8") as f:
        return [(r["line_id"], r[f"text_{lang}"]) for r in csv.DictReader(f)]


def edge_synth(text, dest, lang="en"):
    import edge_tts  # imported lazily so espeak-only machines don't need it

    async def run():
        await asyncio.wait_for(
            edge_tts.Communicate(text, EDGE_VOICES[lang]).save(str(dest)),
            timeout=30,
        )

    asyncio.run(run())
    if not dest.exists() or dest.stat().st_size == 0:
        raise RuntimeError("edge-tts produced no audio")


def espeak_synth(text, dest, lang="en"):
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        subprocess.run(
            ["espeak-ng", "-v", ESPEAK_VOICES[lang], *ESPEAK_RATE, "-w", str(wav), text],
            check=True,
        )
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
             "-codec:a", "libmp3lame", "-qscale:a", "5", str(dest)],
            check=True,
        )


def edge_available():
    try:
        import edge_tts  # noqa: F401
    except ImportError:
        return False
    probe = Path(tempfile.mkdtemp()) / "probe.mp3"
    try:
        edge_synth("Hello", probe)
        return True
    except Exception as e:  # DNS/network/policy failures all land here
        print(f"edge-tts unavailable ({type(e).__name__}); falling back to espeak-ng")
        return False
    finally:
        shutil.rmtree(probe.parent, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lang", choices=[*LANGS, "all"], default="all")
    ap.add_argument("--engine", choices=["auto", "edge", "espeak"], default="auto")
    ap.add_argument("--force", action="store_true", help="overwrite existing mp3s")
    args = ap.parse_args()

    engine = args.engine
    if engine == "auto":
        engine = "edge" if edge_available() else "espeak"
    if engine == "espeak" and not (shutil.which("espeak-ng") and shutil.which("ffmpeg")):
        sys.exit("espeak engine needs espeak-ng and ffmpeg on PATH")

    synth = edge_synth if engine == "edge" else espeak_synth
    for lang in LANGS if args.lang == "all" else [args.lang]:
        generate(lang, engine, synth, args.force)


def generate(lang, engine, synth, force):
    out = out_dir(lang)
    out.mkdir(parents=True, exist_ok=True)
    made = skipped = 0
    for line_id, text in read_lines(lang):
        dest = out / f"{line_id}.mp3"
        if dest.exists() and not force:
            skipped += 1
            continue
        synth(text, dest, lang)
        made += 1
        print(f"  {engine}: {dest.relative_to(ROOT)}")

    voice = (EDGE_VOICES[lang] if engine == "edge"
             else "espeak-ng " + " ".join(["-v", ESPEAK_VOICES[lang], *ESPEAK_RATE]))
    (out / "PLACEHOLDER.txt").write_text(
        "These mp3s are machine-generated PLACEHOLDERS - not for release.\n"
        f"Engine/voice: {voice}\n"
        f"Regenerate: python3 tools/gen_placeholder_audio.py --lang {lang} --force\n"
        "Replace with real recordings, then delete this file.\n"
    )
    print(f"{lang}: {made} generated, {skipped} skipped, engine={engine}")

if __name__ == "__main__":
    main()
