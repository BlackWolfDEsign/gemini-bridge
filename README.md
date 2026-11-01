# gemini-bridge – Gemini als Recherche- und Design-Partner für Claude Code

Claude Code delegiert offene Fragen, Recherchen, Design-Entwürfe und Zweitmeinungen an **Gemini** – über die **Google Antigravity CLI (`agy`)** und dein **Google-AI-Abo**. Kein API-Key nötig.

Claude plant, bewertet und kennt dein Projekt. Gemini durchsucht das Web. Das Ergebnis landet als Markdown in deinem Projekt unter `docs/gemini/`.

## Befehle

| Befehl | Wofür | Dauer |
|---|---|---|
| `/gemini:frage <frage>` | Kurze Faktenfrage, Antwort direkt im Chat | ~1–3 min |
| `/gemini:recherche [--intensitaet niedrig\|mittel\|hoch] <thema>` | Recherche mit Quellen | 3–9 min |
| `/gemini:tiefenrecherche [--tiefe L\|H] [--ja] <frage>` | Mehrere Blickwinkel, mehrere Runden, Red-Team-Gegenprüfung, Bericht mit Empfehlung fürs Projekt | 15–60 min |
| `/gemini:design [--url <adresse>] [--mit-projekt] <auftrag>` | 2–3 echte Design-Varianten (UI, Architektur, Datenmodell, API) mit Vergleich | ~5–9 min |
| `/gemini:zweitmeinung <plan>` | Gemini prüft einen Plan oder eine Entscheidung kritisch | ~3–6 min |
| `/gemini:setup` | Prüft, ob alles läuft | <2 min |

**Claude nutzt sie auch selbstständig:** Alle Befehle sind Skills. Claude ruft `frage`, `recherche` (niedrig/mittel), `design` und `zweitmeinung` von sich aus auf, wenn es passt. Für `tiefenrecherche` und Recherche mit Intensität `hoch` zeigt Claude vorher immer einen Plan bzw. fragt nach.

## Installation (Windows)

Voraussetzungen: Claude Code mit Git for Windows (Standard), Antigravity CLI installiert und einmal per `agy` mit deinem Google-Konto angemeldet.

1. ZIP entpacken, z. B. nach `C:\Users\<name>\claude-plugins\gemini-bridge`
2. In Claude Code:
   ```
   /plugin marketplace add C:/Users/<name>/claude-plugins/gemini-bridge
   /plugin install gemini@gemini-bridge
   ```
   Pfad mit normalen Schrägstrichen `/` angeben.
3. Claude Code neu starten (oder `/reload-plugins`), dann:
   ```
   /gemini:setup
   ```
   Erwartet: `PING OK`.

Alternativ in dein eigenes GitHub-Repo hochladen und `/plugin marketplace add <dein-name>/gemini-bridge` verwenden.

## Damit Claude von selbst delegiert

Füge den Inhalt von `vorlagen/CLAUDE-gemini.md` in die `CLAUDE.md` deiner Projekte ein (oder in `~/.claude/CLAUDE.md` für alle Projekte). Dort legst du fest, **wann** Claude Gemini fragen soll und wie viel.

## Was das Plugin für dich abfängt

Alle Aufrufe laufen über `plugins/gemini/scripts/agy-run.sh`:

- **Datenschutz:** Gemini läuft in einem leeren Temp-Ordner und sieht dein Projekt **nicht**. Es bekommt nur die Frage. Ausnahme: `/gemini:design --mit-projekt` gibt den Projektordner bewusst zum Lesen frei.
- **Nie parallel:** Mehrere agy-Aufrufe gleichzeitig blockieren sich gegenseitig. Eine Sperre sorgt dafür, dass sie nacheinander laufen.
- **agy-Bug #76** (leere Ausgabe ohne Terminal): Antwort wird per Datei übergeben, notfalls aus dem agy-Transcript gerettet.
- **Hängende Aufrufe:** Eingabe wird immer geschlossen, zusätzliches Zeitlimit als Sicherung.
- **Abgelaufene Anmeldung:** wird erkannt und klar gemeldet (Lösung: `agy` einmal im normalen Terminal starten).
- **Windows Defender** sperrt agy-Dateien: ein automatischer Wiederholungsversuch. Dauerhafte Lösung, in einer Admin-PowerShell:
  ```powershell
  Add-MpPreference -ExclusionPath "$env:USERPROFILE\.gemini\antigravity-cli\conversations"
  ```

Diagnose des letzten Laufs: `~/.claude/gemini-bridge/letzter-lauf.log`

## Anpassen

- **Prompts und Abläufe:** in `plugins/gemini/skills/<befehl>/SKILL.md` – reiner Text, direkt editierbar. Nach Änderungen `/reload-plugins`.
- **Neuen Befehl hinzufügen:** neuen Ordner unter `plugins/gemini/skills/` mit `SKILL.md` anlegen, Runner wie in den vorhandenen Skills aufrufen.
- **agy-Pfad:** falls agy nicht gefunden wird, in den Claude-Code-Einstellungen unter `env` die Variable `AGY_BIN` setzen.
- **Ablage:** `docs/gemini/recherche/.tief/` enthält Rohdaten der Tiefenrecherche. Ggf. in `.gitignore` aufnehmen.

## Tests

```bash
bash tests/test-runner.sh
```
Testet den Runner gegen ein nachgebautes agy (keine echte Verbindung nötig): Normalfall, Isolation, Bug #76, Auth-Timeout, Defender-Retry, Sperre, Fehlerfälle.

## Kosten und Grenzen

Jeder Aufruf zählt gegen das Tageskontingent deines Google-Abos. Eine Tiefenrecherche besteht aus 4–15 Aufrufen. Gemini-Ergebnisse sind Hinweise, keine Wahrheit: Claude kennzeichnet ungeprüfte Aussagen, und das Red-Team prüft die wichtigsten Behauptungen gegen. Prüfe selbst, ob die automatisierte Nutzung deines Abos mit Googles Nutzungsbedingungen vereinbar ist.

## Herkunft

Basiert auf [antigravity-plugin-cc](https://github.com/MarcosNahuel/antigravity-plugin-cc) von Marcos Nahuel Albornoz (MIT). Übernommen wurden vor allem die Erkenntnisse zu agy-Fehlern und das Prinzip „Claude orchestriert, Gemini recherchiert“. Neu: deutsche Oberfläche, Skills statt Befehle (selbstständige Nutzung), ein getesteter Runner statt eines 1.400-Zeilen-Subagenten, Tiefenrecherche ohne Abhängigkeit vom Workflow-Werkzeug, Isolation des Projekts, Sperre gegen Parallelaufrufe, Design- und Zweitmeinungs-Skill.
