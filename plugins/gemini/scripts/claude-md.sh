#!/usr/bin/env bash
# =============================================================================
# claude-md.sh – trägt den gemini-bridge-Baustein in eine CLAUDE.md ein.
#
# Nutzung:  claude-md.sh status|install|remove projekt|global|<pfad/zur/CLAUDE.md>
#   projekt = ./CLAUDE.md im aktuellen Ordner
#   global  = ~/.claude/CLAUDE.md (gilt für alle Projekte)
#
# Der Baustein steht zwischen Markierungen und wird bei erneutem install
# ersetzt statt doppelt eingefügt. Vor jeder Änderung: Sicherung *.bak-gemini.
# Windows-Zeilenenden (CRLF) der vorhandenen Datei bleiben erhalten.
# =============================================================================
set -u
AKTION=${1:-}; ZIEL=${2:-}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VORLAGE="$DIR/../vorlagen/CLAUDE-gemini.md"
VERSION=$(grep -o '"version": *"[^"]*"' "$DIR/../.claude-plugin/plugin.json" 2>/dev/null | head -n1 | grep -o '[0-9][^"]*')
START="<!-- gemini-bridge:start"
ENDE="<!-- gemini-bridge:end -->"

die() { echo "FEHLER: $*" >&2; exit 2; }

# ---------------------------------------------------------------------------
# setup <wunsch> – wird von /gemini:setup aufgerufen; <wunsch> ist die Eingabe
# des Nutzers (leer, projekt, global, beide, ohne, entfernen).
# Leer = automatisch: vorhandenen Baustein aktualisieren, sonst ins Projekt.
# ---------------------------------------------------------------------------
if [ "$AKTION" = setup ]; then
  SELF="${BASH_SOURCE[0]}"
  W=$(printf '%s' "$ZIEL" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  [ "$W" = '$arguments' ] && W=""   # Platzhalter nicht ersetzt = keine Eingabe
  echo "CLAUDE.md-Ordner (aktuelles Projekt): $PWD"
  ist_home() { [ "$(cd "$PWD" && pwd -P)" = "$(cd "$HOME" && pwd -P)" ] || [ "$PWD" = / ]; }
  case "$W" in
    ohne)      echo "CLAUDE.md: übersprungen (auf Wunsch)"; exit 0 ;;
    entfernen) bash "$SELF" remove projekt; bash "$SELF" remove global; exit 0 ;;
    global)    bash "$SELF" install global; exit $? ;;
    beide)     ist_home || bash "$SELF" install projekt; bash "$SELF" install global; exit $? ;;
    projekt)   ist_home && die "Der aktuelle Ordner ist dein Benutzerordner, kein Projekt. Öffne Claude Code im Projektordner oder nutze /gemini:setup global."
               bash "$SELF" install projekt; exit $? ;;
    "")
      if grep -qs "^$START" "$PWD/CLAUDE.md"; then bash "$SELF" install projekt
      elif grep -qs "^$START" "$HOME/.claude/CLAUDE.md"; then
        bash "$SELF" install global
        echo "HINWEIS: Regeln gelten bereits global für alle Projekte – im Projekt nichts eingetragen. Nur fürs Projekt: /gemini:setup projekt"
      elif ist_home; then
        echo "HINWEIS: Kein Projektordner geöffnet (aktueller Ordner = Benutzerordner). Nichts eingetragen. Für alle Projekte: /gemini:setup global"
      else bash "$SELF" install projekt
        echo "HINWEIS: Für alle Projekte statt nur dieses: /gemini:setup global"
      fi
      exit $? ;;
    *) die "Unbekannte Eingabe '$ZIEL'. Erlaubt: projekt | global | beide | ohne | entfernen" ;;
  esac
fi

case "$ZIEL" in
  projekt) DATEI="$PWD/CLAUDE.md" ;;
  global)  DATEI="$HOME/.claude/CLAUDE.md" ;;
  "")      die "Ziel fehlt: projekt | global | <pfad>" ;;
  *)       DATEI="$ZIEL" ;;
esac
[ -f "$VORLAGE" ] || die "Vorlage fehlt: $VORLAGE"

hat_block() { [ -f "$DATEI" ] && grep -q "^$START" "$DATEI"; }
version_im_block() { grep -o "^$START v[^ ]*" "$DATEI" 2>/dev/null | head -n1 | sed 's/.* v//'; }
ohne_block() {   # gibt die Datei ohne den Baustein aus
  awk -v s="$START" -v e="$ENDE" '
    index($0, s) == 1 { skip = 1; next }
    skip && index($0, e) == 1 { skip = 0; next }
    !skip { print }' "$DATEI"
}

case "$AKTION" in
  status)
    if [ ! -f "$DATEI" ]; then echo "STATUS: $DATEI existiert nicht"
    elif hat_block; then echo "STATUS: Baustein vorhanden (v$(version_im_block)) in $DATEI – aktuell: v$VERSION"
    else echo "STATUS: $DATEI vorhanden, ohne Baustein"; fi
    ;;

  install)
    mkdir -p "$(dirname "$DATEI")" || die "Kann Ordner für $DATEI nicht anlegen"
    CRLF=0
    if [ -f "$DATEI" ]; then
      grep -q $'\r$' "$DATEI" && CRLF=1
      cp "$DATEI" "$DATEI.bak-gemini" || die "Sicherung fehlgeschlagen"
    fi
    VORHER=$(hat_block && echo ja || echo nein)
    TMP="$DATEI.tmp-gemini.$$"
    {
      if [ -f "$DATEI" ]; then
        ohne_block | tr -d '\r' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'   # Leerzeilen am Ende kürzen
        [ -s "$DATEI" ] && [ -n "$(ohne_block | tr -d '[:space:]')" ] && echo
      fi
      echo "$START v$VERSION – verwaltet von /gemini:setup, Änderungen hier werden beim nächsten Setup überschrieben -->"
      tr -d '\r' < "$VORLAGE"
      echo "$ENDE"
    } > "$TMP" || { rm -f "$TMP"; die "Schreiben fehlgeschlagen"; }
    if [ "$CRLF" = 1 ]; then sed -i 's/$/\r/' "$TMP"; fi
    mv -f "$TMP" "$DATEI" || { rm -f "$TMP"; die "Ersetzen fehlgeschlagen"; }
    if [ "$VORHER" = ja ]; then echo "OK: Baustein in $DATEI aktualisiert (v$VERSION). Sicherung: $DATEI.bak-gemini"
    elif [ -f "$DATEI.bak-gemini" ]; then echo "OK: Baustein an $DATEI angehängt (v$VERSION). Sicherung: $DATEI.bak-gemini"
    else echo "OK: $DATEI neu angelegt mit Baustein (v$VERSION)"; fi
    ;;

  remove)
    hat_block || { echo "OK: kein Baustein in $DATEI – nichts zu tun"; exit 0; }
    cp "$DATEI" "$DATEI.bak-gemini" || die "Sicherung fehlgeschlagen"
    TMP="$DATEI.tmp-gemini.$$"
    ohne_block > "$TMP" && mv -f "$TMP" "$DATEI" || { rm -f "$TMP"; die "Entfernen fehlgeschlagen"; }
    echo "OK: Baustein aus $DATEI entfernt. Sicherung: $DATEI.bak-gemini"
    ;;

  *) die "Aktion fehlt: status | install | remove" ;;
esac
