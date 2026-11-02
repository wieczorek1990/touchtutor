#!/usr/bin/env python3

import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET


def swift_string(value):
    escapes = {code: f"\\u{{{code:x}}}" for code in range(32)}
    escapes.update(
        {
            ord('"'): '\\"',
            ord("\\"): "\\\\",
            127: "\\u{7f}",
            0x2028: "\\u{2028}",
            0x2029: "\\u{2029}",
        }
    )
    return '"' + value.translate(escapes) + '"'


def score_item(path):
    root = ET.parse(path).getroot()
    for element in root.iter():
        element.tag = element.tag.rsplit("}", 1)[-1]
    if root.tag not in {"score-partwise", "score-timewise"}:
        raise ValueError("Expected a MusicXML score.")

    title = (
        (root.findtext("./work/work-title") or "").strip()
        or (root.findtext("./movement-title") or "").strip()
        or path.stem
    )
    score_id = re.sub(r"[\W_]+", "_", path.stem.lower()).strip("_") or path.stem
    return (
        "[[scores]]\n"
        f"    id = {swift_string(score_id)},\n"
        f"    title = {swift_string(title)},\n"
        f"    artist = \"\",\n"
        f"    album = \"\"\n"
    )


def main():
    parser = argparse.ArgumentParser(
        description="Print a Swift ScoreItem from a MusicXML file."
    )
    parser.add_argument("file", type=Path)
    args = parser.parse_args()
    try:
        print(score_item(args.file))
    except (OSError, ValueError, ET.ParseError) as error:
        parser.exit(1, f"Error: {error}\n")


if __name__ == "__main__":
    main()
