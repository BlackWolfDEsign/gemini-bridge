---
name: recherche
description: Web-Recherche mit Quellen über Gemini (Google Antigravity CLI, Abo des Nutzers). Nutze diesen Skill selbstständig, sobald eine offene Frage aktuelles oder externes Wissen braucht, das nicht im Projekt steht – z. B. Stand einer Bibliothek/API, Vergleich von Tools/Anbietern, Best Practices, Normen, Preise, Marktlage. Nicht für Fragen, die sich aus dem Code oder den Projektdateien beantworten lassen. Ergebnis landet als Markdown in docs/gemini/recherche/.
argument-hint: "[--intensitaet niedrig|mittel|hoch] <thema>"
allowed-tools: Bash, Read, Write
---

# Recherche über Gemini

Eingabe: $ARGUMENTS

## 1. Parameter bestimmen
- `--intensitaet niedrig|mittel|hoch` aus der Eingabe lesen, Standard `mittel`. Flag entfernen, der Rest ist das **Thema**.
- Wurdest du **selbstständig** (nicht vom Nutzer) ausgelöst: nur `niedrig` oder `mittel` verwenden. Für `hoch` vorher kurz fragen.
- Ist kein Thema erkennbar: einmal nachfragen „Was soll Gemini recherchieren?“ und stoppen.

| Intensität | Timeout | Bash-Timeout (ms) | Quellen |
|---|---|---|---|
| niedrig | 3m | 300000 | 3–5 |
| mittel  | 6m | 480000 | 8–12 |
| hoch    | 9m | 600000 | 15+ |

## 2. Datenschutz – vor dem Absenden prüfen
Gemini bekommt **nur die Frage**, keine Dateien. Formuliere das Thema so, dass es ohne Projektinterna verständlich ist. Niemals Zugangsdaten, Schlüssel, Kundendaten, interne Namen oder Code-Auszüge in den Prompt schreiben. Wenn Projektkontext nötig ist, abstrahiere ihn („ein Node-Backend mit ~50k Nutzern“ statt Firmenname/Code).

## 3. Gemini aufrufen (EIN Bash-Aufruf)
`DATUM` = heute `YYYY-MM-DD`, `SLUG` = Thema klein, Nicht-Alphanumerisches → `-`, max. 60 Zeichen.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --out "docs/gemini/recherche/<DATUM>-<SLUG>.md" --timeout <TIMEOUT> <<'GEMINI_PROMPT'
Recherchiere im Web gründlich zum folgenden Thema und antworte auf Deutsch.

THEMA: <THEMA>

Regeln:
- Nutze <QUELLENZAHL> vertrauenswürdige Quellen: offizielle Dokumentation, Primärquellen, Fachartikel, seriöse Fachpresse. Keine SEO-Seiten oder Content-Farmen.
- Jede wichtige Aussage braucht eine Quelle mit klickbarer URL.
- Erfinde keine Quellen. Nenne Versionen, Daten, Preise oder Benchmarks nur, wenn eine Quelle sie direkt belegt, mit Datum der Quelle. Unbestätigtes als [UNBESTÄTIGT] markieren.
- Benenne Widersprüche zwischen Quellen ausdrücklich.
- Ist eine Quelle älter als 12 Monate und das Thema schnelllebig, weise darauf hin.

Format (Markdown):
<FORMAT>
GEMINI_PROMPT
```

`<FORMAT>` je Intensität:
- **niedrig:** `## Kurzfazit` (3–5 Stichpunkte) · `## Quellen`
- **mittel:** `## Kurzfazit` · `## Wichtigste Erkenntnisse` · `## Einordnung` · `## Offene Punkte` · `## Quellen` (nummeriert, mit Datum)
- **hoch:** `## Kurzfazit` · `## Kontext` · `## Erkenntnisse` (je Erkenntnis eigener Unterabschnitt mit Belegen) · `## Vergleich` (Tabelle, falls sinnvoll) · `## Risiken und Gegenargumente` · `## Beweislücken` · `## Fazit mit Sicherheitsgrad` · `## Quellen`

Setze den `timeout` des Bash-Aufrufs gemäß Tabelle.

## 4. Ergebnis verwenden
- Ausgabe `OK: <pfad>` → Datei mit Read lesen.
- **An den Nutzer:** Pfad + Kurzfazit (wörtlich aus der Datei, nicht umformulieren). Falls du selbstständig recherchiert hast, sag in einem Satz, dass du Gemini gefragt hast und warum.
- **Für deine eigene Arbeit:** Gemini-Ergebnisse sind Hinweise, keine Wahrheit. Wenn eine Aussage für eine Entscheidung im Projekt kritisch ist, prüfe die Quelle (z. B. Doku-Link öffnen) oder kennzeichne sie als ungeprüft.

## 5. Fehler
Der Runner gibt eine klare deutsche Meldung aus. Gib sie unverändert weiter und schlage passend vor:
- Exit 3 (agy fehlt) oder 4 (Anmeldung abgelaufen) → `/gemini:setup` bzw. `agy` einmal im normalen Terminal starten.
- Exit 5 (keine Antwort) → einmal mit kleinerer Intensität oder engerer Frage erneut versuchen, nicht öfter.
- Niemals die Festplatte nach Dateien durchsuchen oder Hintergrundprozesse zur Diagnose starten.
