---
name: app
description: Bedient die Gemini-App (gemini.google.com) im Chrome des Nutzers über Claude in Chrome – Deep Research oder ein Chat mit dem stärksten Modell und Denkaufwand „Hoch“, Prompt eingeben, Recherche starten, Ergebnis selbst exportieren und als Markdown mit Herkunftskopf ablegen, Quellenliste sichern, hängende Läufe nach der Frist sichern und stoppen. Nur auf ausdrücklichen Wunsch des Nutzers, nie selbstständig – die App zählt gegen sein Kontingent und braucht seinen Browser. Ergebnis in docs/gemini/app/.
argument-hint: "[--modus deep-research|chat] [--datei <prompt.txt>] [--sichern <chat-url>] [--stoppen <chat-url>] <frage>"
allowed-tools: Bash, Read, Write, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__tabs_close_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__find, mcp__claude-in-chrome__javascript_tool, mcp__claude-in-chrome__browser_batch
---

# Gemini-App über Claude in Chrome

Eingabe: $ARGUMENTS

Dieser Skill ersetzt das Kopieren und Anstoßen von Hand: Claude stellt den Modus ein, sendet, klickt „Recherche starten“, exportiert den fertigen Bericht selbst über Geminis eigenen Export und legt ihn ab. Geprüft am 10.11.2026 an der deutschen Oberfläche der App; heißen Schaltflächen anders, die Bezeichnungen per `find` suchen statt raten.

## 1. Voraussetzungen und Parameter
- **Claude in Chrome** muss verbunden sein. Die Werkzeuge in **einem** Aufruf laden: `ToolSearch` mit `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__tabs_close_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__find,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__browser_batch`. Meldet ein Aufruf „not connected“: das sagen und stoppen.
- Der Nutzer ist in Chrome bei Gemini angemeldet. Landet die Seite auf einer Anmeldung: stoppen, nie Zugangsdaten eingeben.
- `--modus deep-research` (Standard) oder `--modus chat` (ein Chat ohne Deep Research, etwa für ein Red-Team). `--datei <pfad>` liest den Prompt aus einer Datei, sonst ist der Rest der Eingabe der Prompt. `--sichern <url>` exportiert nur einen fertigen Chat (Abschnitt 8), `--stoppen <url>` sichert und stoppt einen hängenden Lauf (Abschnitt 9).
- `DATUM` = heute `YYYY-MM-DD`, `SLUG` = Thema klein, Nicht-Alphanumerisches → `-`, höchstens 60 Zeichen. Arbeitsordner `R=docs/gemini/app/.roh/<DATUM>-<SLUG>` (nicht committen), Ergebnis `docs/gemini/app/<DATUM>-<SLUG>.md`. Jeder Schritt mit echter Uhrzeit (`date '+%F %T'`) in `$R/lauf.md` notieren.

## 2. Datenschutz – vor dem Absenden prüfen
Gemini bekommt **nur die Frage**. Keine Dateien hochladen, keine Zugangsdaten, Schlüssel, Kundendaten, internen Namen oder Code-Auszüge. Projektkontext abstrahieren.

## 3. Prompt vorbereiten
- **Eine Zeile.** Ein Zeilenumbruch beim Tippen sendet sofort ab. Umbrüche durch Leerzeichen ersetzen: `tr '\n' ' ' < prompt.txt | sed 's/  */ /g' > "$R/prompt.txt"`.
- Länge zählen (`LC_ALL=C.UTF-8 wc -m < "$R/prompt.txt"`), höchstens etwa 4000 Zeichen. Bei Deep Research am Ende verlangen: Antwort auf Deutsch, je Aussage Quelle mit URL, Abschnitt „## Nicht gefunden“ vor „## Weiterverfolgen“.

## 4. Kontingent prüfen
Neuen Tab öffnen (`tabs_create_mcp`), `https://gemini.google.com/usage` laden, 5 s warten, dann:
```js
document.body.innerText.split('\n').filter(l=>/genutzt|zurückgesetzt/.test(l))
```
Der erste Prozentwert ist das laufende Fenster (wenige Stunden), der letzte die Woche. Ein fertiger Deep-Research-Bericht kostete im Test rund ein Drittel bis die Hälfte des Fensters. Bei weniger als 40 % frei vor dem Start fragen; ist das Fenster voll, droht der Wechsel auf ein schwächeres Modell – dann nicht starten. Höchstens zwei Läufe gleichzeitig.

## 5. Modus einstellen und senden
1. Im eigenen Tab `https://gemini.google.com/app` laden, 9 s warten. `find` nach „Modusauswahl-Button, Prompt-Textbox, Uploads & Tools“. Fehlt der Modus-Button: in die Textbox klicken, 7 s warten, erneut suchen.
2. **Modell und Denkaufwand:** Modus-Button klicken → `find` „Menüeintrag Denkaufwand“ → klicken → `find` „Menüeintrag Hoch Besonders gründlich“ → klicken → `Escape`. Prüfen:
   ```js
   [...document.querySelectorAll('button[aria-label]')].map(b=>b.getAttribute('aria-label')).filter(l=>/Deep Research|Modusauswahl/.test(l))
   ```
   Die Modus-Zeile muss das stärkste Modell mit „Hoch“ zeigen (am 10.11.2026 „Argon Hoch“). Steht dort ein Flash- oder Flash-Lite-Modell: stoppen und fragen, nie damit senden.
3. **Deep Research:** Bei `deep-research` muss „Auswahl von „Deep Research“ aufheben“ in der Liste stehen. Sonst „Uploads & Tools“ klicken und:
   ```js
   const e=[...document.querySelectorAll('[role=menuitemcheckbox]')].find(x=>/Deep Research/.test(x.innerText)); if(e){e.click();} ({found:!!e})
   ```
   Liefert das `found:false`, liegt der Eintrag unter „Weitere Tools“: `find` „Menüeintrag Weitere Tools“, `scroll_to`, klicken, dann das Snippet noch einmal. Bei `chat` darf die Zeile nicht erscheinen; steht sie da, den Button „Auswahl von „Deep Research“ aufheben“ klicken.
4. In die Textbox klicken, den Prompt mit `type` eintippen, dann die Länge prüfen und mit der Datei vergleichen:
   ```js
   document.querySelector('[role=textbox], .ql-editor').innerText.length
   ```
   Erst bei gleicher Länge und richtigem Modus `Return` drücken und sofort die Uhrzeit notieren.
5. Nach 10 s prüfen, ob die Adresse auf `/app/<kennung>` wechselt; die Kennung notieren. Bleibt das Feld leer und es entsteht kein Chat, ging der Versand verloren: einmal neu tippen und senden.

## 6. Deep Research anstoßen und warten
- Nach etwa 60 s steht der Rechercheplan. Gibt es einen aktiven Button „Recherche starten“ (`find`), ihn klicken; in Hintergrund-Tabs und nach Neuladen startet die Recherche oft nicht von selbst. Danach muss „Antwort stoppen“ aktiv sein.
- **Status** (bei Deep Research darf die Seite neu geladen werden, der Stand liegt beim Server):
  ```js
  ({stop:!!document.querySelector('button[aria-label="Antwort stoppen"]'), fertig:/Teilen und exportieren/.test(document.body.innerText), bericht:/Bericht wird erstellt/.test(document.body.innerText), links:document.querySelectorAll('a[href^="http"]').length, modus:[...document.querySelectorAll('button[aria-label]')].map(b=>b.getAttribute('aria-label')).filter(l=>/Modusauswahl/.test(l))})
  ```
  `fertig:true` und `stop:false` heißt: Bericht da. Nach dem Neuladen zeigt die Modus-Zeile nur den Modellnamen ohne Stufe; das ist kein Fehler.
- Ein Bericht dauert 15–60 Minuten, manche Läufe hängen bei „Rechercheplan wird erstellt“ oder „Bericht wird erstellt“. **Frist: 65 Minuten ab Start der Recherche.** Nicht im Sekundentakt prüfen: Stand melden, den Turn beenden und beim nächsten Wort des Nutzers (oder in einem `/loop` alle 10 Minuten) nachsehen. Nach der Frist: Abschnitt 9.

## 7. Chat-Modus warten
- **Nie neu laden und nie im selben Tab einen anderen Chat öffnen, bevor die Antwort fertig ist** – im Test ging die Antwort dabei zweimal ganz verloren, ohne Eintrag in der Chatliste. Den Nutzer bitten, den Tab nicht anzufassen.
- In Abständen von etwa 2 Minuten prüfen (`browser_batch` mit Wartezeiten von 10 s), höchstens 15 Minuten:
  ```js
  ({stop:!!document.querySelector('button[aria-label="Antwort stoppen"]'), len:(document.querySelector('model-response')||{innerText:''}).innerText.length})
  ```
  `stop:false` und eine lange Antwort heißt: fertig.

## 8. Ergebnis selbst exportieren
Der Export braucht die Zwischenablage des Rechners; sag dem Nutzer, dass sie überschrieben wird.
1. Prüfwert setzen: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/app-zwischenablage.sh" --setzen LEER`
2. **Deep Research:** `find` „Button Teilen und exportieren“ → klicken → `find` „Menüeintrag Inhalte kopieren“ (der Eintrag heißt `Kopieren` im Menü „Inhalte kopieren“) → klicken. **Chat:** `find` „Button Kopieren unter der Antwort“ (nicht „Prompt kopieren“) → `scroll_to` → klicken.
3. 2 s warten, dann lesen und umwandeln (`py -3 -I` unter Windows, sonst `python3 -I`):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/app-zwischenablage.sh" --html "$R/bericht.html" && py -3 -I "${CLAUDE_PLUGIN_ROOT}/scripts/app-html2md.py" "$R/bericht.html" "$R/bericht.md"
   ```
   Exit 5 heißt: der Klick hat nichts kopiert. Den Chrome-Tab nach vorn holen lassen und Schritt 1–3 einmal wiederholen.
4. **Quellenliste** sichern (bei Deep Research immer, auch bei hängenden Läufen):
   ```js
   const seen=new Map(); for (const a of document.querySelectorAll('a[href^="http"]')) { if (/^https?:\/\/([a-z0-9-]+\.)*(google\.[a-z.]+|gstatic\.com)\//.test(a.href)) continue; const t=(a.innerText||'').replace(/\s+/g,' ').replace(/ Wird in einem neuen Fenster geöffnet$/,'').trim(); const o=seen.get(a.href); if(o===undefined||t.length>o.length) seen.set(a.href,t); } window.__json=JSON.stringify([...seen].map(([url,title])=>({url,title}))); window.__ok=null; const b=document.createElement('button'); b.textContent='COPY'; b.style.cssText='position:fixed;left:0;top:0;width:300px;height:200px;z-index:2147483647'; b.onclick=()=>{const ta=document.createElement('textarea'); ta.value=window.__json; document.body.appendChild(ta); ta.select(); window.__ok=document.execCommand('copy'); ta.remove(); b.remove();}; document.body.appendChild(b); ({n:seen.size})
   ```
   Dann auf (100, 80) klicken, `window.__ok` muss `true` sein, und `app-zwischenablage.sh --text "$R/quellen.json"`.
5. **Prüfen:** Zeilen, Bytes, Überschriften (`grep -n '^#'`), Zahl der URLs, keine Ersatzzeichen (`grep -c $'\xef\xbf\xbd'`), vollständiges Ende. Fehlt „## Nicht gefunden“ oder bricht der Text ab, das sagen.
6. **Ablegen** als `docs/gemini/app/<DATUM>-<SLUG>.md` mit Kopf, darunter `$R/bericht.md` unverändert:
   ```markdown
   ---
   quelle: Gemini-App (gemini.google.com), <Deep Research|Chat>
   modell: <Modus-Zeile vor dem Senden, z. B. Argon Hoch>
   chat: <kennung>
   gesendet: <Zeitstempel>
   gesichert: <Zeitstempel>
   status: ungeprüft
   ---
   ```
   War der Lauf vom Nutzer gestartet, „gesendet: unbekannt (vom Nutzer gestartet)“ und „modell: nicht geprüft“ schreiben.

## 9. Hängender Lauf nach der Frist
1. Quellenliste sichern (8.4) als `$R/quellen-<n>.json`.
2. Stoppen: `find` „Button Antwort stoppen“ → klicken → 2 s warten →
   ```js
   const b=[...document.querySelectorAll('button')].find(x=>/^\s*Ja, abbrechen\s*$/.test(x.innerText)); if(b){b.click();} ({found:!!b})
   ```
   Danach muss `stop:false` sein; sonst ist der Stopp nicht angekommen.
3. **Chats nie löschen.** Notieren, dann dem Nutzer melden. Ein neuer Versuch mit derselben Frage in einem neuen Chat ist sinnvoll; Teilen der Frage hat im Test das Hängen nicht verhindert.

## 10. Ergebnis verwenden
- **An den Nutzer:** Pfad, Umfang, Stand (fertig, hängt, gestoppt), Kontingent. Kurzfazit nur wörtlich aus dem Bericht.
- Gemini-Ergebnisse sind Hinweise, keine Wahrheit; keine URL ist durch diesen Skill geöffnet. Was eine Entscheidung trägt, prüfen oder als ungeprüft kennzeichnen.
- Tabs, die du geöffnet hast, am Ende schließen.

## 11. Fehler
- Erweiterung nicht verbunden, Seite nicht erlaubt, Anmeldung verlangt: sagen und stoppen, keinen Umweg nehmen.
- Ein Button fehlt: einmal neu suchen (`find`), dann einen Screenshot ansehen; nach zwei bis drei Fehlversuchen anhalten und fragen.
- CAPTCHA oder Prüfseite: nie lösen, den Nutzer bitten.
