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
| `/gemini:setup [projekt\|global\|beide]` | Prüft, ob alles läuft, und trägt die Arbeitsregeln in die CLAUDE.md ein | <2 min |
| `/gemini:app [--modus deep-research\|chat] <frage>` | Bedient die **Gemini-App** in deinem Chrome (Claude in Chrome): Deep Research oder Chat starten, Bericht selbst exportieren und ablegen | 15–60 min |

**Claude nutzt sie auch selbstständig:** Alle Befehle sind Skills. Claude ruft `frage`, `recherche` (niedrig/mittel), `design` und `zweitmeinung` von sich aus auf, wenn es passt. Für `tiefenrecherche` und Recherche mit Intensität `hoch` zeigt Claude vorher immer einen Plan bzw. fragt nach. `/gemini:app` läuft nur auf deinen ausdrücklichen Wunsch.

## Installation (Windows)

### Voraussetzungen

| Was | Prüfen / Installieren |
|---|---|
| **Claude Code** | `claude --version` in PowerShell |
| **Git for Windows** (bringt Git Bash mit, das Claude Code und dieses Plugin nutzen) | `git --version` – sonst von https://git-scm.com/download/win installieren |
| **Google-AI-Abo** (Pro oder Ultra) | in deinem Google-Konto |
| **Antigravity CLI (`agy`)** | siehe Schritt 1 |

### Schritt 1 – Antigravity CLI installieren und anmelden

In **PowerShell** (nicht in Claude Code):

```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

Danach PowerShell **schließen und neu öffnen**, damit `agy` im PATH ist, und einmal starten:

```powershell
agy
```

Mit dem Google-Konto anmelden, das dein Abo hat. Wenn `agy` läuft, wieder beenden. Diese Anmeldung nutzt das Plugin im Hintergrund.

### Schritt 2 – Plugin in Claude Code installieren

Claude Code starten und **nacheinander** eingeben:

```
/plugin marketplace add BlackWolfDEsign/gemini-bridge
/plugin install gemini@gemini-bridge
```

Wichtig: beim Installieren genau `gemini@gemini-bridge` schreiben – `gemini` ist der Name des Plugins, `gemini-bridge` der Name des Marketplace.

### Schritt 3 – Neu starten und testen

Claude Code beenden und neu starten (oder `/reload-plugins`), dann:

```
/gemini:setup
```

Erwartet: `PING OK`. Anschließend fragt Setup, ob die Arbeitsregeln in die `CLAUDE.md` eingetragen werden sollen (siehe „Damit Claude von selbst delegiert“). Danach stehen alle `/gemini:…`-Befehle zur Verfügung.

### Schritt 4 (empfohlen) – Windows Defender ausnehmen

Defender sperrt gelegentlich Dateien, die `agy` gerade schreibt, wodurch Antworten abbrechen. Das Plugin versucht es dann automatisch erneut. Dauerhaft vermeiden lässt es sich in einer **PowerShell als Administrator**:

```powershell
Add-MpPreference -ExclusionPath "$env:USERPROFILE\.gemini\antigravity-cli\conversations"
```

### Aktualisieren

Wenn im Repo etwas geändert wurde:

```
/plugin marketplace update gemini-bridge
```

Danach Claude Code neu starten.

### Deinstallieren

```
/plugin uninstall gemini@gemini-bridge
/plugin marketplace remove gemini-bridge
```

### Probleme bei der Installation

| Meldung / Problem | Lösung |
|---|---|
| **Plugin „gemini“ konnte nicht gefunden werden** | Der Marketplace fehlt oder ist veraltet (z. B. weil das Repo beim ersten Versuch noch privat war). Neu hinzufügen: `/plugin marketplace remove gemini-bridge`, dann `/plugin marketplace add BlackWolfDEsign/gemini-bridge`, dann `/plugin install gemini@gemini-bridge`. Außerdem prüfen, dass du `gemini@gemini-bridge` und nicht nur `gemini` eingegeben hast. |
| `marketplace add` schlägt fehl | Repo-Name genau so schreiben: `BlackWolfDEsign/gemini-bridge`. Prüfen, ob `git --version` funktioniert und GitHub erreichbar ist. |
| `/gemini:setup` meldet **agy nicht gefunden** | PowerShell und Claude Code neu starten. Hilft das nicht, Pfad fest eintragen: in `%USERPROFILE%\.claude\settings.json` unter `"env"` den Eintrag `"AGY_BIN": "C:/Users/<name>/AppData/Local/agy/bin/agy.exe"` ergänzen (normale Schrägstriche). |
| `/gemini:setup` meldet **Anmeldung abgelaufen** | In einer normalen PowerShell einmal `agy` starten, anmelden, beenden. Dann erneut `/gemini:setup`. |
| **Keine Antwort** / Zeitüberschreitung | Läuft gleichzeitig ein `agy` in einem anderen Fenster? Schließen. Details im Diagnose-Log `%USERPROFILE%\.claude\gemini-bridge\letzter-lauf.log`. |
| Befehle `/gemini:…` erscheinen nicht | `/plugin` öffnen und prüfen, ob `gemini@gemini-bridge` aktiviert ist. Claude Code neu starten. |

### Alternative: Installation ohne GitHub (lokaler Ordner)

Repo als ZIP herunterladen (grüner Button **Code → Download ZIP**), z. B. nach `C:\Users\<name>\claude-plugins\gemini-bridge` entpacken – der Ordner muss direkt `.claude-plugin`, `plugins` und `README.md` enthalten. Dann:

```
/plugin marketplace add C:/Users/<name>/claude-plugins/gemini-bridge
/plugin install gemini@gemini-bridge
```

Pfad mit normalen Schrägstrichen `/` angeben.

## Installation (macOS / Linux)

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy   # einmal anmelden, dann beenden
```

Danach wie unter Windows ab Schritt 2.

## Damit Claude von selbst delegiert

`/gemini:setup` fragt nach dem Verbindungstest, ob die **Arbeitsregeln** in die `CLAUDE.md` eingetragen werden sollen – für **dieses Projekt**, für **alle Projekte** (`~/.claude/CLAUDE.md`) oder beides. Die Regeln legen fest, wann Claude welchen Gemini-Befehl selbstständig einsetzt: Code-Verifizierung, Informations-Validierung, Abgleich mit der Realität, vollständige Logik, wissenschaftliche Kennzeichnung ([Beleg] / [Schlussfolgerung] / [Annahme]).

Direkt ohne Rückfrage:

```
/gemini:setup projekt     nur dieses Projekt
/gemini:setup global      alle Projekte
/gemini:setup beide
/gemini:setup entfernen   Regeln wieder herausnehmen
```

Der Baustein steht in Markierungen (`<!-- gemini-bridge:start … -->` … `<!-- gemini-bridge:end -->`). Eigener Inhalt der CLAUDE.md bleibt unangetastet, ein erneutes Setup aktualisiert den Baustein statt ihn zu verdoppeln, und vor jeder Änderung entsteht eine Sicherung `CLAUDE.md.bak-gemini`. Die Regeln gelten ab der nächsten Sitzung. Anpassen: `plugins/gemini/vorlagen/CLAUDE-gemini.md` bearbeiten, dann erneut `/gemini:setup`.

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

## Gemini-App statt CLI (`/gemini:app`)

Für Deep Research in der Gemini-App (gemini.google.com) braucht es kein agy, sondern die Erweiterung **Claude in Chrome**, verbunden mit Claude Code, und eine Anmeldung bei Gemini in diesem Chrome. Claude stellt das stärkste Modell mit Denkaufwand „Hoch“ ein (nie Flash), schaltet Deep Research ein oder aus, tippt den Prompt, klickt „Recherche starten“, wartet und exportiert den fertigen Bericht über Geminis eigenen Export („Teilen und exportieren → Inhalte kopieren“, bei Chats „Kopieren“). Die Zwischenablage liest `scripts/app-zwischenablage.sh` (Windows über PowerShell, macOS über `osascript`/`pbpaste`, Linux über `wl-paste` oder `xclip`), `scripts/app-html2md.py` wandelt das HTML in Markdown um (nur Python-Standardbibliothek). Das Ergebnis liegt mit Herkunftskopf (Modell, Chat, Zeitstempel, „ungeprüft“) unter `docs/gemini/app/`, die Rohdaten unter `docs/gemini/app/.roh/` (nicht committen). Hängt ein Lauf über die Frist von 65 Minuten, sichert Claude die Quellenliste und stoppt ihn; Chats werden nie gelöscht.

Aus dem Praxistest (November 2026): Viele Deep-Research-Läufe bleiben bei „Rechercheplan wird erstellt“ oder „Bericht wird erstellt“ hängen; ein neuer Versuch in einem neuen Chat hilft öfter als das Teilen der Frage. Ein normaler Chat geht verloren, wenn der Tab vor der fertigen Antwort neu geladen wird oder einen anderen Chat öffnet. Der Export überschreibt die Zwischenablage.

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
