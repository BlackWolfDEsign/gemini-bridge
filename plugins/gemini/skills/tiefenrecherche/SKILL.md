---
name: tiefenrecherche
description: Gründliche, mehrstufige Recherche mit Gegenprüfung – Gemini durchsucht das Web aus mehreren Blickwinkeln, Claude bewertet Lücken und Widersprüche, ein Red-Team-Durchgang prüft die Kernaussagen, am Ende ein Bericht mit Quellen und einer konkreten Empfehlung für das Projekt. Nutze diesen Skill, wenn eine Entscheidung im Projekt davon abhängt, es richtig zu wissen (Architektur, Technologie- oder Anbieterwahl, Machbarkeit, rechtliche/technische Rahmenbedingungen). Dauert 15–60 Minuten; Claude zeigt vorher immer einen Plan zur Freigabe, außer der Nutzer gibt --ja an.
argument-hint: "[--tiefe L|H] [--ja] <thema oder offene frage>"
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Tiefenrecherche: Claude orchestriert, Gemini recherchiert

Eingabe: $ARGUMENTS

Rollenverteilung: **Gemini** (über `agy`) liest das Web. **Du (Claude)** planst, bewertest, prüfst gegen und kennst das Projekt. Gemini sieht das Projekt nie.

Runner (alle Gemini-Aufrufe, immer einzeln nacheinander – nie parallel):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --out "<datei>" --timeout <dauer> <<'GEMINI_PROMPT'
<prompt>
GEMINI_PROMPT
```

## Schritt 1 – Parameter
- `--tiefe L` (Standard) oder `H`. `--ja` überspringt die Planfreigabe. Flags entfernen, Rest = **Thema**. Leer → einmal nachfragen und stoppen.
- `DATUM` = heute `YYYY-MM-DD`, `SLUG` = Thema klein, Nicht-Alphanumerisches → `-`, max. 60 Zeichen.
- `ARBEIT` = `docs/gemini/recherche/.tief/<DATUM>-<SLUG>` (Rohdaten), `BERICHT` = `docs/gemini/recherche/<DATUM>-<SLUG>-tief.md`.

| | Tiefe L | Tiefe H |
|---|---|---|
| Blickwinkel Runde 1 | 3–4 | 5–6 |
| Runden insgesamt | max. 2 | max. 4 |
| Red-Team-Aussagen | bis 5 | bis 10 |
| Timeout je Blickwinkel | 5m (Bash 420000 ms) | 6m (Bash 480000 ms) |
| Timeout Red-Team | 7m (Bash 540000 ms) | 9m (Bash 600000 ms) |

## Schritt 2 – Projektkontext (nur du, kein Gemini)
Wenn das Thema das aktuelle Projekt betrifft: verschaffe dir mit Glob/Grep/Read einen knappen Überblick über die relevanten Rahmenbedingungen (Stack, Größenordnung, Einschränkungen, bestehende Entscheidungen, `CLAUDE.md`). Halte 3–6 Stichpunkte als **Projektrahmen** fest. Für Gemini nur **abstrahiert** verwenden – keine Dateiinhalte, Namen, Zugangsdaten oder Kundendaten.

## Schritt 3 – Plan
1. **Kernfrage** in einem Satz.
2. **Prüfmatrix**: 4–10 Teilfragen. Je Teilfrage: was als Beleg zählt, wie aktuell es sein muss, und ob sie **entscheidungsrelevant** ist (könnte die Empfehlung kippen).
3. **Blickwinkel**: je Blickwinkel Titel, Suchauftrag, welche Teilfragen er abdeckt. Jede entscheidungsrelevante Teilfrage muss abgedeckt sein.

## Schritt 4 – Freigabe
Zeige Kernfrage, Prüfmatrix und Blickwinkel als kompakte Tabellen plus geschätzte Dauer (≈ 5–7 min pro Gemini-Aufruf). Warte auf „ok“ oder Änderungen.
- Überspringen nur mit `--ja`.
- **Wurdest du selbstständig ausgelöst, ist die Freigabe immer Pflicht**, auch ohne Flag.

## Schritt 5 – Runde 1: Blickwinkel recherchieren
`mkdir -p "<ARBEIT>"`, dann pro Blickwinkel **einen eigenen** Bash-Aufruf (nacheinander), Ausgabe `<ARBEIT>/r1-w<N>.md`:

```
Du bist EIN Blickwinkel einer größeren Recherche. Geh eng und tief statt breit. Antworte auf Deutsch.

Übergeordnete Frage: <KERNFRAGE>
Rahmen (abstrakt): <PROJEKTRAHMEN ABSTRAHIERT oder "allgemein">
Dein Blickwinkel: <SUCHAUFTRAG>

Regeln:
- Liefere 4–8 überprüfbare Aussagen zur übergeordneten Frage.
- Je Aussage: die Aussage selbst · ein wörtliches Zitat (max. 2 Sätze) von der Seite, die du tatsächlich geöffnet hast · URL · Quellenart (primär|sekundär|Blog|Forum) · Datum der Quelle (YYYY-MM-DD oder "unbekannt").
- Kein Zitat gefunden → Aussage weglassen oder als [UNBESTÄTIGT] markieren. Niemals Zahlen, Versionen, IDs aus dem Gedächtnis zitieren.
- Primärquellen bevorzugen, SEO-Seiten ignorieren. Quellen älter als 12 Monate bei schnelllebigen Themen kennzeichnen.
- Zum Schluss "## Weiterverfolgen": vielversprechende offene Fäden, je markiert als entscheidend | Widerspruchsgefahr | Aktualitätsrisiko | nebensächlich. Keine erfundenen Fäden.
```

Schlägt ein Aufruf fehl (Exit ≠ 0): Fehlermeldung notieren, Blickwinkel als *fehlgeschlagen* markieren, mit dem nächsten weitermachen. Bei Exit 3 oder 4 (agy fehlt/Anmeldung abgelaufen) **sofort abbrechen** und auf `/gemini:setup` verweisen.

## Schritt 6 – Bewerten und weitere Runden
Lies alle Ergebnisse der Runde. Erstelle für dich eine **Erkenntnisliste**: Aussage · Quellen · Stärke (stark = ≥2 unabhängige Primärquellen, mittel, schwach) · betroffene Teilfragen.

Weitere Runde nur, wenn mindestens eins zutrifft **und** das Rundenlimit nicht erreicht ist:
- eine entscheidungsrelevante Teilfrage ist unbeantwortet oder nur schwach belegt,
- Quellen widersprechen sich bei einem entscheidungsrelevanten Punkt,
- ein Faden ist als *entscheidend* markiert.

Dann 1–3 gezielte neue Blickwinkel (gleiche Vorlage, Datei `<ARBEIT>/r<RUNDE>-w<N>.md`). Sonst weiter zu Schritt 7. Gib dem Nutzer zwischen den Runden eine Zeile Zwischenstand.

## Schritt 7 – Red-Team
Wähle die 5 (L) bzw. 10 (H) wichtigsten Aussagen – zuerst die, auf denen die Empfehlung ruht, und alle, die nur eine Quelle haben. **Ein** Aufruf, Ausgabe `<ARBEIT>/redteam.md`:

```
Du bist ein skeptischer Prüfer. Versuche, jede der folgenden Aussagen zu WIDERLEGEN. Antworte auf Deutsch.

Kernfrage: <KERNFRAGE>

Aussagen:
1. "<AUSSAGE>" – Quelle(n): <URL(s)>
2. ...

Prüfe je Aussage:
1. Gibt es glaubwürdige Gegenbelege (Websuche)?
2. Öffne die angegebene URL: Existiert die Seite? Steht die genannte Zahl/Angabe wirklich dort? Passt eine zitierte ID/Version zum Inhalt?
3. Reicht die Quellenqualität für die Stärke der Aussage?
4. Ist sie veraltet, Marketing, Einzelmeinung oder ein herausgepickter Benchmark?

Je Aussage eine Zeile in einer Tabelle: Nr · Urteil (halten | abschwächen | verwerfen) · Begründung · Gegenquelle (URL oder "–").
Im Zweifel abschwächen oder verwerfen.
```
Fehlschlag → Red-Team im Bericht als *nicht durchgeführt* vermerken, Aussagen bleiben ungeprüft markiert (nicht automatisch „halten“).

## Schritt 8 – Bericht schreiben (du, mit Write)
Verwerfe widerlegte Aussagen, schwäche abgeschwächte ab. Schreibe `<BERICHT>`:

```markdown
---
thema: <THEMA>
datum: <DATUM>
tiefe: <L|H>
runden: <n>
gemini_aufrufe: <n> (davon fehlgeschlagen: <n>)
---
# <Thema>

## Kurzfazit
3–5 Sätze: Antwort auf die Kernfrage + Empfehlung + Sicherheitsgrad (hoch/mittel/niedrig).

## Empfehlung für das Projekt
Konkret, angewandt auf den Projektrahmen aus Schritt 2 (hier darfst du Projektdetails nennen – der Bericht bleibt lokal). Nächste Schritte.

## Erkenntnisse
Je Erkenntnis: Aussage mit Kennzeichnung [Beleg] / [Schlussfolgerung] / [Annahme], Quellenverweise [1], [2], Red-Team-Status (gehalten / abgeschwächt / ungeprüft).

## Widersprüche und Unsicherheiten
## Was die Empfehlung kippen würde
## Beweislücken
## Abdeckung
Tabelle: Teilfrage · beantwortet ja/teilweise/nein · Belegstärke.
## Quellen
Nummeriert: Titel – URL – Datum der Quelle.
```

Regeln: Nur Quellen aufnehmen, die in den Gemini-Ergebnissen vorkommen – keine aus deinem Gedächtnis ergänzen. Erscheint dieselbe URL/ID unter verschiedenen Titeln, unter „Beweislücken“ als **Zitat prüfen** markieren.

## Schritt 9 – Rückmeldung
Pfad zum Bericht + Kurzfazit + Empfehlung (wörtlich aus dem Bericht). Hinweis, dass die Rohdaten in `<ARBEIT>` liegen.
