---
name: setup
description: Richtet die Gemini-Anbindung ein und prüft sie – Antigravity CLI (agy) installiert, angemeldet und erreichbar – und trägt auf Wunsch die Arbeitsregeln (wann Claude welchen Gemini-Befehl nutzt) in die CLAUDE.md des Projekts oder global ein. Nutze diesen Skill, wenn ein anderer Gemini-Skill mit Exit-Code 3 oder 4 scheitert oder der Nutzer die Einrichtung prüfen bzw. die CLAUDE.md einrichten möchte.
argument-hint: "[projekt|global|beide|ohne|entfernen]"
allowed-tools: Bash
---

# Gemini einrichten und prüfen

Eingabe: $ARGUMENTS

Führe die folgenden zwei Bash-Aufrufe **beide** aus, auch wenn der erste Fehler meldet. Befehle exakt so übernehmen, nichts weglassen.

## 1. Arbeitsregeln in die CLAUDE.md + Bestandsaufnahme (ein Bash-Aufruf)
Die Regeln legen fest, wann Claude selbstständig `/gemini:frage`, `/gemini:recherche`, `/gemini:tiefenrecherche`, `/gemini:design` und `/gemini:zweitmeinung` einsetzt.
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/claude-md.sh" setup "$ARGUMENTS"; echo "---"; bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --info
```
Das Skript entscheidet selbst: ohne Eingabe wird ein vorhandener Baustein aktualisiert, sonst die `CLAUDE.md` im aktuellen Projektordner angelegt bzw. ergänzt. Eigener Inhalt bleibt unangetastet, vorher wird `CLAUDE.md.bak-gemini` gesichert. Bearbeite die CLAUDE.md nie selbst mit Write/Edit.

## 2. Funktionstest (ein Bash-Aufruf, `timeout` 200000)
Nur wenn Schritt 1 unter `---` agy gefunden hat:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --ping
```

## 3. Ergebnis melden
Kurze Tabelle: agy gefunden · Version · Anmeldung · Ping · **CLAUDE.md** – hier die `OK:`/`HINWEIS:`/`FEHLER:`-Zeile aus Schritt 1 **mit vollständigem Pfad** wiedergeben. Dann je nach Lage:

- **PING OK** → „Alles bereit.“ Befehle nennen: `/gemini:frage`, `/gemini:recherche`, `/gemini:tiefenrecherche`, `/gemini:design`, `/gemini:zweitmeinung`. Wurde die CLAUDE.md geändert: Hinweis, dass die Regeln ab der **nächsten Sitzung** gelten (Claude Code neu starten).
- **Exit 3 – agy nicht gefunden** →
  - Windows (PowerShell): `irm https://antigravity.google/cli/install.ps1 | iex`
  - macOS/Linux: `curl -fsSL https://antigravity.google/cli/install.sh | bash`
  - Danach Claude Code neu starten. Ist agy installiert, aber nicht im PATH: in den Claude-Code-Einstellungen unter `env` die Variable `AGY_BIN` auf den vollen Pfad setzen (z. B. `C:/Users/<name>/AppData/Local/agy/bin/agy.exe`).
- **Exit 4 – Anmeldung abgelaufen** → in einem **normalen Terminal** (nicht in Claude Code) einmal `agy` starten, mit dem Google-Konto anmelden, beenden, dann `/gemini:setup` erneut.
- **Exit 5 – keine Antwort** → läuft parallel ein agy-Terminal? Schließen und erneut versuchen. Sonst die letzten Zeilen aus `~/.claude/gemini-bridge/letzter-lauf.log` zeigen.
- **Hinweis Windows Defender** in der Meldung → den angezeigten `Add-MpPreference`-Befehl in einer Admin-PowerShell ausführen lassen (der Nutzer muss das selbst tun).

Die CLAUDE.md-Einrichtung läuft immer, auch wenn agy fehlt oder der Ping fehlschlägt.

Ändere niemals selbst Einstellungen von agy, PATH oder Defender – nur erklären.
