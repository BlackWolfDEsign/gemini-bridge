#!/usr/bin/env bash
# =============================================================================
# agy-run.sh – robuster Transport von Claude Code zur Google Antigravity CLI (agy)
#
# Teil des Plugins "gemini-bridge". Abgeleitet von antigravity-plugin-cc
# (c) Marcos Nahuel Albornoz, MIT-Lizenz – siehe LICENSE.
#
# Nutzung:
#   agy-run.sh --out <datei> [--timeout 8m] [--projekt <ordner>] [--weiter] [--zeigen] < prompt.txt
#   agy-run.sh --ping       Schnelltest: ist agy installiert, angemeldet und antwortet?
#   agy-run.sh --info       Pfad, Version, Sperrstatus
#
# Was dieses Skript für dich abfängt:
#   * Bug #76: agy --print liefert ohne TTY oft leeres stdout -> Antwort wird per
#     write_file in eine Datei geschrieben; Notfall: Wiederherstellung aus dem Transcript.
#   * Hängende Aufrufe: stdin wird immer geschlossen (< /dev/null).
#   * Headless-Auth-Timeout: wird erkannt und klar gemeldet (kein sinnloser Retry).
#   * Windows #217 (Defender sperrt .tmp-Dateien): einmaliger Retry nach 2 s.
#   * Parallel-Aufrufe blockieren sich gegenseitig: globale Sperre, Aufrufe laufen nacheinander.
#   * Datenschutz: ohne --projekt läuft agy in einem leeren Temp-Ordner und sieht dein Projekt nicht.
#
# Exit-Codes: 0 OK | 2 Aufruf falsch | 3 agy fehlt | 4 Anmeldung abgelaufen
#             5 keine Antwort | 6 Sperre belegt
# =============================================================================
set -u

RUNNER_VERSION="1.0.0"
STATE_DIR="${GEMINI_BRIDGE_HOME:-$HOME/.claude/gemini-bridge}"
LOCK_DIR="$STATE_DIR/lock"
AGY_HOME="${AGY_HOME:-$HOME/.gemini/antigravity-cli}"

OUT=""; TIMEOUT="8m"; PROJEKT=""; WEITER=0; ZEIGEN=0; MODE="run"
WORK=""; HAVE_LOCK=0

die() { local code=$1; shift; echo "FEHLER: $*" >&2; exit "$code"; }

cleanup() {
  [ "$HAVE_LOCK" = 1 ] && rm -rf "$LOCK_DIR" 2>/dev/null
  [ -n "$WORK" ] && rm -rf "$WORK" 2>/dev/null
  return 0
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# Windows (Git Bash): agy ist ein natives Programm und braucht C:/...-Pfade
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
posix()  { if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s' "$1"; fi; }

find_agy() {
  if [ -n "${AGY_BIN:-}" ] && [ -x "$(posix "$AGY_BIN")" ]; then posix "$AGY_BIN"; return 0; fi
  if command -v agy >/dev/null 2>&1; then command -v agy; return 0; fi
  local c
  for c in \
    "${LOCALAPPDATA:+$(posix "$LOCALAPPDATA")/agy/bin/agy.exe}" \
    "$HOME/AppData/Local/agy/bin/agy.exe" \
    "$HOME/.local/bin/agy" \
    "/usr/local/bin/agy" \
    "/opt/homebrew/bin/agy"; do
    [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}

# "8m", "90s", "1h30m", "8m0s" oder reine Sekunden -> Sekunden
dur_secs() {
  local d=$1 s=0
  if [[ $d =~ ^[0-9]+$ ]]; then echo "$d"; return; fi
  [[ $d =~ ([0-9]+)h ]] && s=$(( s + BASH_REMATCH[1] * 3600 ))
  [[ $d =~ ([0-9]+)m ]] && s=$(( s + BASH_REMATCH[1] * 60 ))
  [[ $d =~ ([0-9]+)s ]] && s=$(( s + BASH_REMATCH[1] ))
  echo "$s"
}

# ---------------------------------------------------------------- Argumente
while [ $# -gt 0 ]; do
  case "$1" in
    --out)      OUT=${2:-}; shift 2 ;;
    --timeout)  TIMEOUT=${2:-}; shift 2 ;;
    --projekt)  PROJEKT=${2:-}; shift 2 ;;
    --weiter)   WEITER=1; shift ;;
    --zeigen)   ZEIGEN=1; shift ;;
    --ping)     MODE="ping"; shift ;;
    --info)     MODE="info"; shift ;;
    -h|--help)  sed -n '2,30p' "$0"; exit 0 ;;
    *) die 2 "Unbekannte Option: $1" ;;
  esac
done

[[ $TIMEOUT =~ ^[0-9]+$ ]] && TIMEOUT="${TIMEOUT}s"
[ "$(dur_secs "$TIMEOUT")" -gt 0 ] 2>/dev/null || die 2 "Ungültiger Timeout: $TIMEOUT"

AGY=$(find_agy) || die 3 "agy (Antigravity CLI) nicht gefunden. Installieren:
  Windows (PowerShell): irm https://antigravity.google/cli/install.ps1 | iex
  macOS/Linux:          curl -fsSL https://antigravity.google/cli/install.sh | bash
Danach Terminal neu öffnen und 'agy' einmal starten, um dich mit Google anzumelden.
Alternativ AGY_BIN auf den Pfad zu agy setzen."

# ---------------------------------------------------------------- --info
if [ "$MODE" = info ]; then
  echo "Runner:   $RUNNER_VERSION ($0)"
  echo "agy:      $AGY"
  echo "Version:  $("$AGY" --version </dev/null 2>/dev/null | head -n 1 || echo unbekannt)"
  echo "Anmeldung: $([ -s "$AGY_HOME/installation_id" ] && echo 'installation_id vorhanden' || echo 'installation_id fehlt – agy einmal interaktiv starten')"
  if [ -d "$LOCK_DIR" ]; then echo "Sperre:   belegt (PID $(cat "$LOCK_DIR/pid" 2>/dev/null || echo ?))"; else echo "Sperre:   frei"; fi
  exit 0
fi

# ---------------------------------------------------------------- Prompt
if [ "$MODE" = ping ]; then
  PROMPT_IN="Antworte mit exakt dem Wort pong und sonst nichts. Benutze außer write_file keine Werkzeuge."
  TIMEOUT="90s"
else
  [ -n "$OUT" ] || die 2 "--out <datei> fehlt."
  [ -t 0 ] && die 2 "Kein Prompt: bitte per stdin übergeben (z. B. Heredoc oder < datei)."
  PROMPT_IN=$(cat)
  [ -n "${PROMPT_IN//[[:space:]]/}" ] || die 2 "Prompt ist leer."
fi
if [ -n "$PROJEKT" ]; then
  [ -d "$PROJEKT" ] || die 2 "Projektordner existiert nicht: $PROJEKT"
  PROJEKT=$(cd "$PROJEKT" && pwd)
fi

# ---------------------------------------------------------------- Sperre
mkdir -p "$STATE_DIR" || die 1 "Kann $STATE_DIR nicht anlegen."
acquire_lock() {
  local waited=0 max=${GEMINI_BRIDGE_LOCK_WAIT:-2400} pid announced=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    pid=$(cat "$LOCK_DIR/pid" 2>/dev/null || true)
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then rm -rf "$LOCK_DIR"; continue; fi
    if [ -z "$pid" ] && [ "$waited" -ge 15 ]; then rm -rf "$LOCK_DIR"; continue; fi
    [ "$announced" = 0 ] && { echo "Warte auf einen anderen laufenden Gemini-Aufruf (läuft nacheinander, nie parallel) …" >&2; announced=1; }
    sleep 5; waited=$(( waited + 5 ))
    [ "$waited" -ge "$max" ] && die 6 "Anderer Gemini-Aufruf blockiert seit ${max}s. Falls nichts mehr läuft: Ordner $LOCK_DIR löschen."
  done
  echo $$ > "$LOCK_DIR/pid"
  HAVE_LOCK=1
}
acquire_lock

# ---------------------------------------------------------------- Arbeitsordner
WORK=$(mktemp -d "${TMPDIR:-/tmp}/gemini-bridge.XXXXXX") || die 1 "mktemp fehlgeschlagen."
OUT_TMP="$WORK/antwort.md"
LOG="$WORK/agy.log"
WORK_N=$(native "$WORK"); OUT_TMP_N=$(native "$OUT_TMP"); LOG_N=$(native "$LOG")
RUN_DIR=${PROJEKT:-$WORK}

FULL_PROMPT="$PROMPT_IN

---
AUSGABE-ANWEISUNG (zwingend): Gib deine Antwort NICHT im Chat aus. Schreibe die vollständige Antwort mit dem Werkzeug write_file in genau diese Datei:
  $OUT_TMP_N
Danach nur kurz den Pfad bestätigen. Diese Datei ist dein einziges Ergebnis."

# Verwaiste .tmp-Dateien früherer Abstürze entfernen (Windows #217), nie fatal
find "$AGY_HOME/conversations" -name '*.tmp' -mmin +5 -delete 2>/dev/null || true

GUARD=$(( $(dur_secs "$TIMEOUT") + 90 ))
TO_CMD=()
if command -v timeout >/dev/null 2>&1; then TO_CMD=(timeout -k 10 "$GUARD")
elif command -v gtimeout >/dev/null 2>&1; then TO_CMD=(gtimeout -k 10 "$GUARD"); fi

USE_LOGFLAG=1
run_agy() {
  local args=(--dangerously-skip-permissions --add-dir "$WORK_N")
  [ -n "$PROJEKT" ] && args+=(--add-dir "$(native "$PROJEKT")")
  args+=(--print-timeout "$TIMEOUT")
  [ "$USE_LOGFLAG" = 1 ] && args+=(--log-file "$LOG_N")
  [ "$WEITER" = 1 ] && args+=(--continue)
  args+=(--print "$FULL_PROMPT")            # --print MUSS das letzte Flag sein
  ( cd "$RUN_DIR" && ${TO_CMD[@]+"${TO_CMD[@]}"} "$AGY" "${args[@]}" \
      < /dev/null > "$WORK/stdout.txt" 2> "$WORK/stderr.txt" )
  echo $?
}

log_text() {
  if [ -s "$LOG" ]; then cat "$LOG"; return; fi
  local latest
  latest=$(ls -t "$AGY_HOME"/log/cli-*.log 2>/dev/null | head -n 1)
  [ -n "$latest" ] && tail -n 400 "$latest"
}

save_diag() {
  { echo "=== $(date '+%F %T') | timeout=$TIMEOUT | rc=${RC:-?}"
    echo "--- stderr"; tail -n 40 "$WORK/stderr.txt" 2>/dev/null
    echo "--- log (Ende)"; log_text | tail -n 80
  } > "$STATE_DIR/letzter-lauf.log" 2>/dev/null || true
}

json_last_response() {   # $1 = transcript.jsonl
  local f=$1 py
  for py in python3 python py; do
    if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import json' >/dev/null 2>&1; then
      "$py" -I - "$(native "$f")" <<'PY'
import json, sys
last = None
with open(sys.argv[1], encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
        except Exception:
            continue
        if o.get("source") == "MODEL" and o.get("type") == "PLANNER_RESPONSE" and o.get("content"):
            last = o["content"]
if not last:
    sys.exit(1)
sys.stdout.write(last)
PY
      return $?
    fi
  done
  if command -v node >/dev/null 2>&1; then
    node -e '
const fs=require("fs");let last="";
for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n")){
  try{const o=JSON.parse(l);if(o.source==="MODEL"&&o.type==="PLANNER_RESPONSE"&&o.content)last=o.content}catch(e){}
}
if(!last)process.exit(1);process.stdout.write(last);' "$(native "$f")"
    return $?
  fi
  return 1
}

recover_transcript() {
  local cid tx
  cid=$(log_text | grep -oE 'conversation=[0-9a-f-]{36}' | tail -n 1 | cut -d= -f2)
  [ -z "$cid" ] && cid=$(ls -t "$AGY_HOME/brain/" 2>/dev/null | head -n 1)
  [ -z "$cid" ] && return 1
  tx="$AGY_HOME/brain/$cid/.system_generated/logs/transcript.jsonl"
  [ -f "$tx" ] || return 1
  json_last_response "$tx" > "$OUT_TMP" && [ -s "$OUT_TMP" ]
}

deliver() {
  local note=${1:-}
  if [ "$MODE" = ping ]; then
    if grep -qi 'pong' "$OUT_TMP"; then echo "PING OK – agy ist installiert, angemeldet und antwortet."; exit 0; fi
    die 5 "agy hat geantwortet, aber nicht mit 'pong': $(head -c 200 "$OUT_TMP")"
  fi
  mkdir -p "$(dirname "$OUT")" || die 1 "Kann Zielordner für $OUT nicht anlegen."
  cp "$OUT_TMP" "$OUT" || die 1 "Kann $OUT nicht schreiben."
  save_diag
  echo "OK: $OUT${note:+ ($note)}"
  [ "$ZEIGEN" = 1 ] && { echo "-----"; cat "$OUT"; }
  exit 0
}

# ---------------------------------------------------------------- Ausführen
RC=$(run_agy)
if grep -q 'flag provided but not defined: -log-file' "$WORK/stderr.txt" 2>/dev/null; then
  USE_LOGFLAG=0; RC=$(run_agy)
fi
[ -s "$OUT_TMP" ] && deliver

LT=$(log_text)

# Windows Defender sperrt die .tmp-Datei (#217): einmal nach kurzer Pause wiederholen
if grep -q 'Access is denied' <<<"$LT"; then
  sleep 2; RC=$(run_agy)
  [ -s "$OUT_TMP" ] && deliver "nach Retry"
  save_diag
  die 5 "Windows Defender blockiert agy weiterhin. Dauerhafte Lösung (PowerShell als Admin):
  Add-MpPreference -ExclusionPath \"\$env:USERPROFILE\\.gemini\\antigravity-cli\\conversations\""
fi

# Anmeldung im Hintergrundmodus abgelaufen: Retry bringt nichts
if grep -Eq 'auth timed out|silent auth failed|keyringAuth: timed out|OAuth login required|please run agy to sign in' <<<"$LT"; then
  save_diag
  die 4 "Die agy-Anmeldung ist abgelaufen (das Modell lief gar nicht). Lösung: in einem normalen Terminal einmal 'agy' starten, anmelden, wieder schließen – dann erneut versuchen."
fi

# Bug #76: Antwort wurde erzeugt, aber nicht ausgegeben -> aus dem Transcript holen
if recover_transcript; then deliver "aus agy-Transcript wiederhergestellt"; fi

# Notfalls stdout verwenden, falls agy doch dort geantwortet hat
if [ "$(wc -c < "$WORK/stdout.txt" 2>/dev/null || echo 0)" -gt 80 ]; then
  cp "$WORK/stdout.txt" "$OUT_TMP"; deliver "aus stdout"
fi

save_diag
if [ "$RC" = 124 ] || [ "$RC" = 137 ]; then
  die 5 "Zeitlimit ($TIMEOUT) überschritten, keine Antwort. Größeren --timeout wählen oder Frage enger fassen. Diagnose: $STATE_DIR/letzter-lauf.log"
fi
OTHERS=$( (pgrep -fl 'agy' 2>/dev/null || ps -ef 2>/dev/null | grep -i '[a]gy') | grep -v -e agy-run -e "$$" | head -n 3)
[ -n "$OTHERS" ] && die 5 "Keine Antwort – vermutlich lief gleichzeitig ein anderer agy-Prozess (z. B. ein offenes agy-Terminal). Bitte beenden und erneut versuchen.
$OTHERS"
die 5 "agy hat keine Antwort geliefert (Exit $RC). Diagnose: $STATE_DIR/letzter-lauf.log
$(tail -n 5 "$WORK/stderr.txt" 2>/dev/null)"
