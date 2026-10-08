"""Tests for the studio-recording ingest pipeline (needs ffmpeg/ffprobe).

    python3 -m unittest discover tools/tests
"""
import csv
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import audio_manifest  # noqa: E402
import ingest_recordings  # noqa: E402


def tone(path, seconds, lead_silence=0.0):
    src = f"sine=frequency=440:duration={seconds}"
    af = f"adelay={int(lead_silence * 1000)}" if lead_silence else "anull"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi", "-i", src,
                    "-af", af, str(path)], check=True)


@unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg not installed")
class IngestTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        (self.tmp / "docs").mkdir()
        with (self.tmp / "docs" / "audio_script_hi.csv").open("w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["line_id", "text_hi", "notes"])
            w.writerow(["pf_ep01_s1_intro", "x", ""])
            w.writerow(["pf_ep01_s2_explain", "y", ""])
        self.src = self.tmp / "delivery"
        self.src.mkdir()

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_valid_delivery_is_normalised_and_recorded_as_studio(self):
        tone(self.src / "pf_ep01_s1_intro.wav", 2.0, lead_silence=0.8)
        errors, missing = ingest_recordings.ingest(
            "hi", self.src, "Studio A", self.tmp, talent="Actor A")
        self.assertEqual(errors, [])
        self.assertEqual(missing, ["pf_ep01_s2_explain"])
        mp3 = self.tmp / "assets" / "audio" / "hi" / "pf_ep01_s1_intro.mp3"
        self.assertTrue(mp3.exists())
        # leading silence trimmed: ~2.0s tone, not 2.8s
        self.assertLess(ingest_recordings.duration(mp3), 2.5)
        entry = audio_manifest.load("hi", self.tmp)["pf_ep01_s1_intro"]
        self.assertEqual(entry["source"], "studio")
        self.assertEqual(entry["sha256"], audio_manifest.sha256(mp3))
        self.assertEqual(entry["detail"], "Studio A")
        self.assertEqual(entry["talent"], "Actor A")

    def test_unknown_id_rejects_whole_delivery(self):
        tone(self.src / "pf_ep01_s1_intro.wav", 1.0)
        tone(self.src / "pf_ep01_s1_intr0.wav", 1.0)  # typo
        errors, _ = ingest_recordings.ingest("hi", self.src, "T", self.tmp)
        self.assertTrue(any("unknown line id" in e for e in errors))
        self.assertFalse((self.tmp / "assets").exists(), "nothing may be written")

    def test_too_short_and_too_long_are_rejected(self):
        tone(self.src / "pf_ep01_s1_intro.wav", 0.1)
        tone(self.src / "pf_ep01_s2_explain.wav", 31)
        errors, _ = ingest_recordings.ingest("hi", self.src, "T", self.tmp)
        self.assertEqual(len(errors), 2)

    def test_unreadable_file_is_rejected(self):
        (self.src / "pf_ep01_s1_intro.wav").write_bytes(b"not audio")
        errors, _ = ingest_recordings.ingest("hi", self.src, "T", self.tmp)
        self.assertTrue(any("unreadable" in e for e in errors))


class PlaceholderGeneratorTest(unittest.TestCase):
    """The placeholder generator must never overwrite a studio recording."""

    def test_force_regeneration_keeps_studio_lines(self):
        import gen_placeholder_audio as gen

        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        (tmp / "docs").mkdir()
        with (tmp / "docs" / "audio_script_hi.csv").open("w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["line_id", "text_hi", "notes"])
            w.writerow(["studio_line", "a", ""])
            w.writerow(["placeholder_line", "b", ""])
        out = tmp / "assets" / "audio" / "hi"
        out.mkdir(parents=True)
        studio = out / "studio_line.mp3"
        studio.write_bytes(b"REAL RECORDING")
        manifest = {}
        audio_manifest.record(manifest, "studio_line", studio, "studio", "Talent")
        audio_manifest.save("hi", manifest, tmp)

        synthesised = []

        def fake_synth(text, dest, lang):
            synthesised.append(dest.name)
            Path(dest).write_bytes(b"ROBOT")

        old_root = gen.ROOT
        gen.ROOT = tmp
        try:
            gen.generate("hi", "espeak", fake_synth, force=True)
        finally:
            gen.ROOT = old_root

        self.assertEqual(studio.read_bytes(), b"REAL RECORDING")
        self.assertEqual(synthesised, ["placeholder_line.mp3"])
        m = audio_manifest.load("hi", tmp)
        self.assertEqual(m["studio_line"]["source"], "studio")
        self.assertEqual(m["placeholder_line"]["source"], "placeholder")


if __name__ == "__main__":
    unittest.main()
