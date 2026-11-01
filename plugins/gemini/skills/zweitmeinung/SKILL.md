---
name: zweitmeinung
description: Holt eine kritische Zweitmeinung von Gemini (Google Antigravity CLI, Abo des Nutzers) zu einem Plan, einer Architektur- oder Design-Entscheidung oder einer offenen Abwägung ein. Nutze diesen Skill selbstständig, wenn du vor einer folgenreichen, schwer umkehrbaren Entscheidung stehst und dir nicht sicher bist, oder wenn der Nutzer nach einer zweiten Meinung, Gegenprüfung oder Alternativen fragt.
argument-hint: "<plan, entscheidung oder frage>"
allowed-tools: Bash, Read
---

# Zweitmeinung von Gemini

Eingabe: $ARGUMENTS

## 1. Fall zusammenfassen (du)
Schreibe eine **in sich verständliche** Zusammenfassung von höchstens ~300 Wörtern:
- Ziel und Rahmenbedingungen (Stack, Größenordnung, Einschränkungen)
- die Entscheidung oder der Plan, um den es geht
- die Optionen, die du siehst, und deine aktuelle Tendenz mit Begründung

Kommt der Fall aus der laufenden Unterhaltung, nimm ihn von dort; ist die Eingabe leer und nichts Offenes im Gespräch, einmal nachfragen und stoppen.

**Datenschutz:** abstrahieren statt kopieren – keine Code-Auszüge, Zugangsdaten, Kunden- oder Firmennamen.

## 2. Gemini fragen (ein Bash-Aufruf, `timeout` 480000)

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" --out "docs/gemini/zweitmeinung/$(date +%Y-%m-%d-%H%M).md" --timeout 6m <<'GEMINI_PROMPT'
Ein anderer KI-Assistent hat folgenden Plan bzw. folgende Abwägung erarbeitet. Prüfe ihn kritisch und unabhängig. Antworte auf Deutsch.

<ZUSAMMENFASSUNG>

Deine Aufgabe:
1. Was ist an der Tendenz richtig? (kurz)
2. Wo sind Denkfehler, übersehene Risiken, falsche Annahmen? Sei konkret und direkt, keine Höflichkeitsfloskeln.
3. Welche Option wurde gar nicht erwogen, sollte es aber?
4. Prüfe per Websuche alle Fakten, auf denen die Entscheidung ruht (Versionen, Limits, Preise, bekannte Probleme). Nenne Quellen mit URL.
5. Dein Urteil: zustimmen | mit Änderungen zustimmen | ablehnen – mit einem Satz Begründung.

Format: ## Urteil (zuerst) · ## Was stimmt · ## Probleme und Risiken · ## Übersehene Optionen · ## Faktencheck · ## Quellen
GEMINI_PROMPT
```

## 3. Ergebnis
Datei lesen und dem Nutzer berichten: Geminis Urteil, die 2–3 wichtigsten Einwände, und **deine ehrliche Reaktion** darauf – welche Einwände du übernimmst, welche du für falsch hältst und warum. Ändere deinen Plan nur, wenn die Einwände überzeugen; Gemini ist eine zweite Stimme, keine Instanz.

Fehler des Runners unverändert weitergeben; bei Exit 3/4 auf `/gemini:setup` verweisen.
