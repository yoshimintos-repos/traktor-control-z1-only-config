# Entwicklung

Die Änderungen liegen in `patches/patches.json` als Paare „suchen → ersetzen“ pro Datei.

## Werkzeuge (Python 3)

- `apply_patches.py <kopie-von-qml> <ausgabe>`: wendet die Patches auf eine Kopie von `Resources64\qml` an.
- `make_patches.py <original-qml> <geaenderte-qml>`: erzeugt `patches.json` neu und prüft das Ergebnis sofort.
- `check_qml.py <gepatchte-qml>`: lädt Mapping und Displays mit Stubs (`qml-stubs/`) in einer echten QML-Engine (`pip install PySide6-Essentials`). Findet Fehler, die Traktor den Controller nicht laden lassen würden.

## Nach einem Traktor-Update anpassen

1. Neue Originale aus `C:\Program Files\Native Instruments\Traktor Pro 4\Resources64\qml` in einen Arbeitsordner kopieren.
2. `apply_patches.py` zeigt, welche Stellen nicht mehr passen.
3. Die Änderungen in einer Kopie von Hand nachziehen (alles mit `MOD` markiert), dann `make_patches.py` ausführen.
4. `check_qml.py` laufen lassen, dann am Gerät testen.

## Wichtige Erkenntnisse

- In den CSI-Dateien (nur `import CSI 1.0`) gibt es kein `Component.onCompleted`. Damit lädt das ganze Mapping nicht, und der Controller wird nicht erkannt.
- Soft Takeover: Der Ausgang des eingebauten `SoftTakeover`-Moduls kann per `ValuePropertyAdapter` auf eine eigene `MappingPropertyDescriptor` (Float, min 0, max 1) zeigen. Die Loop Size wird daraus abgeleitet und zurückgespiegelt.
- „Override factory map“ im Controller Manager blockiert den QML-Teil einer Taste, solange die Zeile aktiv ist.
