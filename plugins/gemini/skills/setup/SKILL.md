---
name: setup
description: Richtet die Gemini-Anbindung ein und prüft sie – Antigravity CLI (agy) installiert, angemeldet und erreichbar – und trägt auf Wunsch die Arbeitsregeln (wann Claude welchen Gemini-Befehl nutzt) in die CLAUDE.md des Projekts oder global ein. Nutze diesen Skill, wenn ein anderer Gemini-Skill mit Exit-Code 3 oder 4 scheitert oder der Nutzer die Einrichtung prüfen bzw. die CLAUDE.md einrichten möchte.
argument-hint: "[projekt|global|beide|ohne|entfernen]"
allowed-tools: Bash
---

# Gemini einrichten und prüfen

Eingabe: $ARGUMENTS

## 1. Bestandsaufnahme (ein Bash-Aufruf)
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --info; echo "---"; bash "${CLAUDE_PLUGIN_ROOT}/scripts/claude-md.sh" status projekt; bash "${CLAUDE_PLUGIN_ROOT}/scripts/claude-md.sh" status global
```

## 2. Funktionstest (ein Bash-Aufruf, `timeout` 200000)
Nur wenn Schritt 1 agy gefunden hat:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --ping
```

## 3. Arbeitsregeln in die CLAUDE.md eintragen
Die Regeln legen fest, wann Claude selbstständig `/gemini:frage`, `/gemini:recherche`, `/gemini:tiefenrecherche`, `/gemini:design` und `/gemini:zweitmeinung` einsetzt (verifiziert, belegt, vollständig).

**Ziel bestimmen:**
- Eingabe `projekt`, `global` oder `beide` → direkt so ausführen.
- Eingabe `ohne` → Schritt überspringen.
- Eingabe `entfernen` → Baustein aus Projekt **und** global entfernen (`remove projekt`, `remove global`), dann weiter zu Schritt 4.
- **Keine Eingabe** → Schau dir das Ergebnis von Schritt 1 an:
  - Baustein schon vorhanden und Version aktuell → nichts tun, nur erwähnen.
  - Baustein vorhanden, aber ältere Version → ohne Rückfrage am selben Ort aktualisieren.
  - Baustein fehlt → den Nutzer **einmal** fragen, mit diesen Optionen:
    1. **Nur dieses Projekt** – `CLAUDE.md` im aktuellen Ordner (empfohlen, wenn die Regeln nur hier gelten sollen)
    2. **Alle Projekte** – `~/.claude/CLAUDE.md`
    3. **Beides**
    4. **Nicht eintragen**

    Ist der aktuelle Ordner offensichtlich kein Projekt (z. B. das Benutzerverzeichnis), Option 1 nicht anbieten.

**Ausführen** (ein Bash-Aufruf je Ziel):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/claude-md.sh" install projekt
bash "${CLAUDE_PLUGIN_ROOT}/scripts/claude-md.sh" install global
```
Das Skript hängt den Baustein in Markierungen an, ersetzt eine ältere Fassung statt sie zu verdoppeln, lässt eigenen Inhalt unangetastet und legt vorher eine Sicherung `CLAUDE.md.bak-gemini` an. Bearbeite die CLAUDE.md nicht selbst mit Write/Edit – immer über das Skript.

## 4. Ergebnis melden
Kurze Tabelle: agy gefunden · Version · Anmeldung · Ping · CLAUDE.md (Projekt/global: eingetragen/aktualisiert/unverändert). Dann je nach Lage:

- **PING OK** → „Alles bereit.“ Befehle nennen: `/gemini:frage`, `/gemini:recherche`, `/gemini:tiefenrecherche`, `/gemini:design`, `/gemini:zweitmeinung`. Wurde die CLAUDE.md geändert: Hinweis, dass die Regeln ab der **nächsten Sitzung** gelten (Claude Code neu starten).
- **Exit 3 – agy nicht gefunden** →
  - Windows (PowerShell): `irm https://antigravity.google/cli/install.ps1 | iex`
  - macOS/Linux: `curl -fsSL https://antigravity.google/cli/install.sh | bash`
  - Danach Claude Code neu starten. Ist agy installiert, aber nicht im PATH: in den Claude-Code-Einstellungen unter `env` die Variable `AGY_BIN` auf den vollen Pfad setzen (z. B. `C:/Users/<name>/AppData/Local/agy/bin/agy.exe`).
- **Exit 4 – Anmeldung abgelaufen** → in einem **normalen Terminal** (nicht in Claude Code) einmal `agy` starten, mit dem Google-Konto anmelden, beenden, dann `/gemini:setup` erneut.
- **Exit 5 – keine Antwort** → läuft parallel ein agy-Terminal? Schließen und erneut versuchen. Sonst die letzten Zeilen aus `~/.claude/gemini-bridge/letzter-lauf.log` zeigen.
- **Hinweis Windows Defender** in der Meldung → den angezeigten `Add-MpPreference`-Befehl in einer Admin-PowerShell ausführen lassen (der Nutzer muss das selbst tun).

Die CLAUDE.md-Einrichtung (Schritt 3) auch dann anbieten, wenn der Ping fehlschlägt – sie hängt nicht davon ab.

Ändere niemals selbst Einstellungen von agy, PATH oder Defender – nur erklären.
