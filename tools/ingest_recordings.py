#!/usr/bin/env python3
"""Ingest studio recordings into the app.

    python3 tools/ingest_recordings.py --lang hi --src ~/delivery/hi \\
        --detail "Talent: <name>, session 2026-11-02"

For every file in --src named {line_id}.{wav,flac,mp3,m4a,aiff}:
  1. rejects unknown line ids, unreadable files and wrong durations
  2. trims leading/trailing silence, converts to mono 44.1 kHz,
     loudness-normalises to -16 LUFS (true peak -1.5 dB), encodes mp3 96 kbps
  3. writes assets/audio/{lang}/{line_id}.mp3
  4. records it as "studio" (with sha256) in docs/audio_manifest_{lang}.json

Nothing is written if any file is rejected (fix the delivery and re-run).
Prints which lines still have no studio recording.
"""
import argparse
import csv
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_manifest  # noqa: E402

EXTS = {".wav", ".flac", ".mp3", ".m4a", ".aiff", ".aif"}
MIN_SECONDS = 0.4
MAX_SECONDS = 30.0
FILTER = (
    "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,"
    "areverse,"
    "loudnorm=I=-16:TP=-1.5:LRA=11"
)


def line_ids(root, lang):
    path = root / "docs" / f"audio_script_{lang}.csv"
    with path.open(newline="", encoding="utf-8") as f:
        return [r["line_id"] for r in csv.DictReader(f)]


def duration(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "json", str(path)],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        return None
    try:
        return float(json.loads(out.stdout)["format"]["duration"])
    except (KeyError, ValueError):
        return None


def convert(src, dest):
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-af", FILTER,
         "-ac", "1", "-ar", "44100", "-codec:a", "libmp3lame", "-b:a", "96k",
         str(dest)],
        check=True,
    )


def ingest(lang, src, detail, root=None):
    root = root or audio_manifest.ROOT
    known = set(line_ids(root, lang))
    files = sorted(p for p in Path(src).iterdir() if p.suffix.lower() in EXTS)
    errors, accepted = [], []
    for p in files:
        if p.stem not in known:
            errors.append(f"{p.name}: unknown line id")
            continue
        d = duration(p)
        if d is None:
            errors.append(f"{p.name}: unreadable audio")
        elif not MIN_SECONDS <= d <= MAX_SECONDS:
            errors.append(f"{p.name}: {d:.2f}s outside {MIN_SECONDS}-{MAX_SECONDS}s")
        else:
            accepted.append(p)
    if errors:
        return errors, []

    manifest = audio_manifest.load(lang, root)
    out_dir = audio_manifest.audio_dir(lang, root)
    out_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        staged = []
        for p in accepted:
            mp3 = Path(tmp) / f"{p.stem}.mp3"
            convert(p, mp3)
            d = duration(mp3)
            if d is None or d < MIN_SECONDS:
                return [f"{p.name}: silent or too short after trimming"], []
            staged.append((p.stem, mp3))
        for line_id, mp3 in staged:
            dest = out_dir / f"{line_id}.mp3"
            shutil.copyfile(mp3, dest)
            audio_manifest.record(manifest, line_id, dest, "studio", detail)
    audio_manifest.save(lang, manifest, root)
    missing = sorted(i for i in known if manifest.get(i, {}).get("source") != "studio")
    return [], missing


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lang", required=True, choices=audio_manifest.LANGS)
    ap.add_argument("--src", required=True, type=Path)
    ap.add_argument("--detail", required=True,
                    help="talent / session / studio, kept in the manifest")
    args = ap.parse_args()
    if not (shutil.which("ffmpeg") and shutil.which("ffprobe")):
        sys.exit("needs ffmpeg and ffprobe on PATH")
    errors, missing = ingest(args.lang, args.src, args.detail)
    if errors:
        print("Rejected, nothing written:\n  " + "\n  ".join(errors))
        sys.exit(1)
    print(f"{args.lang}: ingested. Lines still without a studio recording: "
          f"{len(missing)}" + (("\n  " + "\n  ".join(missing)) if missing else ""))


if __name__ == "__main__":
    main()
