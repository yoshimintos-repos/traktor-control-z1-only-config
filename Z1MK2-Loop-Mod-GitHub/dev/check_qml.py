#!/usr/bin/env python3
"""Laedt das (gepatchte) Z1-MK2-Mapping und die Displays mit Platzhaltern (Stubs) fuer
Traktors interne CSI-Bausteine in einer echten QML-Engine. Findet Fehler, die Traktor
den Controller nicht laden lassen wuerden (z. B. unbekannte Eigenschaften, Syntaxfehler).

    pip install PySide6-Essentials
    python dev/check_qml.py <gepatchter-qml-ordner>

Hinweis: Die Stubs bilden nur die Struktur nach, nicht Traktors Verhalten.
"""
import os, pathlib, sys
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlEngine, QQmlComponent

def main(qml_root):
    qml_root = pathlib.Path(qml_root)
    stubs = pathlib.Path(__file__).resolve().parent / "qml-stubs"
    app = QGuiApplication(sys.argv)
    ok = True
    for rel in ["CSI/Z1MK2/Z1MK2.qml", "Screens/Z1MK2/SideScreen.qml", "Screens/Z1MK2/MainScreen.qml"]:
        eng = QQmlEngine()
        eng.addImportPath(str(stubs))
        comp = QQmlComponent(eng, QUrl.fromLocalFile(str(qml_root / rel)))
        obj = comp.create()
        errs = [e.toString() for e in comp.errors()]
        good = obj is not None and not errs
        ok &= good
        print(("OK     " if good else "FEHLER ") + rel)
        for e in errs:
            print("   ", e)
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
