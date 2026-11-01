from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "bin" / "score_metadata.py"


class ScoreMetadataTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.score = Path(directory.name) / "Example Score.xml"

    def run_script(self, xml):
        self.score.write_text(xml, encoding="utf-8")
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(self.score)],
            capture_output=True,
            text=True,
        )

    def test_title_and_swift_output(self):
        result = self.run_script("""
        <score-partwise xmlns="https://example.test/musicxml">
        <work><work-title>Nocturne &amp; Étude</work-title></work>
        </score-partwise>
        """)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            """ScoreItem(
    id: "example_score",
    name: L10n.string("Nocturne & Étude"),
    filename: "Example Score.xml",
    defaultTitle: L10n.string("Nocturne & Étude")
)
""",
        )

    def test_title_fallbacks(self):
        for xml, title in [
            (
                "<score-partwise><movement-title>Movement</movement-title></score-partwise>",
                "Movement",
            ),
            (
                "<score-partwise><work><work-title> </work-title></work></score-partwise>",
                "Example Score",
            ),
        ]:
            result = self.run_script(xml)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f'defaultTitle: L10n.string("{title}")', result.stdout)

    def test_swift_escaping(self):
        result = self.run_script(
            "<score-partwise><work><work-title>&quot;Étude&quot; \\(literal)</work-title></work></score-partwise>"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(r'L10n.string("\"Étude\" \\(literal)")', result.stdout)

    def test_invalid_input(self):
        for xml in ["<broken>", "<not-a-score/>"]:
            result = self.run_script(xml)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Error:", result.stderr)
            self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
