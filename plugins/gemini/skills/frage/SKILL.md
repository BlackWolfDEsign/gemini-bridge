---
name: frage
description: Schnelle Einzelfrage an Gemini (Google Antigravity CLI, Abo des Nutzers), Antwort direkt zurück. Nutze diesen Skill selbstständig für kurze Faktenfragen mit Web-Bezug, wenn du unsicher bist oder dein Wissen veraltet sein könnte (aktuelle Version, ob eine Funktion existiert, kurze Definition aus aktueller Quelle). Für Themen, die mehrere Quellen brauchen, stattdessen den Skill recherche verwenden.
argument-hint: "<frage>"
allowed-tools: Bash, Read
---

# Kurze Frage an Gemini

Frage: $ARGUMENTS

Ist keine Frage erkennbar: einmal nachfragen „Was soll ich Gemini fragen?“ und stoppen.

**Datenschutz:** Nur die Frage senden, keine Dateien, keine Zugangsdaten, keine Kunden- oder Firmeninterna. Projektkontext nur abstrakt beschreiben.

Ein Bash-Aufruf, `timeout` 300000:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --out "$HOME/.claude/gemini-bridge/antworten/$(date +%Y%m%d-%H%M%S).md" --timeout 3m --zeigen <<'GEMINI_PROMPT'
Beantworte die folgende Frage knapp und präzise auf Deutsch. Prüfe aktuelle Fakten per Websuche und nenne am Ende 1–3 Quellen mit URL. Wenn du dir nicht sicher bist, sag das ausdrücklich.

FRAGE: <FRAGE>
GEMINI_PROMPT
```

Danach:
- Die Antwort steht nach der Zeile `-----` in der Ausgabe. Gib sie dem Nutzer wörtlich wieder (bei eigenständiger Nutzung: kurz erwähnen, dass die Info von Gemini stammt).
- Fehlermeldungen des Runners unverändert weitergeben; bei Exit 3/4 auf `/gemini:setup` verweisen. Kein zweiter Versuch ohne Rückfrage.
