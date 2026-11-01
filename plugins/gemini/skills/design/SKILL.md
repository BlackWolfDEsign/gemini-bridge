---
name: design
description: Lässt Gemini (Google Antigravity CLI, Abo des Nutzers) Design-Entwürfe ausarbeiten – UI/UX-Konzepte, Seiten- und Komponentenstruktur, Systemarchitektur, Datenmodelle, API-Entwürfe – jeweils in 2–3 unterschiedlichen Varianten mit Begründung und aktuellen Vorbildern aus dem Web. Optional prüft Gemini eine bestehende Website per Browser. Nutze diesen Skill, wenn der Nutzer einen Entwurf ausgearbeitet haben möchte oder du vor einer größeren Design-Entscheidung echte Alternativen brauchst. Ergebnis in docs/gemini/design/.
argument-hint: "[--url <adresse>] [--mit-projekt] <was soll entworfen werden>"
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Design-Ausarbeitung mit Gemini

Eingabe: $ARGUMENTS

## 1. Auftrag klären
- `--url <adresse>`: Gemini öffnet die Seite im Browser und bezieht das Ist-Design ein (Desktop und Mobil).
- `--mit-projekt`: Gemini darf den Projektordner **lesen** (wird mit `--projekt "$PWD"` freigegeben). Nur verwenden, wenn der Nutzer es ausdrücklich angegeben hat – nie von dir aus.
- Rest = **Auftrag**. Leer → einmal nachfragen und stoppen.
- Ohne `--mit-projekt`: Sammle selbst (Glob/Grep/Read) die relevanten Rahmenbedingungen – vorhandene Farben/Komponenten/Technik, Zielgruppe, Einschränkungen – und fasse sie als **Rahmen** zusammen. Keine Zugangsdaten, Kundendaten oder Code-Auszüge; Technik und Stil beschreiben statt kopieren.
- Fehlt dir etwas Wesentliches (Zielgruppe, Plattform, Art des Designs) und ist es nicht aus dem Projekt ableitbar: **eine** kurze Rückfrage, dann loslegen.

`DATUM` = heute, `SLUG` aus dem Auftrag (max. 60 Zeichen), Ausgabe `docs/gemini/design/<DATUM>-<SLUG>.md`.

## 2. Gemini aufrufen (ein Bash-Aufruf, `timeout` 600000)

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --out "docs/gemini/design/<DATUM>-<SLUG>.md" --timeout 9m [--projekt "$PWD"] <<'GEMINI_PROMPT'
Du bist erfahrene/r Designer/in und Architekt/in. Arbeite den folgenden Entwurf aus. Antworte auf Deutsch.

AUFTRAG: <AUFTRAG>
RAHMEN: <RAHMEN>
<falls --url:> BESTEHENDE SEITE: <URL> – öffne sie im Browser (Desktop 1440 px und Mobil 375 px) und beziehe Stärken und Schwächen des Ist-Zustands ein.
<falls --mit-projekt:> Du darfst die Dateien im Projektordner lesen, aber NICHTS verändern.

Vorgehen:
1. Recherchiere kurz aktuelle, gute Vorbilder und etablierte Muster zu dieser Art von Design (mit URLs).
2. Entwickle 2–3 klar UNTERSCHIEDLICHE Varianten – nicht drei Abwandlungen derselben Idee.

Je Variante:
- Leitidee in einem Satz
- Aufbau/Struktur (bei UI: Bereiche, Hierarchie, Navigation, wichtigste Zustände; bei Architektur/Daten/API: Komponenten, Schnittstellen, Datenfluss)
- Gestaltung bzw. Technik im Detail (bei UI: Raster, Typografie, Farben als Hex-Werte, Abstände, Komponenten, Interaktionen, Barrierefreiheit; bei Architektur: Technologien, Skalierung, Fehlerfälle)
- Skizze als ASCII-Wireframe oder Mermaid-Diagramm
- Stärken, Schwächen, Aufwand (niedrig/mittel/hoch), passt am besten wenn …

Zum Schluss:
## Vergleich – Tabelle aller Varianten nach den wichtigsten Kriterien
## Empfehlung – welche Variante, warum, und was du aus den anderen übernehmen würdest
## Quellen und Vorbilder – mit URLs
GEMINI_PROMPT
```

## 3. Auswerten und weitergeben
- Datei lesen. Dem Nutzer: Pfad, die Varianten in je einer Zeile, Geminis Empfehlung.
- Ergänze **deine eigene Einschätzung** in 2–4 Sätzen: Wo passt die Empfehlung zum tatsächlichen Projekt, wo nicht (du kennst den Code, Gemini nur den Rahmen)? Widersprich offen, wenn du es anders siehst.
- Biete an, die gewählte Variante umzusetzen oder mit `/gemini:zweitmeinung` gegenprüfen zu lassen.
- Fehler des Runners unverändert weitergeben; bei Exit 3/4 auf `/gemini:setup` verweisen.
