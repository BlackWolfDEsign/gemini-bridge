---
name: setup
description: Prüft, ob die Gemini-Anbindung funktioniert – Antigravity CLI (agy) installiert, angemeldet und erreichbar – und erklärt, wie Fehler zu beheben sind. Nutze diesen Skill, wenn ein anderer Gemini-Skill mit Exit-Code 3 oder 4 scheitert oder der Nutzer die Einrichtung prüfen möchte.
argument-hint: ""
allowed-tools: Bash
---

# Gemini-Anbindung prüfen

## 1. Bestandsaufnahme (ein Bash-Aufruf)
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --info
```

## 2. Funktionstest (ein Bash-Aufruf, `timeout` 200000)
Nur wenn Schritt 1 agy gefunden hat:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --ping
```

## 3. Ergebnis melden
Kurze Tabelle: agy gefunden · Version · Anmeldung · Ping. Dann je nach Lage:

- **PING OK** → „Alles bereit.“ Nenne die Befehle: `/gemini:frage`, `/gemini:recherche`, `/gemini:tiefenrecherche`, `/gemini:design`, `/gemini:zweitmeinung`.
- **Exit 3 – agy nicht gefunden** →
  - Windows (PowerShell): `irm https://antigravity.google/cli/install.ps1 | iex`
  - macOS/Linux: `curl -fsSL https://antigravity.google/cli/install.sh | bash`
  - Danach Claude Code neu starten. Ist agy installiert, aber nicht im PATH: in den Claude-Code-Einstellungen unter `env` die Variable `AGY_BIN` auf den vollen Pfad setzen (z. B. `C:/Users/<name>/AppData/Local/agy/bin/agy.exe`).
- **Exit 4 – Anmeldung abgelaufen** → in einem **normalen Terminal** (nicht in Claude Code) einmal `agy` starten, mit dem Google-Konto anmelden, beenden, dann `/gemini:setup` erneut.
- **Exit 5 – keine Antwort** → läuft parallel ein agy-Terminal? Schließen und erneut versuchen. Sonst die letzten Zeilen aus `~/.claude/gemini-bridge/letzter-lauf.log` zeigen.
- **Hinweis Windows Defender** in der Meldung → den angezeigten `Add-MpPreference`-Befehl in einer Admin-PowerShell ausführen lassen (der Nutzer muss das selbst tun).

Ändere niemals selbst Einstellungen von agy, PATH oder Defender – nur erklären.
