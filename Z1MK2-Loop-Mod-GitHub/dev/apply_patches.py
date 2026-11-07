#!/usr/bin/env python3
"""Wendet patches/patches.json auf eine KOPIE von Traktors qml-Ordner an (fuer Entwicklung/Tests).

    python dev/apply_patches.py <kopie-von-Resources64/qml> <ausgabe-ordner>

Prueft jede Stelle (muss genau einmal vorkommen) und bricht sonst ab.
"""
import json, pathlib, shutil, sys

def main(src, dst):
    src, dst = pathlib.Path(src), pathlib.Path(dst)
    spec = json.loads((pathlib.Path(__file__).resolve().parents[1] / "patches" / "patches.json").read_text(encoding="utf-8"))
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    for rel, hunks in spec["files"].items():
        p = dst / rel
        raw = p.read_bytes().decode("utf-8")
        crlf = "\r\n" in raw
        t = raw.replace("\r\n", "\n")
        if "// MOD" in t:
            sys.exit(f"{rel}: enthaelt schon den Mod - bitte Originaldateien verwenden")
        for i, h in enumerate(hunks, 1):
            n = t.count(h["find"])
            if n != 1:
                sys.exit(f"{rel}: Stelle {i} {n}-mal gefunden (erwartet 1) - andere Traktor-Version?")
            t = t.replace(h["find"], h["replace"])
        p.write_bytes((t.replace("\n", "\r\n") if crlf else t).encode("utf-8"))
        print(f"{rel}: {len(hunks)} Stellen angepasst")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
