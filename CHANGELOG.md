# Changelog

## Version 7
- Behoben: Die Loop-Taste setzte nach dem ersten Loop immer einen 4-Beat-Loop, auch wenn eine andere Loop Size eingestellt war (z. B. Loop gesetzt, im Loop auf 8 vergrößert, beendet, neu gesetzt → wieder 4). Ursache: Traktor übernimmt den Wert eines `SetPropertyAdapter` offenbar nur einmal beim Laden und ignoriert spätere Änderungen des Bindings (NI verwendet dort ausschließlich feste Werte). Jetzt gibt es pro Loop-Größe einen Adapter mit festem Wert, von dem nur der zur aktuellen Loop Size passende aktiv ist.
- `Layout pruefen.bat`: Einträge ohne zugewiesenes Gerät (Port „None“) gelten jetzt als inaktiv und werden nicht mehr als Problem gemeldet.

## Version 6.1
- Neu: `Layout pruefen.bat` findet doppelte oder veraltete Z1-MK2-Layouts im Controller Manager (damals für die Ursache von „Loop immer 4“ gehalten, siehe Version 7). Der Installer zeigt das Ergebnis am Ende ebenfalls an.

## Version 6
- Shift-Taste (Filter) leuchtet immer weiß: gedimmt = bereit, hell = gedrückt.
- Only-Browser-Taste leuchtet mit Shift weiß.
- Soft-Takeover-Pfeil überlappt nicht mehr den Namen (z. B. bei „LOOP 1/32“). Er steht dann über dem Wert.
- Installation über `patches/patches.json`, es werden keine NI-Dateien mehr mitgeliefert.

## Version 5
- Mit Shift leuchten alle Tasten mit Shift-Belegung in passenden Farben, Tasten ohne Shift-Belegung sind aus.
- Stem-Mode: Shift + Gain-Knopf = Loop Size (mit Soft Takeover).

## Version 4
- Loop-Taste im Mod (Shift + EQ links / Stems rechts), deterministisch, kann nicht mehr hängen bleiben.
- Filter-Taste ist auch für den Mod die Shift-Taste.
- Seiten-Displays im Ruhezustand: Restzeit, BPM und Loop Size.

## Version 3
- „LOOP“ wird beim Drehen hinterlegt, wenn ein Loop gesetzt ist.
- Mittleres Display: Listen-Symbole im Only-Browser-Modus.

## Version 2
- Gain-Knopf im EQ-Mode = Loop Size mit echtem Soft Takeover (Traktors eingebautes Soft-Takeover-Modul).

## Version 1
- Erster Versuch. Lud wegen `Component.onCompleted` nicht (in Traktors CSI-Dateien nicht verfügbar).
