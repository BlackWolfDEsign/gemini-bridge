#!/usr/bin/env bash
# =============================================================================
# app-zwischenablage.sh – liest die Zwischenablage für den Skill /gemini:app
#
# Nutzung:
#   app-zwischenablage.sh --html <ziel.html>   HTML-Fassung (Export „Inhalte kopieren“ / „Kopieren“)
#   app-zwischenablage.sh --text <ziel.txt>    reiner Text (etwa die Quellenliste als JSON)
#   app-zwischenablage.sh --setzen <wert>      Zwischenablage auf einen Prüfwert setzen
#
# Windows (Git Bash): PowerShell mit System.Windows.Forms (STA).
# macOS: osascript / pbpaste. Linux: wl-paste oder xclip.
#
# Exit-Codes: 0 OK | 2 Aufruf falsch | 3 kein Werkzeug | 5 Zwischenablage leer
# =============================================================================
set -u

MODE="${1:-}"; ARG="${2:-}"
[ -n "$MODE" ] && [ -n "$ARG" ] || { echo "FEHLER: Aufruf: $0 --html|--text <ziel> | --setzen <wert>" >&2; exit 2; }

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS=win;;
  Darwin) OS=mac;;
  *) OS=linux;;
esac

ps() { powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $1"; }

if [ "$MODE" = "--setzen" ]; then
  case "$OS" in
    win) ps "[System.Windows.Forms.Clipboard]::SetText('$(printf '%s' "$ARG" | sed "s/'/''/g")')";;
    mac) printf '%s' "$ARG" | pbcopy;;
    linux) if command -v wl-copy >/dev/null; then printf '%s' "$ARG" | wl-copy
           elif command -v xclip >/dev/null; then printf '%s' "$ARG" | xclip -selection clipboard
           else echo "FEHLER: weder wl-copy noch xclip gefunden." >&2; exit 3; fi;;
  esac
  echo "OK: Zwischenablage gesetzt"; exit 0
fi

ZIEL="$ARG"
mkdir -p "$(dirname "$ZIEL")"
case "$OS" in
  win)
    WZIEL=$(cygpath -w "$ZIEL" 2>/dev/null || printf '%s' "$ZIEL")
    if [ "$MODE" = "--html" ]; then
      ps "\$h=[System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Html); if (-not \$h) { exit 5 }; [IO.File]::WriteAllText('$WZIEL', \$h, [Text.UTF8Encoding]::new(\$false))"
    else
      ps "\$t=[System.Windows.Forms.Clipboard]::GetText(); if (-not \$t) { exit 5 }; [IO.File]::WriteAllText('$WZIEL', \$t, [Text.UTF8Encoding]::new(\$false))"
    fi
    RC=$?;;
  mac)
    if [ "$MODE" = "--html" ]; then
      HEX=$(osascript -e 'the clipboard as «class HTML»' 2>/dev/null) || HEX=""
      [ -n "$HEX" ] || { echo "FEHLER: Zwischenablage enthält kein HTML." >&2; exit 5; }
      printf '%s' "$HEX" | sed -e 's/^«data HTML//' -e 's/»$//' | xxd -r -p > "$ZIEL"; RC=$?
    else
      pbpaste > "$ZIEL"; RC=$?
    fi;;
  linux)
    if command -v wl-paste >/dev/null; then
      if [ "$MODE" = "--html" ]; then wl-paste -t text/html > "$ZIEL"; else wl-paste > "$ZIEL"; fi; RC=$?
    elif command -v xclip >/dev/null; then
      if [ "$MODE" = "--html" ]; then xclip -selection clipboard -t text/html -o > "$ZIEL"; else xclip -selection clipboard -o > "$ZIEL"; fi; RC=$?
    else
      echo "FEHLER: weder wl-paste noch xclip gefunden." >&2; exit 3
    fi;;
esac

if [ "$RC" -eq 5 ] || [ ! -s "$ZIEL" ]; then
  echo "FEHLER: Zwischenablage leer oder ohne passendes Format." >&2; exit 5
fi
[ "$RC" -eq 0 ] || { echo "FEHLER: Lesen der Zwischenablage fehlgeschlagen (Exit $RC)." >&2; exit 5; }
echo "OK: $ZIEL ($(wc -c < "$ZIEL" | tr -d ' ') Byte)"
