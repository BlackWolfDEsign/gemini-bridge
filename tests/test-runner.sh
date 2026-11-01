#!/usr/bin/env bash
# Testet agy-run.sh gegen ein nachgebautes agy (keine echte Google-Verbindung nötig).
# Aufruf: bash tests/test-runner.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/plugins/gemini/scripts/agy-run.sh"
T=$(mktemp -d)
export HOME="$T/home" GEMINI_BRIDGE_HOME="$T/home/.claude/gemini-bridge" AGY_HOME="$T/home/.gemini/antigravity-cli"
mkdir -p "$AGY_HOME/log" "$AGY_HOME/conversations" "$AGY_HOME/brain"
PASS=0; FAIL=0
ok()   { echo "  ✔ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ✘ $1"; FAIL=$((FAIL+1)); }

# ---- Mock-agy: Verhalten über MOCK_MODE steuerbar
cat > "$T/agy" <<'MOCK'
#!/usr/bin/env bash
LOGF=""; PROMPT=""; ARGS="$*"
echo "$ARGS" > "$MOCK_ARGS_FILE"
pwd > "$MOCK_CWD_FILE"
while [ $# -gt 0 ]; do
  case "$1" in
    --log-file) LOGF=$2; shift 2;;
    --print) PROMPT=$2; shift 2;;
    --version) echo "agy 1.0.9-mock"; exit 0;;
    --add-dir|--print-timeout) shift 2;;
    *) shift;;
  esac
done
# stdin muss geschlossen sein, sonst würde echtes agy hängen
if ! read -t 1 -r _; then :; fi
OUTF=$(printf '%s\n' "$PROMPT" | grep -A1 'in genau diese Datei' | tail -n1 | sed 's/^ *//')
CID=11111111-2222-3333-4444-555555555555
case "$MOCK_MODE" in
  ok)      printf '# Antwort\nInhalt zu: %s\n' "$(printf '%s' "$PROMPT" | head -n1)" > "$OUTF"; echo "Print mode: conversation=$CID" > "$LOGF";;
  pong)    echo pong > "$OUTF";;
  drop76)  echo "Print mode: conversation=$CID" > "$LOGF"; echo "text_drip.go: Drip stopped: length=42" >> "$LOGF"
           mkdir -p "$AGY_HOME/brain/$CID/.system_generated/logs"
           printf '%s\n' '{"source":"USER","type":"X","content":"frage"}' '{"source":"MODEL","type":"PLANNER_RESPONSE","content":"Gerettete Antwort aus Transcript"}' > "$AGY_HOME/brain/$CID/.system_generated/logs/transcript.jsonl";;
  auth)    printf 'printmode.go: Print mode: silent auth failed, triggering OAuth\nPrint mode: auth timed out\n' > "$LOGF";;
  defender)
           if [ -f "$MOCK_STATE" ]; then echo "# nach retry" > "$OUTF"; else touch "$MOCK_STATE"; echo "rename x.tmp x.pb: Access is denied." > "$LOGF"; fi;;
  nothing) : ;;
  slow)    sleep 3; echo "# langsam" > "$OUTF";;
esac
exit 0
MOCK
chmod +x "$T/agy"
export AGY_BIN="$T/agy" MOCK_ARGS_FILE="$T/args" MOCK_CWD_FILE="$T/cwd" MOCK_STATE="$T/state"
cd "$T"

echo "1) Normaler Lauf"
MOCK_MODE=ok bash "$RUNNER" --out "$T/res/a.md" --timeout 1m <<<"Was ist X?" >"$T/o" 2>&1
grep -q '^OK:' "$T/o" && grep -q 'Inhalt zu: Was ist X?' "$T/res/a.md" && ok "Antwort landet in --out" || { bad "Normaler Lauf"; cat "$T/o"; }
grep -q -- '--print-timeout 1m --log-file' "$T/args" && ok "Flags korrekt" || bad "Flags: $(cat "$T/args")"
[[ "$(cat "$T/args")" == *"--print "* ]] && [[ "$(cat "$T/args")" != *"--print --"* ]] && ok "--print ist letztes Flag" || bad "--print Position"
[[ "$(cat "$T/cwd")" == */gemini-bridge.* ]] && ok "agy läuft isoliert im Temp-Ordner (sieht Projekt nicht)" || bad "cwd: $(cat "$T/cwd")"
[ ! -d "$GEMINI_BRIDGE_HOME/lock" ] && ok "Sperre wieder freigegeben" || bad "Sperre hängt"

echo "2) --projekt gibt Zugriff auf Projekt"
mkdir -p "$T/proj"
MOCK_MODE=ok bash "$RUNNER" --out "$T/res/b.md" --projekt "$T/proj" <<<"Code?" >"$T/o" 2>&1
[ "$(cat "$T/cwd")" = "$T/proj" ] && grep -q -- "--add-dir $T/proj" "$T/args" && ok "läuft im Projekt mit --add-dir" || bad "projekt: $(cat "$T/cwd") / $(cat "$T/args")"

echo "3) Bug #76 – Antwort aus Transcript retten"
MOCK_MODE=drop76 bash "$RUNNER" --out "$T/res/c.md" <<<"x" >"$T/o" 2>&1
grep -q 'Transcript' "$T/o" && grep -q 'Gerettete Antwort' "$T/res/c.md" && ok "Transcript-Wiederherstellung" || { bad "Transcript"; cat "$T/o"; }

echo "4) Anmeldung abgelaufen"
MOCK_MODE=auth bash "$RUNNER" --out "$T/res/d.md" <<<"x" >"$T/o" 2>&1; rc=$?
[ $rc = 4 ] && grep -q 'Anmeldung ist abgelaufen' "$T/o" && ok "Exit 4 + klare Meldung" || { bad "auth rc=$rc"; cat "$T/o"; }

echo "5) Windows-Defender-Retry"
rm -f "$T/state"
MOCK_MODE=defender bash "$RUNNER" --out "$T/res/e.md" <<<"x" >"$T/o" 2>&1
grep -q 'nach Retry' "$T/o" && ok "einmaliger Retry erfolgreich" || { bad "defender"; cat "$T/o"; }

echo "6) Gar keine Antwort"
rm -rf "$AGY_HOME/brain/"*
MOCK_MODE=nothing bash "$RUNNER" --out "$T/res/f.md" <<<"x" >"$T/o" 2>&1; rc=$?
[ $rc = 5 ] && [ -s "$GEMINI_BRIDGE_HOME/letzter-lauf.log" ] && ok "Exit 5 + Diagnose-Log" || { bad "nothing rc=$rc"; cat "$T/o"; }

echo "7) Ping"
MOCK_MODE=pong bash "$RUNNER" --ping >"$T/o" 2>&1 && grep -q 'PING OK' "$T/o" && ok "Ping" || { bad "Ping"; cat "$T/o"; }

echo "8) Info"
bash "$RUNNER" --info >"$T/o" 2>&1 && grep -q 'agy 1.0.9-mock' "$T/o" && ok "Info zeigt Version" || { bad "info"; cat "$T/o"; }

echo "9) Parallel-Aufrufe laufen nacheinander"
start=$(date +%s)
MOCK_MODE=slow bash "$RUNNER" --out "$T/res/g1.md" <<<"a" >"$T/o1" 2>&1 &
sleep 0.5
MOCK_MODE=slow bash "$RUNNER" --out "$T/res/g2.md" <<<"b" >"$T/o2" 2>&1
wait
dur=$(( $(date +%s) - start ))
[ -s "$T/res/g1.md" ] && [ -s "$T/res/g2.md" ] && [ $dur -ge 6 ] && grep -q 'Warte auf' "$T/o2" && ok "serialisiert (${dur}s, 2. Aufruf hat gewartet)" || { bad "lock dur=$dur"; cat "$T/o1" "$T/o2"; }

echo "10) Verwaiste Sperre wird erkannt"
mkdir -p "$GEMINI_BRIDGE_HOME/lock"; echo 999999 > "$GEMINI_BRIDGE_HOME/lock/pid"
MOCK_MODE=ok timeout 20 bash "$RUNNER" --out "$T/res/h.md" <<<"x" >"$T/o" 2>&1 && ok "tote PID übernommen" || { bad "stale lock"; cat "$T/o"; }

echo "11) Fehlerfälle beim Aufruf"
bash "$RUNNER" --timeout 1m </dev/null >"$T/o" 2>&1; [ $? = 2 ] && ok "--out fehlt -> Exit 2" || bad "missing out"
AGY_BIN="$T/nix" PATH=/usr/bin:/bin bash "$RUNNER" --info >"$T/o" 2>&1; [ $? = 3 ] && ok "agy fehlt -> Exit 3 + Installationshinweis" || { bad "missing agy"; cat "$T/o"; }

echo "12) --zeigen gibt Inhalt aus"
MOCK_MODE=ok bash "$RUNNER" --out "$T/res/i.md" --zeigen <<<"Zeig mir" >"$T/o" 2>&1
grep -q 'Inhalt zu: Zeig mir' "$T/o" && ok "Inhalt ausgegeben" || bad "zeigen"

echo
echo "Ergebnis: $PASS bestanden, $FAIL fehlgeschlagen"
rm -rf "$T"
[ $FAIL = 0 ]
