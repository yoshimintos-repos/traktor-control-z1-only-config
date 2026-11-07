#!/usr/bin/env python3
"""Erzeugt patches/patches.json aus Original- und geaenderten Dateien.

    python dev/make_patches.py <original-qml-ordner> <geaenderter-qml-ordner>

Benachbarte Aenderungen werden zusammengefasst; jede Stelle muss im jeweiligen
Zwischenstand genau einmal vorkommen. Das Ergebnis wird zur Kontrolle sofort
wieder angewendet und mit den geaenderten Dateien verglichen.
"""
import difflib, json, pathlib, sys

FILES = ["CSI/Z1MK2/Z1MK2.qml", "CSI/Z1MK2/Z1MK2Side.qml", "CSI/Z1MK2/Z1MK2FXSelector.qml",
         "Screens/Z1MK2/SideScreen.qml", "Screens/Z1MK2/MainScreen.qml"]

def norm(p):
    return p.read_bytes().decode("utf-8").replace("\r\n", "\n")

def main(orig_dir, mod_dir):
    orig_dir, mod_dir = pathlib.Path(orig_dir), pathlib.Path(mod_dir)
    out = {"format": 1, "target": "Traktor Pro 4 / Resources64/qml", "files": {}}
    for rel in FILES:
        a, b = norm(orig_dir / rel), norm(mod_dir / rel)
        al, bl = a.splitlines(keepends=True), b.splitlines(keepends=True)
        sm = difflib.SequenceMatcher(a=al, b=bl, autojunk=False)
        for n in range(2, 60):
            hunks = [{"find": "".join(al[g[0][1]:g[-1][2]]), "replace": "".join(bl[g[0][3]:g[-1][4]])}
                     for g in sm.get_grouped_opcodes(n)]
            t, ok = a, True
            for h in hunks:
                if t.count(h["find"]) != 1:
                    ok = False
                    break
                t = t.replace(h["find"], h["replace"])
            if ok and t == b:
                break
        else:
            sys.exit(f"Keine eindeutigen Stellen fuer {rel}")
        out["files"][rel] = hunks
        print(f"{rel}: {len(hunks)} Stellen")
    target = pathlib.Path(__file__).resolve().parents[1] / "patches" / "patches.json"
    target.write_text(json.dumps(out, ensure_ascii=True, indent=1), encoding="utf-8")
    print("geschrieben:", target)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
