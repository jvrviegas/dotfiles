#!/usr/bin/env python3
"""Inject interview data JSON into the scoresheet template.

Usage: build_scoresheet.py <data.json> <output.html>

The template lives next to this script in ../assets/scoresheet-template.html.
Validates the JSON (schema basics) before injecting, and refuses content that
would break out of the inline <script> block.
"""
import json
import pathlib
import sys


def fail(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: build_scoresheet.py <data.json> <output.html>")

    data_path, out_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    template_path = pathlib.Path(__file__).resolve().parent.parent / "assets" / "scoresheet-template.html"

    raw = data_path.read_text(encoding="utf-8")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        fail(f"invalid JSON in {data_path}: {e}")

    for key in ("title", "barTitle", "storeKey", "sections"):
        if key not in data:
            fail(f"missing required key: {key!r}")
    if not isinstance(data["sections"], list) or not data["sections"]:
        fail("'sections' must be a non-empty list")
    for si, sec in enumerate(data["sections"], 1):
        if "title" not in sec or not sec.get("questions"):
            fail(f"section {si} needs 'title' and a non-empty 'questions' list")
        for qi, q in enumerate(sec["questions"], 1):
            for key in ("topic", "ask"):
                if key not in q:
                    fail(f"question {si}.{qi} missing {key!r}")

    if "</script" in raw.lower():
        fail("data must not contain '</script' — it would break the inline JSON block")

    html = template_path.read_text(encoding="utf-8")
    html = html.replace("__TITLE__", data["title"])
    html = html.replace("__INTERVIEW_DATA__", raw)
    out_path.write_text(html, encoding="utf-8")

    n_q = sum(len(s["questions"]) for s in data["sections"])
    print(f"wrote {out_path} — {len(data['sections'])} sections, {n_q} questions, max score {n_q * 5}")


if __name__ == "__main__":
    main()
