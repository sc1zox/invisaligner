# Invisaligner

Private Android-App zum Stempeln von Schienenpausen, gebaut mit Flutter.

## Bedienung

1. Aktuelle Schienennummer und ersten Tragetag einrichten. Ab diesem Tag gilt
   die Schiene außerhalb eingetragener Pausen als eingesetzt.
2. Beim Herausnehmen **Schiene raus** (**Pause starten**) antippen.
3. Beim Einsetzen **Schiene rein** (**Pause beenden**) antippen.
4. Vergessene Pausen im **Verlauf** nachtragen, korrigieren oder löschen.
   **Noch draußen** lässt eine Pause offen; **Ganzer Tag ohne Schiene** trägt
   für einen vergangenen Tag eine Pause von Mitternacht bis Mitternacht ein.
   Bestehende Pausen dürfen sich dabei nicht überschneiden.

Die große Stempelaktion steht direkt oben auf **Heute** und speichert mit
einem Tippen. Eine kurze Vibrationsrückmeldung bestätigt das Speichern.
Beim Wechsel zu **Heute** springt die Ansicht an den Anfang. Darunter zeigen
Fortschrittsring und Schienenkarte die Tragezeit und den geplanten Wechsel.

Es läuft kein Timer und kein Hintergrunddienst. Gespeichert werden nur die
Zeitstempel. Die Anzeige wird beim Stempeln, beim Zurückkehren in die App,
bei Navigation sowie durch Aktualisieren oder Herunterziehen neu berechnet.
Eine offene Pause bleibt auch nach einem App-Neustart erhalten.

## Berechnung

- Abgeschlossene Tage: Tageslänge minus Pausen, normalerweise 24 Stunden minus
  Zeit ohne Schiene. Zeitumstellungstage haben entsprechend 23 oder 25 Stunden.
- Heute: Seit Mitternacht vergangene Zeit minus bisherige Pausen.
  Zukünftige Stunden werden nicht vorab als getragen gezählt.
- Pausen über Mitternacht werden auf die betroffenen Tage verteilt.
- Ohne eingetragene Pause zählt die gesamte verfügbare Tageszeit als getragen.
  Nicht gestempelte Pausen müssen deshalb nachgetragen werden.
- Das Tagesziel beträgt 20 Stunden. Der Wechsel ist nach 14 Tragetagen ab dem
  ersten Tragetag geplant. Unterschreitungen des Tagesziels werden für die
  aktuelle Schiene aufsummiert; sobald ein Defizit besteht, schlägt die App
  einen zusätzlichen Tag bis zum Wechsel vor. Mehr als 20 Stunden an einem
  anderen Tag gleichen ein Defizit nicht aus.
- **Tag anrechnen** überschreibt die Anrechnung für den Wechseltermin,
  nicht die Zeitwerte. Nachträge berechnen den Termin der aktuellen Schiene neu.
- Ein bestätigter Schienenwechsel beginnt standardmäßig am heutigen
  Kalendertag. Wurde der Wechsel vergessen, lässt sich im Wechseldialog der
  tatsächliche Tag wählen. Eine offene Pause bleibt bis zum Einsetzstempel
  bestehen.
- **Wechsel korrigieren** auf der Schienenkarte ändert Nummer und Starttag der
  aktuellen Schiene, etwa wenn der Wechsel zu spät eingetragen wurde. Der
  Starttag muss nach dem Start der vorherigen Schiene liegen.

## Code

- `lib/app`: App-Start, deutsche Lokalisierung und Routing.
- `lib/core/theme`: gemeinsame Farben und Theme.
- `lib/features/home/tracker_models.dart`: Zeitintervalle und Tagesgrenzen.
- `lib/features/home/tracker.dart`: SQLite, Validierung und Tagesberechnung.
- `lib/features/home/presentation`: Ansichten und eigenständige Eingabedialoge.

Die SQLite-Datenbank verwendet ein frisches Pausenschema ohne Migration vom
früheren Entwicklungsstand. Es gibt keinen Server und keine Synchronisierung.
Beim Löschen der App-Daten gehen die Einträge verloren; ein Export/Import ist
noch nicht implementiert. Release-Builds verwenden derzeit den Debug-Schlüssel.

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter run
flutter build apk --debug
```
