"""Per-line provenance for shipped audio: docs/audio_manifest_{lang}.json.

    { "<line_id>": { "source": "placeholder" | "studio",
                     "sha256": "<hex of the mp3>",
                     "detail": "<engine/voice or talent/session>" } }

The release test refuses to ship unless every line is "studio" and its hash
matches the file, so a placeholder can't sneak back in under a real name.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ["en", "hi", "te"]


def manifest_path(lang, root=None):
    return (root or ROOT) / "docs" / f"audio_manifest_{lang}.json"


def audio_dir(lang, root=None):
    return (root or ROOT) / "assets" / "audio" / lang


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def load(lang, root=None):
    p = manifest_path(lang, root)
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


def save(lang, manifest, root=None):
    manifest_path(lang, root).write_text(
        json.dumps(dict(sorted(manifest.items())), indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )


def record(manifest, line_id, mp3, source, detail, talent=None):
    entry = {"source": source, "sha256": sha256(mp3), "detail": detail}
    if talent:
        entry["talent"] = talent
    manifest[line_id] = entry
