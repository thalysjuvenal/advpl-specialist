#!/usr/bin/env bash
# Runner for hooks/pre-tool-use + hooks/post-tool-use + hooks/post-tool-use-read
# + hooks/post-tool-use-bash + hooks/stop: simulates the stdin JSON Claude Code
# sends to PreToolUse/PostToolUse for Write|Edit|MultiEdit, to PostToolUse for
# Read and Bash and to Stop/SessionEnd, in a temporary directory, and checks
# exit codes, stderr/stdout, file bytes and the session's pending list (files
# converted back to Windows-1252 at the end of the turn). Also checks
# hooks/hooks.json and hooks/session-start.
#
# Usage: bash tests/hooks/run-tests.sh
#   HOOK_BASH  interpreter for the hooks (default /bin/bash: bash 3.2 on macOS)
#
# Every case runs once per JSON parser: "jq" (only when jq is installed) and
# "builtin" (ADVPL_HOOK_NO_JQ=1 forces the awk fallback of the hooks).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_BASH="${HOOK_BASH:-/bin/bash}"
PRE="$ROOT/hooks/pre-tool-use"
POST="$ROOT/hooks/post-tool-use"
READ="$ROOT/hooks/post-tool-use-read"
BASHHOOK="$ROOT/hooks/post-tool-use-bash"
STOP="$ROOT/hooks/stop"
# the converter as the Read hint names it (symbolic links resolved)
CONV="$(cd "$ROOT/skills/advpl-code-generation/scripts" && pwd -P)/convert-encoding.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export CLAUDE_PLUGIN_ROOT="$ROOT"
export CLAUDE_PLUGIN_DATA="$TMP_DIR/plugin-data"
export CLAUDE_PROJECT_DIR="$TMP_DIR"
SNAP_DIR="$CLAUDE_PLUGIN_DATA/advpl-specialist-snapshots"
PEND_DIR="$CLAUDE_PLUGIN_DATA/advpl-specialist-pending"
SID=t   # session_id of the payloads (new_session gives a case its own list)
cd "$TMP_DIR" || exit 2   # no .advpl-specialist-ignore from the caller's cwd

FFFD="$(printf '\357\277\275')"
CP_ACENTO="$(printf '\347\343')"      # "ca" cedilha + "a" til em Windows-1252
UTF8_ACENTO="$(printf '\303\247')"    # "c" cedilha em UTF-8

PASS=0; FAIL=0
pass() { echo "  ok   $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL $1"; FAIL=$((FAIL+1)); }
check() { # check LABEL CMD... : passes when CMD succeeds
  local label="$1"; shift
  if "$@"; then pass "$label"; else fail "$label"; fi
}

json_quote() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# hook_json EVENT TOOL PATH: payload with decoy "file_path" text inside the
# other tool_input strings, placed before the real key.
hook_json() {
  local p; p="$(json_quote "$3")"
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"%s","tool_name":"%s","tool_input":{"old_string":"say \\"file_path\\": \\"/decoy.prw\\"","new_string":"a\\\\\\"file_path\\\\\\":x","file_path":"%s"},"tool_response":{"filePath":"%s"}}' \
    "$(json_quote "$SID")" "$(json_quote "$TMP_DIR")" "$1" "$2" "$p" "$p"
}

# pre PATH [TOOL] / post PATH [TOOL]: run the hook; post sets RC, OUT, ERR
pre() {
  hook_json PreToolUse "${2:-Edit}" "$1" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$PRE" >"$TMP_DIR/pre.out" 2>&1
  PRE_RC=$?
}
post() {
  hook_json PostToolUse "${2:-Edit}" "$1" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$POST" >"$TMP_DIR/post.out" 2>"$TMP_DIR/post.err"
  RC=$?
  OUT="$(cat "$TMP_DIR/post.out")"
  ERR="$(cat "$TMP_DIR/post.err")"
}

snap_key() { printf '%s' "$1" | cksum | awk '{print $1 "-" $2}'; }
snap_empty() { [ -z "$(ls -A "$SNAP_DIR" 2>/dev/null)" ]; }
has_bytes() { LC_ALL=C grep -q "$1" "$2"; }
lacks_bytes() { ! LC_ALL=C grep -q "$1" "$2"; }
contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
lacks() { ! contains "$1" "$2"; }
finding_count() { printf '%s\n' "$1" | grep -Ec ': (error|warning) ADV[0-9]'; }
not() { ! "$@"; }

# Pending list of the session $SID: the files hooks/stop converts back to
# Windows-1252 at the end of the turn.
new_session() { SID="$MODE-$1"; rm -f "$PEND_DIR/$SID"; }
pending_has() { [ -f "$PEND_DIR/$SID" ] && grep -qxF -- "$1" "$PEND_DIR/$SID"; }
pending_count() {
  if [ -f "$PEND_DIR/$SID" ]; then wc -l <"$PEND_DIR/$SID" | tr -d ' '; else echo 0; fi
}
pending_gone() { [ ! -e "$PEND_DIR/$SID" ]; }
# pending_none: neither the list nor a work file ($SID.*) of the session is left
pending_none() {
  local w
  for w in "$PEND_DIR/$SID" "$PEND_DIR/$SID".*; do [ ! -e "$w" ] || return 1; done
}
# pending_set PATH...: the session's list, written by hand
pending_set() { mkdir -p "$PEND_DIR" && printf '%s\n' "$@" >"$PEND_DIR/$SID"; }

# Background task entries (background_tasks of the Stop input)
# (a shell task whose strings and nested object mention another "type")
T_SHELL='{"id":"b1","type":"shell","status":"running","description":"tail ] } \"type\": \"subagent\"","command":"echo \"type\":\"subagent\" [x]","meta":{"type":"subagent","tags":["]","}"]}}'
T_SUBAGENT='{"id":"b2","type":"subagent","status":"running","description":"revisa os fontes","agent_type":"code-reviewer"}'

# stop_json EVENT [TASKS]: payload of EVENT (Stop, SessionEnd or another one)
# for session $SID. TASKS: the raw background_tasks array ("[]" when omitted)
# or "absent" (no key). last_assistant_message carries escaped decoy
# "background_tasks" keys before the real one, an empty array first (a parser
# that took it would never defer), then a subagent.
stop_json() {
  local tasks="${2:-[]}" bg decoy='[] e \"background_tasks\": [{\"type\":\"subagent\"}]'
  bg="\"background_tasks\":$tasks,"
  [ "$tasks" != absent ] || bg=''
  if [ "$1" = SessionEnd ]; then
    printf '{"session_id":"%s","transcript_path":"/t.jsonl","cwd":"%s","hook_event_name":"SessionEnd","reason":"other"}' \
      "$(json_quote "$SID")" "$(json_quote "$TMP_DIR")"
  else
    printf '{"session_id":"%s","transcript_path":"/t.jsonl","cwd":"%s","hook_event_name":"%s","stop_hook_active":false,"last_assistant_message":"say \\"background_tasks\\": %s",%s"session_crons":[]}' \
      "$(json_quote "$SID")" "$(json_quote "$TMP_DIR")" "$1" "$decoy" "$bg"
  fi
}

# stop_hook EVENT [TASKS]: run hooks/stop; sets RC, OUT, ERR and SYS (decoded
# systemMessage)
stop_hook() {
  stop_json "$@" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$STOP" >"$TMP_DIR/stop.out" 2>"$TMP_DIR/stop.err"
  RC=$?
  OUT="$(cat "$TMP_DIR/stop.out")"
  ERR="$(cat "$TMP_DIR/stop.err")"
  SYS="$(json_string .systemMessage systemMessage "$OUT")"
}

# set_line FILE N TEXT: replace line N (bytes kept, LF ending on that line)
set_line() {
  NEWLINE_TEXT="$3" LC_ALL=C awk -v n="$2" 'NR == n { print ENVIRON["NEWLINE_TEXT"]; next } { print }' "$1" >"$1.new" &&
    cat "$1.new" >"$1" && rm -f "$1.new"
}
# insert_after FILE N TEXT
insert_after() {
  NEWLINE_TEXT="$3" LC_ALL=C awk -v n="$2" '{ print } NR == n { print ENVIRON["NEWLINE_TEXT"] }' "$1" >"$1.new" &&
    cat "$1.new" >"$1" && rm -f "$1.new"
}

# Windows-1252 legacy source: line 10 IIf( (warn), line 11 ConOut( (error)
legacy_cp1252() {
  {
    printf '#include "totvs.ch"\n'
    printf '\n'
    printf '/*/{Protheus.doc} FATA001\n'
    printf 'Rotina de importa\347\343o de pedidos\n'
    printf '/*/\n'
    printf 'User Function FATA001()\n'
    printf '\tLocal cDesc := "Descri\347\343o padr\343o"\n'
    printf '\tLocal nX := 0\n'
    printf '\tLocal nY := 0\n'
    printf '\tnX := IIf(Empty(cDesc), 1, 2)\n'
    printf '\tConOut("in\355cio da importa\347\343o")\n'
    printf '\tnY := nX + 1\n'
    printf 'Return Nil\n'
  } >"$1"
}

# ---------------------------------------------------------------------------

case_write_novo() {
  local d="$TMP_DIR/$MODE/write-novo" f
  mkdir -p "$d"; f="$d/FATA002.prw"
  new_session write-novo
  pre "$f" Write
  printf '#include "totvs.ch"\n\nUser Function FATA002()\n\tLocal cMsg := "importa\303\247\303\243o"\n\tConOut(cMsg)\nReturn Nil\n' >"$f"
  post "$f" Write
  check "write-novo: exit 2" [ "$RC" = 2 ]
  check "write-novo: stderr cita ADV003 na linha 5" contains "$ERR" "FATA002.prw:5: error ADV003"
  check "write-novo: stderr traz a dica do ignore" contains "$ERR" ".advpl-specialist-ignore"
  check "write-novo: stdout vazio" [ -z "$OUT" ]
  check "write-novo: continua UTF-8 depois do post (sem conversao por Edit)" has_bytes "$UTF8_ACENTO" "$f"
  check "write-novo: entra na lista de pendentes da sessao" pending_has "$f"
  check "write-novo: snapshot removido" snap_empty
  stop_hook Stop
  check "write-novo: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "write-novo: Stop converte para CP1252" has_bytes "$(printf 'importa\347\343o')" "$f"
  check "write-novo: sem bytes UTF-8 remanescentes" lacks_bytes "$UTF8_ACENTO" "$f"
  check "write-novo: lista removida depois do Stop" pending_gone
}

case_edit_legado_cp1252() {
  local d="$TMP_DIR/$MODE/edit-legado" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  legacy_cp1252 "$f"
  pre "$f"
  check "edit-legado-cp1252: pre exit 0" [ "$PRE_RC" = 0 ]
  check "edit-legado-cp1252: snapshot criado" [ -f "$SNAP_DIR/$(snap_key "$f")" ]
  set_line "$f" 12 "$(printf '\tnX := 1')"
  post "$f"
  check "edit-legado-cp1252: exit 0" [ "$RC" = 0 ]
  check "edit-legado-cp1252: sem stdout" [ -z "$OUT" ]
  check "edit-legado-cp1252: sem stderr" [ -z "$ERR" ]
  check "edit-legado-cp1252: acentos CP1252 preservados" has_bytes "$CP_ACENTO" "$f"
  check "edit-legado-cp1252: snapshot removido" snap_empty
}

case_edit_legado_reencode() {
  # the editor rewrote the whole CP1252 file as UTF-8: snapshot and file are
  # compared as Windows-1252, so the legacy lines (accents, IIf l.10, ConOut
  # l.11) are not introduced
  local d="$TMP_DIR/$MODE/edit-reencode" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  new_session edit-reencode
  legacy_cp1252 "$f"
  pre "$f"
  set_line "$f" 12 "$(printf '\tnX := 1')"
  iconv -f WINDOWS-1252 -t UTF-8 "$f" >"$f.u" && cat "$f.u" >"$f" && rm -f "$f.u"
  post "$f"
  check "edit-legado-utf8: exit 0" [ "$RC" = 0 ]
  check "edit-legado-utf8: sem saida" [ -z "$OUT$ERR" ]
  check "edit-legado-utf8: continua UTF-8 ate o fim do turno" has_bytes "$UTF8_ACENTO" "$f"
  stop_hook Stop
  check "edit-legado-utf8: Stop reconverte para CP1252" has_bytes "$CP_ACENTO" "$f"
  check "edit-legado-utf8: sem bytes UTF-8" lacks_bytes "$UTF8_ACENTO" "$f"
}

case_edit_introduz_erro() {
  local d="$TMP_DIR/$MODE/edit-erro" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  legacy_cp1252 "$f"
  pre "$f"
  set_line "$f" 12 "$(printf '\tConOut("nova linha")')"
  post "$f"
  check "edit-introduz-erro: exit 2" [ "$RC" = 2 ]
  check "edit-introduz-erro: acusa a linha 12" contains "$ERR" "FATA001.prw:12: error ADV003"
  check "edit-introduz-erro: nao acusa o legado (linha 11)" lacks "$ERR" "FATA001.prw:11:"
  check "edit-introduz-erro: nao acusa o IIf legado (linha 10)" lacks "$ERR" "FATA001.prw:10:"
  check "edit-introduz-erro: exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
  check "edit-introduz-erro: snapshot removido" snap_empty
}

case_edit_crlf() {
  local d="$TMP_DIR/$MODE/edit-crlf" f
  mkdir -p "$d"; f="$d/FATA003.prw"
  legacy_cp1252 "$f.lf"
  LC_ALL=C awk '{ printf "%s\r\n", $0 }' "$f.lf" >"$f" && rm -f "$f.lf"
  pre "$f"
  # same text re-saved with LF on line 12, plus a new LF line after line 9
  set_line "$f" 12 "$(printf '\tnY := nX + 1')"
  insert_after "$f" 9 "$(printf '\tConOut("crlf")')"
  post "$f"
  check "edit-crlf: exit 2" [ "$RC" = 2 ]
  check "edit-crlf: acusa so a linha nova (10)" contains "$ERR" "FATA003.prw:10: error ADV003"
  check "edit-crlf: exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
}

case_caminho_espaco_acento() {
  local d f
  d="$TMP_DIR/$MODE/meu projeto/jo$(printf '\303\243')o"
  mkdir -p "$d"; f="$d/FATA001.PRW"
  new_session caminho-espaco-acento
  printf '#include "totvs.ch"\n\nUser Function FATA001()\n\tLocal nX := 0\n\tConOut("legado")\nReturn nX\n' >"$f"
  pre "$f"
  check "caminho-espaco-acento: snapshot criado" [ -f "$SNAP_DIR/$(snap_key "$f")" ]
  insert_after "$f" 4 "$(printf '\tConOut("novo")')"
  post "$f"
  check "caminho-espaco-acento: exit 2" [ "$RC" = 2 ]
  check "caminho-espaco-acento: cita o caminho completo" contains "$ERR" "$f:5: error ADV003"
  check "caminho-espaco-acento: exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
  check "caminho-espaco-acento: snapshot removido" snap_empty
  check "caminho-espaco-acento: caminho exato na lista" pending_has "$f"
}

case_fffd() {
  local d="$TMP_DIR/$MODE/fffd" f g ctx
  mkdir -p "$d"; f="$d/FATA004.prw"; g="$d/FATA005.prw"
  new_session fffd
  pre "$f" Write
  printf '#include "totvs.ch"\n\nUser Function FATA004()\n\tLocal cMsg := "importa%s%so"\nReturn cMsg\n' "$FFFD" "$FFFD" >"$f"
  post "$f" Write
  check "fffd: exit 2" [ "$RC" = 2 ]
  check "fffd: stderr cita ADV014 na linha 4" contains "$ERR" "FATA004.prw:4: error ADV014"
  check "fffd: conversao pulada (bytes EF BF BD mantidos)" has_bytes "$FFFD" "$f"
  check "fffd: stderr avisa que a conversao foi pulada" contains "$ERR" "conversao para Windows-1252 nao executada"
  check "fffd: sem o aviso de '?' (o U+FFFD nao e transliterado)" lacks "$ERR" "viram '?'"
  check "fffd: snapshot removido" snap_empty
  # U+FFFD already in the file before the edit is legacy debt: not reported,
  # only the non-blocking note that the conversion was skipped
  printf '#include "totvs.ch"\n\nUser Function FATA005()\n\tLocal cMsg := "importa%so"\n\tLocal nX := 0\nReturn cMsg\n' "$FFFD" >"$g"
  pre "$g"
  set_line "$g" 5 "$(printf '\tLocal nX := 1')"
  post "$g"
  ctx="$(json_context "$OUT")"
  check "fffd-legado: exit 0" [ "$RC" = 0 ]
  check "fffd-legado: sem stderr" [ -z "$ERR" ]
  check "fffd-legado: JSON valido" valid_hook_json "$OUT"
  check "fffd-legado: contexto avisa conversao pulada" contains "$ctx" "conversao para Windows-1252 nao executada"
  check "fffd-legado: sem o aviso de '?'" lacks "$ctx" "viram '?'"
  check "fffd-legado: nenhum achado do lint" [ "$(finding_count "$ctx")" = 0 ]
  check "fffd-legado: U+FFFD legado nao e transliterado" has_bytes "$FFFD" "$g"
  # end of the turn: both files listed, neither converted (U+FFFD stays
  # visible to ADV014), the user is told why
  check "fffd: os dois arquivos na lista" [ "$(pending_count)" = 2 ]
  stop_hook Stop
  check "fffd-stop: exit 0 sem stderr" [ "$RC$ERR" = 0 ]
  check "fffd-stop: JSON valido (so systemMessage)" valid_stop_json "$OUT"
  check "fffd-stop: systemMessage cita o arquivo novo" contains "$SYS" "nao executada em $f"
  check "fffd-stop: systemMessage cita o arquivo legado" contains "$SYS" "nao executada em $g"
  check "fffd-stop: systemMessage cita U+FFFD" contains "$SYS" "U+FFFD"
  check "fffd-stop: U+FFFD mantido no arquivo novo" has_bytes "$FFFD" "$f"
  check "fffd-stop: U+FFFD mantido no legado" has_bytes "$FFFD" "$g"
  check "fffd-stop: lista removida" pending_gone
}

case_legado_utf8() {
  # legacy files never converted (still UTF-8, maybe with BOM): the snapshot is
  # normalized like the file, so untouched accented/BOM lines are not "introduced"
  local d="$TMP_DIR/$MODE/legado-utf8" f g h
  mkdir -p "$d"; f="$d/FATA010.prw"; g="$d/FATA011.PRW"; h="$d/defs.th"
  new_session legado-utf8
  printf '#include "totvs.ch"\n\nUser Function FATA010()\n\tLocal nX := 0\n\tConOut("In\303\255cio da importa\303\247\303\243o")\nReturn nX\n' >"$f"
  pre "$f"
  set_line "$f" 4 "$(printf '\tLocal nX := 1')"
  post "$f"
  check "legado-utf8: exit 0" [ "$RC" = 0 ]
  check "legado-utf8: sem saida (ConOut legado acentuado nao acusado)" [ -z "$OUT$ERR" ]
  check "legado-utf8: Edit em UTF-8 com acentos fica UTF-8 depois do post" has_bytes "$UTF8_ACENTO" "$f"
  check "legado-utf8: e entra na lista" pending_has "$f"
  check "legado-utf8: snapshot e copias removidos" snap_empty
  # UTF-8 with BOM, editor kept the BOM: the end of the turn strips it
  printf '\357\273\277#Include "Protheus.ch"\n\nUser Function FATA011()\n\tLocal cMsg := "a\303\247\303\243o"\n\tLocal nX := 0\nReturn cMsg\n' >"$g"
  pre "$g"
  set_line "$g" 5 "$(printf '\tLocal nX := 1')"
  post "$g"
  check "legado-utf8-bom: exit 0" [ "$RC" = 0 ]
  check "legado-utf8-bom: sem saida (#Include Protheus.ch legado nao acusado)" [ -z "$OUT$ERR" ]
  check "legado-utf8-bom: snapshot e copias removidos" snap_empty
  # .th with BOM, editor dropped the BOM: both sides go through the converter
  # (BOM stripped), so line 1 still matches
  printf '\357\273\277#Include "Protheus.ch"\n#define CMSG "x"\n' >"$h"
  pre "$h"
  printf '#Include "Protheus.ch"\n#define CMSG "y"\n' >"$h"
  post "$h"
  check "legado-bom-removido (.th): exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "legado-bom-removido (.th): snapshot removido" snap_empty
  stop_hook Stop
  check "legado-utf8: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "legado-utf8: Stop converte para CP1252" has_bytes "$CP_ACENTO" "$f"
  check "legado-utf8-bom: Stop remove o BOM" lacks_bytes "$(printf '\357\273\277')" "$g"
  check "legado-utf8-bom: Stop converte para CP1252" has_bytes "$CP_ACENTO" "$g"
}

case_translit() {
  # emoji in a comment: an immediate non-blocking warning (it becomes "?" at
  # the end of the turn, replace it now); the Stop transliterates it and
  # tells the user with the converter's translit: line
  local d="$TMP_DIR/$MODE/translit" f ctx
  mkdir -p "$d"; f="$d/FATA012.prw"
  new_session translit
  pre "$f" Write
  printf '#include "totvs.ch"\n\n// lan\303\247amento \360\237\232\200\nUser Function FATA012()\nReturn Nil\n' >"$f"
  post "$f" Write
  check "translit: exit 0" [ "$RC" = 0 ]
  check "translit: sem stderr" [ -z "$ERR" ]
  check "translit: JSON valido" valid_hook_json "$OUT"
  ctx="$(json_context "$OUT")"
  check "translit: aviso imediato cita o arquivo" contains "$ctx" "$f tem caracteres sem representacao em Windows-1252"
  check "translit: aviso diz que viram '?' no fim do turno" contains "$ctx" "no fim do turno"
  check "translit: aviso pede a troca agora" contains "$ctx" "Troque-os agora"
  check "translit: arquivo intocado ate o fim do turno (emoji em UTF-8)" has_bytes "$(printf '\360\237\232\200')" "$f"
  check "translit: snapshot removido" snap_empty
  stop_hook Stop
  check "translit-stop: exit 0 sem stderr" [ "$RC$ERR" = 0 ]
  check "translit-stop: JSON valido (so systemMessage)" valid_stop_json "$OUT"
  check "translit-stop: systemMessage traz a linha translit: com a contagem" contains "$SYS" "translit: $f (1)"
  check "translit-stop: systemMessage pede revisao dos '?'" contains "$SYS" "viraram '?'"
  check "translit-stop: emoji virou ? e acento em CP1252" has_bytes "$(printf 'lan\347amento ?')" "$f"
  check "translit-stop: sem bytes UTF-8" lacks_bytes "$UTF8_ACENTO" "$f"
  check "translit-stop: lista removida" pending_gone
}

case_nao_advpl() {
  local d="$TMP_DIR/$MODE/nao-advpl" f c sum
  mkdir -p "$d"; f="$d/notas.txt"; c="$d/defs.ch"
  new_session nao-advpl
  printf 'ConOut("x")\n' >"$f"
  pre "$f"
  check "nao-advpl: pre nao cria snapshot" snap_empty
  printf 'ConOut("a\303\247\303\243o")\n' >>"$f"
  post "$f"
  check "nao-advpl: exit 0" [ "$RC" = 0 ]
  check "nao-advpl: sem saida" [ -z "$OUT$ERR" ]
  check "nao-advpl: fora da lista" not pending_has "$f"
  # .ch: listed and converted to CP1252 at the end of the turn, never linted
  pre "$c" Write
  printf '#define CMSG "importa\303\247\303\243o"\nConOut(CMSG)\n' >"$c"
  post "$c" Write
  check "ch: exit 0 e sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "ch: na lista" pending_has "$c"
  # a .txt listed by hand is skipped by the end of the turn
  printf '%s\n' "$f" >>"$PEND_DIR/$SID"
  sum="$(cksum <"$f")"
  stop_hook Stop
  check "ch: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "ch: Stop converte para CP1252" has_bytes "$CP_ACENTO" "$c"
  check "nao-advpl: Stop nao toca o .txt listado" [ "$(cksum <"$f")" = "$sum" ]
}

big_ops() {
  pre "$1"
  set_line "$1" 2500 "$(printf '\tConOut("x")')"
  post "$1"
}

case_arquivo_grande() {
  local d="$TMP_DIR/$MODE/grande" f elapsed max=2
  # Windows (Git Bash): process start-up dominates and CI runners vary, so the
  # bound there only catches a pathological slowdown.
  case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) max=30 ;; esac
  mkdir -p "$d"; f="$d/FATA006.prw"
  LC_ALL=C awk 'BEGIN {
    print "#include \"totvs.ch\""
    for (i = 1; i <= 1000; i++)
      printf "User Function F%04d()\n\tLocal nX := 0\n\tnX := nX + %d\n\tReturn nX\n\n", i, i
  }' >"$f"
  check "arquivo-grande: 5001 linhas" [ "$(wc -l <"$f" | tr -d ' ')" = 5001 ]
  TIMEFORMAT='%R'
  { time big_ops "$f"; } 2>"$TMP_DIR/time.txt"
  elapsed="$(tail -n 1 "$TMP_DIR/time.txt")"
  echo "       arquivo-grande: pre+post em ${elapsed}s"
  check "arquivo-grande: exit 2" [ "$RC" = 2 ]
  check "arquivo-grande: acusa so a linha 2500" contains "$ERR" "FATA006.prw:2500: error ADV003"
  check "arquivo-grande: exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
  check "arquivo-grande: < $max s" awk -v t="$elapsed" -v m="$max" 'BEGIN { exit !(t + 0 < m + 0) }'
}

valid_hook_json() { # strict shape check of the PostToolUse JSON on stdout
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -e '(keys == ["hookSpecificOutput"])
      and (.hookSpecificOutput.hookEventName == "PostToolUse")
      and (.hookSpecificOutput.additionalContext | type == "string")' >/dev/null
  else
    printf '%s\n' "$1" | LC_ALL=C grep -Eq '^\{"hookSpecificOutput":\{"hookEventName":"PostToolUse","additionalContext":"([^"\\]|\\["\\/bfnrt]|\\u[0-9a-f]{4})*"\}\}$' &&
      [ "$(printf '%s\n' "$1" | wc -l | tr -d ' ')" = 1 ]
  fi
}

valid_stop_json() { # strict shape check of the Stop JSON: systemMessage only
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -e '(keys == ["systemMessage"]) and (.systemMessage | type == "string")' >/dev/null
  else
    printf '%s\n' "$1" | LC_ALL=C grep -Eq '^\{"systemMessage":"([^"\\]|\\["\\/bfnrt]|\\u[0-9a-f]{4})*"\}$' &&
      [ "$(printf '%s\n' "$1" | wc -l | tr -d ' ')" = 1 ]
  fi
}

json_context() { json_string .hookSpecificOutput.additionalContext additionalContext "$1"; }

# json_string FILTER KEY JSON: the string at the jq FILTER, decoded (without
# jq: the first "KEY" key, \uXXXX kept)
json_string() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$3" | jq -r "$1 // empty" 2>/dev/null
  else
    printf '%s\n' "$3" | KEY="$2" LC_ALL=C awk '
      match($0, "\"" ENVIRON["KEY"] "\":\"") {
        s = substr($0, RSTART + RLENGTH); n = length(s); out = ""
        for (i = 1; i <= n; i++) {
          c = substr(s, i, 1)
          if (c == "\"") break
          if (c == "\\") {
            c = substr(s, ++i, 1)
            if (c == "n") c = "\n"; else if (c == "t") c = "\t"
            else if (c == "r") c = "\r"; else if (c == "u") c = "\\u"
          }
          out = out c
        }
        print out
      }'
  fi
}

case_somente_avisos() {
  # name with a double quote and a backslash: the JSON must escape both
  local d="$TMP_DIR/$MODE/avisos" f ctx
  mkdir -p "$d"; f="$d/aspas\"e\\barra.prw"
  new_session somente-avisos
  printf '#include "totvs.ch"\n\nUser Function FATA007()\n\tLocal nX := 0\n\tLocal lOk := .T.\nReturn nX\n' >"$f"
  pre "$f"
  insert_after "$f" 5 "$(printf '\tnX := IIf(lOk, 1, 2)')"
  post "$f"
  check "somente-avisos: exit 0" [ "$RC" = 0 ]
  check "somente-avisos: sem stderr" [ -z "$ERR" ]
  check "somente-avisos: JSON valido em stdout" valid_hook_json "$OUT"
  ctx="$(json_context "$OUT")"
  check "somente-avisos: contexto cita ADV009 na linha 6" contains "$ctx" ":6: warning ADV009"
  check "somente-avisos: aspas e barra escapadas" contains "$OUT" 'aspas\"e\\barra.prw'
  check "somente-avisos: snapshot removido" snap_empty
  check "somente-avisos: caminho com aspas e barra na lista" pending_has "$f"
}

case_tlpp() {
  local d="$TMP_DIR/$MODE/tlpp" f g
  mkdir -p "$d"; f="$d/Servico.tlpp"; g="$d/Legado.tlpp"
  # stale snapshot from an earlier failed call must not turn the Write into a diff
  mkdir -p "$SNAP_DIR"
  printf 'namespace custom.teste.servico\n' >"$SNAP_DIR/$(snap_key "$f")"
  pre "$f" Write
  check "tlpp-novo: pre remove snapshot obsoleto" snap_empty
  printf 'namespace custom.teste.servico\n\nclass Servico\n\tpublic method new() constructor\nendclass\n\nmethod new() class Servico\nreturn self\n' >"$f"
  post "$f" Write
  check "tlpp-novo: exit 0" [ "$RC" = 0 ]
  check "tlpp-novo: JSON valido" valid_hook_json "$OUT"
  check "tlpp-novo: ADV019 (escopo file) roda em arquivo novo" contains "$(json_context "$OUT")" "Servico.tlpp:1: warning ADV019"
  # editing an existing .tlpp: file-scope rules stay off
  printf 'namespace custom.teste.legado\n\nclass Legado\n\tpublic method new() constructor\nendclass\n\nmethod new() class Legado\nreturn self\n' >"$g"
  pre "$g"
  insert_after "$g" 7 "$(printf '\tLocal nX := 0')"
  post "$g"
  check "tlpp-edicao: exit 0 sem ADV019" [ "$RC$OUT$ERR" = 0 ]
}

case_ignore() {
  local d="$TMP_DIR/$MODE/ignore" f
  mkdir -p "$d"; f="$d/FATA008.prw"
  printf '# falso positivo aceito\nrule ADV003\n' >"$d/.advpl-specialist-ignore"
  printf '#include "totvs.ch"\n\nUser Function FATA008()\nReturn Nil\n' >"$f"
  pre "$f"
  insert_after "$f" 3 "$(printf '\tConOut("ok")')"
  CLAUDE_PROJECT_DIR="$d" post "$f"
  check "ignore: ADV003 suprimido pelo .advpl-specialist-ignore do projeto" [ "$RC$OUT$ERR" = 0 ]
}

case_sem_mudanca() {
  local d="$TMP_DIR/$MODE/sem-mudanca" f
  mkdir -p "$d"; f="$d/FATA009.prw"
  legacy_cp1252 "$f"
  pre "$f"
  post "$f"
  check "sem-linhas-introduzidas: exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "sem-linhas-introduzidas: snapshot removido" snap_empty
}

# --- PostToolUse(Read): hint for editing a Windows-1252 source ----------------

# read_json PATH: PostToolUse payload of a Read with offset/limit; the content
# in tool_response carries an escaped "file_path" decoy.
read_json() {
  local p; p="$(json_quote "$1")"
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"PostToolUse","tool_name":"Read","tool_input":{"offset":1,"limit":50,"file_path":"%s"},"tool_response":{"type":"text","file":{"filePath":"%s","content":"say \\"file_path\\": \\"/decoy.prw\\"\\n","numLines":1,"startLine":1,"totalLines":13}}}' \
    "$(json_quote "$SID")" "$(json_quote "$TMP_DIR")" "$p" "$p"
}

# read_hook PATH: run post-tool-use-read; sets RC, OUT, ERR and CTX (decoded
# additionalContext)
read_hook() {
  read_json "$1" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$READ" >"$TMP_DIR/read.out" 2>"$TMP_DIR/read.err"
  RC=$?
  OUT="$(cat "$TMP_DIR/read.out")"
  ERR="$(cat "$TMP_DIR/read.err")"
  CTX="$(json_context "$OUT")"
}

no_hint() { [ "$RC" = 0 ] && [ -z "$OUT$ERR" ]; }
has_line() { printf '%s\n' "$1" | grep -qxF -- "$2"; }
# to_utf8_line FILE: the --to-utf8 command line the hint must carry for FILE
to_utf8_line() { printf 'bash "%s" --to-utf8 "%s"' "$CONV" "$1"; }

# run_hint to-utf8|back: runs the matching command line of $CTX the way a
# shell reads it; sets CMD_OUT, returns the command's exit status
run_hint() {
  local cmd
  CMD_OUT=""
  if [ "$1" = to-utf8 ]; then
    cmd="$(printf '%s\n' "$CTX" | grep -- '^bash .* --to-utf8 ' | head -n 1)"
  else
    cmd="$(printf '%s\n' "$CTX" | grep '^bash ' | grep -v -- ' --to-utf8 ' | head -n 1)"
  fi
  [ -n "$cmd" ] || return 1
  CMD_OUT="$(cd "$TMP_DIR" && eval "$cmd" 2>&1)"
}

# is_cp1252 FILE: not valid UTF-8, every byte defined in Windows-1252
is_cp1252() { [ "$("$HOOK_BASH" "$CONV" --dry-run --to-utf8 -- "$1")" = "converted: $1" ]; }
# same_except_line A B "N...": same line count and same bytes outside the
# lines N (space-separated)
same_except_line() {
  local skip='BEGIN { k = split(n, a, " "); for (i = 1; i <= k; i++) s[a[i]] = 1 } !(NR in s)'
  [ "$(wc -l <"$1")" = "$(wc -l <"$2")" ] &&
    LC_ALL=C awk -v n="$3" "$skip" "$1" >"$TMP_DIR/a.cmp" &&
    LC_ALL=C awk -v n="$3" "$skip" "$2" >"$TMP_DIR/b.cmp" &&
    cmp -s "$TMP_DIR/a.cmp" "$TMP_DIR/b.cmp"
}
line_is() { [ "$(LC_ALL=C sed -n "$2p" "$1")" = "$3" ]; }

case_read_dica() {
  local d="$TMP_DIR/$MODE/read-dica" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  new_session read-dica
  legacy_cp1252 "$f"; cp "$f" "$d/original"
  # an Edit of the same file in flight (parallel tool calls): the Read must
  # not touch its snapshot
  pre "$f"
  read_hook "$f"
  check "read-dica: exit 0" [ "$RC" = 0 ]
  check "read-dica: sem stderr" [ -z "$ERR" ]
  check "read-dica: JSON valido" valid_hook_json "$OUT"
  check "read-dica: comando exato com --to-utf8 e o caminho" has_line "$CTX" "$(to_utf8_line "$f")"
  check "read-dica: comando de volta (sem --to-utf8)" has_line "$CTX" "bash \"$CONV\" \"$f\""
  check "read-dica: explica a recusa do Edit/Write" contains "$CTX" "Edit/Write do Claude Code recusa"
  check "read-dica: pede nova leitura antes do Edit" contains "$CTX" "leia o arquivo de novo"
  check "read-dica: edite a vontade" contains "$CTX" "edite a vontade"
  check "read-dica: lint de cada edicao e reconversao no fim do turno" \
    contains "$CTX" "faz o lint de cada edicao (so das linhas introduzidas) e reconverte o arquivo para Windows-1252 no fim do turno"
  check "read-dica: sem Bash (subagente), devolve o caminho a quem chamou" \
    contains "$CTX" "Sem a ferramenta Bash (subagente), nao converta: devolva o caminho do arquivo a quem chamou"
  check "read-dica: desistir = conversor sem --to-utf8" contains "$CTX" "rode o mesmo script sem --to-utf8"
  check "read-dica: nao editar com sed" contains "$CTX" "Nao edite com sed"
  check "read-dica: arquivo intocado (dry-run)" cmp -s "$f" "$d/original"
  check "read-dica: snapshot do Edit em curso preservado" [ -f "$SNAP_DIR/$(snap_key "$f")" ]
  check "read-dica: arquivo entra na lista de pendentes" pending_has "$f"
  rm -f "$SNAP_DIR/$(snap_key "$f")"
  legacy_cp1252 "$d/Servico.TLPP"; legacy_cp1252 "$d/defs.th"
  read_hook "$d/Servico.TLPP"
  check "read-dica: .TLPP" has_line "$CTX" "$(to_utf8_line "$d/Servico.TLPP")"
  read_hook "$d/defs.th"
  check "read-dica: .th" has_line "$CTX" "$(to_utf8_line "$d/defs.th")"
  read_hook "$f"
  check "read-dica: tres arquivos na lista, sem repeticao" [ "$(pending_count)" = 3 ]
}

case_read_caminho() {
  # space, UTF-8 accent, " and $ in the path: the hint commands are
  # double-quoted shell words that run as written
  local d f q
  d="$TMP_DIR/$MODE/read caminho/jo$(printf '\303\243')o/aspas\"e\$x"
  mkdir -p "$d"; f="$d/FATA001.PRW"
  legacy_cp1252 "$f"; cp "$f" "$TMP_DIR/$MODE/read-caminho.original"
  q="$TMP_DIR/$MODE/read caminho/jo$(printf '\303\243')o/aspas\\\"e\\\$x/FATA001.PRW"
  read_hook "$f"
  check "read-caminho: aspas e cifrao escapados no comando" has_line "$CTX" "bash \"$CONV\" --to-utf8 \"$q\""
  check "read-caminho: o comando da dica roda" run_hint to-utf8
  check "read-caminho: converted: do caminho certo" [ "$CMD_OUT" = "converted: $f" ]
  check "read-caminho: arquivo em UTF-8" has_bytes "$UTF8_ACENTO" "$f"
  check "read-caminho: o comando de volta roda" run_hint back
  check "read-caminho: volta reporta converted:" [ "$CMD_OUT" = "converted: $f" ]
  check "read-caminho: bytes de volta identicos ao original" cmp -s "$f" "$TMP_DIR/$MODE/read-caminho.original"
}

case_read_sem_dica() {
  local d="$TMP_DIR/$MODE/read-sem-dica" r
  mkdir -p "$d"
  new_session read-sem-dica
  printf '#include "totvs.ch"\n\nUser Function FATA010()\n\tConOut("In\303\255cio da importa\303\247\303\243o")\nReturn Nil\n' >"$d/utf8.prw"
  printf '#include "totvs.ch"\n\nUser Function FATA011()\nReturn Nil\n' >"$d/ascii.prw"
  legacy_cp1252 "$d/notas.txt"
  legacy_cp1252 "$d/defs.ch"
  # 0x81 is undefined in Windows-1252: --to-utf8 cannot convert it
  printf 'User Function FATA012()\n\tLocal c := "\201\347"\nReturn c\n' >"$d/indefinido.prw"
  for r in utf8.prw ascii.prw notas.txt defs.ch indefinido.prw inexistente.prw; do
    read_hook "$d/$r"
    check "read-sem-dica: $r" no_hint
  done
  printf '{"hook_event_name":"PostToolUse","tool_name":"Read","tool_input":{}}' |
    ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$READ" >"$TMP_DIR/read.out" 2>&1
  check "read-sem-dica: payload sem file_path" [ "$?$(cat "$TMP_DIR/read.out")" = 0 ]
  check "read-sem-dica: sem dica, nada na lista" pending_gone
}

case_read_plugin() {
  # files of the plugin itself (fixtures) never get the hint
  local d="$TMP_DIR/$MODE/read-plugin" fx="$ROOT/examples/encoding-tests/fixtures/05-already-cp1252.prw" sum
  new_session read-plugin
  check "read-plugin: a fixture do plugin e CP1252" is_cp1252 "$fx"
  sum="$(cksum <"$fx")"
  read_hook "$fx"
  check "read-plugin: fixture CP1252 do plugin sem dica" no_hint
  check "read-plugin: fixture intocada" [ "$(cksum <"$fx")" = "$sum" ]
  mkdir -p "$d/plugin/fixtures" "$d/plugin-x"
  legacy_cp1252 "$d/plugin/fixtures/FATA001.prw"; legacy_cp1252 "$d/plugin-x/FATA001.prw"
  CLAUDE_PLUGIN_ROOT="$d/plugin" read_hook "$d/plugin/fixtures/FATA001.prw"
  check "read-plugin: arquivo sob CLAUDE_PLUGIN_ROOT sem dica" no_hint
  CLAUDE_PLUGIN_ROOT="$d/plugin" read_hook "$d/plugin-x/FATA001.prw"
  check "read-plugin: irmao com o mesmo prefixo recebe a dica" has_line "$CTX" "$(to_utf8_line "$d/plugin-x/FATA001.prw")"
  check "read-plugin: so o irmao entra na lista" [ "$(cat "$PEND_DIR/$SID" 2>/dev/null)" = "$d/plugin-x/FATA001.prw" ]
}

case_read_erro_interno() {
  # a failing converter (stderr, exit 3) never surfaces in the Read
  local d="$TMP_DIR/$MODE/read-erro" s
  s="$d/root/skills/advpl-code-generation/scripts"
  mkdir -p "$s"
  new_session read-erro-interno
  printf '#!/bin/sh\necho "boom" >&2\nexit 3\n' >"$s/convert-encoding.sh"
  legacy_cp1252 "$d/FATA001.prw"
  CLAUDE_PLUGIN_ROOT="$d/root" read_hook "$d/FATA001.prw"
  check "read-erro-interno: silencio e exit 0" no_hint
  check "read-erro-interno: nada na lista" pending_gone
}

case_read_ida_volta() {
  # the whole flow with the real hook scripts: Read hint, --to-utf8 from the
  # hint, two Edits (pre-tool-use + post-tool-use each) while the file stays
  # UTF-8, then Stop
  local d="$TMP_DIR/$MODE/read-ida-volta" f o ctx
  mkdir -p "$d"; f="$d/FATA001.prw"; o="$d/original"
  new_session ida-volta
  legacy_cp1252 "$f"; cp "$f" "$o"
  read_hook "$f"
  check "ida-volta: o Read da a dica" has_line "$CTX" "$(to_utf8_line "$f")"
  check "ida-volta: o Read poe o arquivo na lista" pending_has "$f"
  check "ida-volta: o comando da dica roda" run_hint to-utf8
  check "ida-volta: converted: $f" [ "$CMD_OUT" = "converted: $f" ]
  check "ida-volta: arquivo em UTF-8" has_bytes "$UTF8_ACENTO" "$f"
  read_hook "$f"
  check "ida-volta: novo Read (ja UTF-8) sem dica" no_hint
  # first Edit: an accented line, nothing to report (IIf l.10, ConOut l.11 legacy)
  pre "$f"
  set_line "$f" 12 "$(printf '\tnY := nX + 2 // revis\303\243o')"
  post "$f"
  check "ida-volta: 1o Edit exit 0 sem saida (IIf e ConOut legados quietos)" [ "$RC$OUT$ERR" = 0 ]
  check "ida-volta: arquivo continua UTF-8 para o 2o Edit" has_bytes "$UTF8_ACENTO" "$f"
  check "ida-volta: snapshot removido" snap_empty
  # second Edit of the same file, without a new Read nor --to-utf8: a new IIf
  pre "$f"
  set_line "$f" 9 "$(printf '\tLocal nY := IIf(nX > 0, 1, 0) // padr\303\243o')"
  post "$f"
  ctx="$(json_context "$OUT")"
  check "ida-volta: 2o Edit exit 0 sem stderr" [ "$RC$ERR" = 0 ]
  check "ida-volta: 2o Edit JSON valido" valid_hook_json "$OUT"
  check "ida-volta: 2o Edit acusa o IIf novo (linha 9)" contains "$ctx" "FATA001.prw:9: warning ADV009"
  check "ida-volta: 2o Edit exatamente 1 achado (IIf legado l.10 nunca)" [ "$(finding_count "$ctx")" = 1 ]
  check "ida-volta: uma entrada na lista (Read + 2 Edits)" [ "$(pending_count)" = 1 ]
  stop_hook Stop
  check "ida-volta: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "ida-volta: arquivo final em Windows-1252" is_cp1252 "$f"
  check "ida-volta: linha 9 em Windows-1252" line_is "$f" 9 "$(printf '\tLocal nY := IIf(nX > 0, 1, 0) // padr\343o')"
  check "ida-volta: linha 12 em Windows-1252" line_is "$f" 12 "$(printf '\tnY := nX + 2 // revis\343o')"
  check "ida-volta: bytes fora das linhas 9 e 12 identicos ao original" same_except_line "$f" "$o" "9 12"
  check "ida-volta: lista removida" pending_gone
}

case_read_sem_conversao() {
  # Read of a Windows-1252 source, no --to-utf8, then Stop: bytes untouched
  local d="$TMP_DIR/$MODE/read-stop" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  new_session read-stop
  legacy_cp1252 "$f"; cp "$f" "$d/original"
  read_hook "$f"
  check "read-stop: dica e lista" pending_has "$f"
  stop_hook Stop
  check "read-stop: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "read-stop: arquivo CP1252 com bytes identicos" cmp -s "$f" "$d/original"
  check "read-stop: lista removida" pending_gone
}

case_tres_edits() {
  # three Edits of a UTF-8 source (converted with --to-utf8): each one lints
  # only the lines it introduced, the list keeps one entry, the file stays
  # UTF-8 (Edit accepts it) until the end of the turn
  local d="$TMP_DIR/$MODE/tres-edits" f ctx
  mkdir -p "$d"; f="$d/FATA001.prw"
  new_session tres-edits
  legacy_cp1252 "$f"; cp "$f" "$d/original"
  "$HOOK_BASH" "$CONV" --to-utf8 -- "$f" >/dev/null
  pre "$f"
  insert_after "$f" 9 "$(printf '\tConOut("um")')"
  post "$f"
  check "tres-edits: 1o Edit exit 2" [ "$RC" = 2 ]
  check "tres-edits: 1o Edit acusa a linha 10" contains "$ERR" "FATA001.prw:10: error ADV003"
  check "tres-edits: 1o Edit exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
  check "tres-edits: UTF-8 depois do 1o Edit" has_bytes "$UTF8_ACENTO" "$f"
  pre "$f"
  set_line "$f" 10 "$(printf '\tnX := IIf(nY > 0, 3, 4) // edi\303\247\303\243o')"
  post "$f"
  ctx="$(json_context "$OUT")"
  check "tres-edits: 2o Edit exit 0" [ "$RC" = 0 ]
  check "tres-edits: 2o Edit acusa o IIf da linha 10" contains "$ctx" "FATA001.prw:10: warning ADV009"
  check "tres-edits: 2o Edit exatamente 1 achado (IIf legado l.11 fora)" [ "$(finding_count "$ctx")" = 1 ]
  pre "$f"
  insert_after "$f" 13 "$(printf '\tConOut("tr\303\252s")')"
  post "$f"
  check "tres-edits: 3o Edit exit 2" [ "$RC" = 2 ]
  check "tres-edits: 3o Edit acusa a linha 14" contains "$ERR" "FATA001.prw:14: error ADV003"
  check "tres-edits: 3o Edit exatamente 1 achado (IIf do 2o Edit fora)" [ "$(finding_count "$ERR")" = 1 ]
  check "tres-edits: UTF-8 depois do 3o Edit" has_bytes "$UTF8_ACENTO" "$f"
  check "tres-edits: uma entrada na lista" [ "$(pending_count)" = 1 ]
  check "tres-edits: a entrada e o arquivo" pending_has "$f"
  check "tres-edits: snapshot removido" snap_empty
  stop_hook Stop
  check "tres-edits: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "tres-edits: Windows-1252 depois do Stop" is_cp1252 "$f"
  check "tres-edits: linhas 1-9 identicas ao original" \
    [ "$(LC_ALL=C sed -n '1,9p' "$f" | cksum)" = "$(LC_ALL=C sed -n '1,9p' "$d/original" | cksum)" ]
}

case_stop() {
  # Stop and SessionEnd with lists written by hand: bytes checked against the
  # expected Windows-1252 files
  local d="$TMP_DIR/$MODE/stop" a b e gone sid
  mkdir -p "$d"; a="$d/FATA020.prw"; b="$d/defs.ch"; e="$d/FATA022.tlpp"; gone="$d/FATA021.prw"
  new_session stop
  utf8_pair() {
    printf '#include "totvs.ch"\n// importa\303\247\303\243o\nReturn\n' >"$a"
    printf '#define CMSG "a\303\247\303\243o"\n' >"$b"
  }
  printf '#include "totvs.ch"\n// importa\347\343o\nReturn\n' >"$d/a.esperado"
  printf '#define CMSG "a\347\343o"\n' >"$d/b.esperado"
  utf8_pair
  pending_set "$a" "$gone" "$b" "$a"
  stop_hook Stop "[$T_SUBAGENT]"
  check "stop-ocupado: exit 0 sem stderr" [ "$RC$ERR" = 0 ]
  check "stop-ocupado: JSON valido (so systemMessage)" valid_stop_json "$OUT"
  check "stop-ocupado: avisa os 2 fontes ainda em UTF-8" \
    contains "$SYS" "2 fonte(s) ainda em UTF-8; a reconversao para Windows-1252 ocorre quando as tarefas em segundo plano terminarem"
  check "stop-ocupado: nada convertido" has_bytes "$UTF8_ACENTO" "$a"
  check "stop-ocupado: .ch tambem nao" has_bytes "$UTF8_ACENTO" "$b"
  check "stop-ocupado: lista mantida" [ "$(pending_count)" = 4 ]
  stop_hook SubagentStop
  check "subagentstop: nada convertido, lista mantida" [ "$RC$OUT$ERR$(pending_count)" = 04 ]
  stop_hook Stop
  check "stop-vazio: exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "stop-vazio: .prw convertido (bytes conferidos)" cmp -s "$a" "$d/a.esperado"
  check "stop-vazio: .ch convertido (bytes conferidos)" cmp -s "$b" "$d/b.esperado"
  check "stop-vazio: pendente apagado foi pulado (nada criado)" [ ! -e "$gone" ]
  check "stop-vazio: lista removida" pending_gone
  stop_hook Stop
  check "stop-sem-lista: exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  # background_tasks absent: same as empty
  utf8_pair; pending_set "$a"
  stop_hook Stop absent
  check "stop-sem-background_tasks: convertido" cmp -s "$a" "$d/a.esperado"
  check "stop-sem-background_tasks: lista removida" pending_gone
  # SessionEnd: converts; the translit note goes to stderr only
  utf8_pair; printf '// foguete \360\237\232\200\n' >"$e"
  pending_set "$a" "$e"
  stop_hook SessionEnd
  check "sessionend: exit 0 sem stdout" [ "$RC$OUT" = 0 ]
  check "sessionend: convertido" cmp -s "$a" "$d/a.esperado"
  check "sessionend: emoji virou ?" [ "$(cat "$e")" = "// foguete ?" ]
  check "sessionend: translit: no stderr" contains "$ERR" "translit: $e (1)"
  check "sessionend: lista removida" pending_gone
  # another session's list is not touched
  utf8_pair; pending_set "$a"; sid="$SID"
  SID="$sid-outra"
  stop_hook Stop
  SID="$sid"
  check "stop-outra-sessao: lista e arquivo intocados" [ "$(pending_count)" = 1 ]
  check "stop-outra-sessao: arquivo ainda UTF-8" has_bytes "$UTF8_ACENTO" "$a"
  rm -f "$PEND_DIR/$SID"
}

case_sessao() {
  # session_id becomes a file name: anything outside [A-Za-z0-9_-] turns into
  # "_", so "../s p" stays inside the pending directory
  local d="$TMP_DIR/$MODE/sessao" f saved="$SID"
  mkdir -p "$d"; f="$d/FATA030.prw"
  SID='../s p'
  rm -f "$PEND_DIR/___s_p"
  pre "$f" Write
  printf '#include "totvs.ch"\n// importa\303\247\303\243o\nReturn\n' >"$f"
  post "$f" Write
  check "sessao: id saneado (___s_p)" grep -qxF -- "$f" "$PEND_DIR/___s_p"
  check "sessao: nada fora do diretorio de pendentes" [ ! -e "$CLAUDE_PLUGIN_DATA/s p" ]
  stop_hook Stop
  check "sessao: Stop com o mesmo id converte" has_bytes "$CP_ACENTO" "$f"
  check "sessao: lista saneada removida" [ ! -e "$PEND_DIR/___s_p" ]
  SID="$saved"
}

case_stop_tarefas() {
  # only agent work in background_tasks defers the conversion; shell, monitor
  # and MCP task entries do not; a missing or unknown type counts as agent
  local d="$TMP_DIR/$MODE/stop-tarefas" f c t
  mkdir -p "$d"; f="$d/FATA050.prw"; c="$d/FATA051.prw"
  new_session stop-tarefas
  utf8_one() { printf '// importa\303\247\303\243o\n' >"$f"; pending_set "$f"; }
  utf8_one
  stop_hook Stop "[$T_SHELL]"
  check "tarefas-shell: exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "tarefas-shell: so shell converte" has_bytes "$CP_ACENTO" "$f"
  check "tarefas-shell: lista removida" pending_gone
  utf8_one
  stop_hook Stop '[{"id":"m1","type":"monitor","status":"running","command":"tail -f x"},{"id":"p1","type":"MCP task","status":"running","server":"s","tool":"t"}]'
  check "tarefas-monitor-mcp: converte" has_bytes "$CP_ACENTO" "$f"
  for t in "$T_SUBAGENT" '{"id":"t1","type":"teammate"}' '{"id":"w1","type":"workflow","name":"w"}' \
    '{"id":"c1","type":"cloud session"}' '{"id":"x1","status":"running"}' '{"id":"u1","type":"novo-tipo"}' \
    "$T_SHELL,$T_SUBAGENT"; do
    utf8_one
    stop_hook Stop "[$t]"
    check "tarefas-adia ($t): exit 0 sem stderr" [ "$RC$ERR" = 0 ]
    check "tarefas-adia ($t): systemMessage com 1 fonte" contains "$SYS" "1 fonte(s) ainda em UTF-8"
    check "tarefas-adia ($t): nada convertido, lista mantida" has_bytes "$UTF8_ACENTO" "$f"
    check "tarefas-adia ($t): lista mantida" pending_has "$f"
  done
  # deferred with nothing in UTF-8 (only a Windows-1252 source listed): silent
  legacy_cp1252 "$c"; pending_set "$c"
  stop_hook Stop "[$T_SUBAGENT]"
  check "tarefas-adia-sem-utf8: exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "tarefas-adia-sem-utf8: lista mantida" pending_has "$c"
  rm -f "$PEND_DIR/$SID"
}

case_caminho_relativo() {
  # only absolute paths go on the list, and Stop never resolves a listed path
  # against its own working directory
  local d="$TMP_DIR/$MODE/relativo" a out
  mkdir -p "$d"; a="$d/FATA041.prw"
  new_session relativo
  printf '// importa\303\247\303\243o\n' >"$d/FATA040.prw"
  cd "$d" || return
  pre FATA040.prw Write
  post FATA040.prw Write
  cd "$TMP_DIR" || return
  check "relativo: post com caminho relativo nao entra na lista" pending_gone
  printf '// importa\303\247\303\243o\n' >"$a"
  pending_set FATA040.prw "$a"
  cd "$d" || return
  stop_hook Stop
  cd "$TMP_DIR" || return
  check "relativo: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "relativo: entrada relativa nao convertida no cwd do Stop" has_bytes "$UTF8_ACENTO" "$d/FATA040.prw"
  check "relativo: entrada absoluta convertida" has_bytes "$CP_ACENTO" "$a"
  check "relativo: lista removida" pending_gone
  # advpl_pending_add: absolute = "/..." or a Windows drive path "C:\..." / "c:/..."
  # shellcheck disable=SC2016 # $1, $p and $SID_JSON belong to the inner script
  out="$(SID_JSON="{\"session_id\":\"$SID\"}" ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" -c '
    . "$1"
    for p in "/abs/F.prw" "C:\\dir\\F.prw" "c:/dir/F.prw" "F.prw" "dir/F.prw" "C:F.prw" "\\\\srv\\s\\F.prw" "./F.prw"; do
      advpl_pending_add "$SID_JSON" "$p"
    done' _ "$POST" 2>&1)"
  check "relativo: advpl_pending_add sem saida" [ -z "$out" ]
  check "relativo: so caminhos absolutos (/ e unidade do Windows) na lista" \
    [ "$(cat "$PEND_DIR/$SID" 2>/dev/null)" = '/abs/F.prw
C:\dir\F.prw
c:/dir/F.prw' ]
  rm -f "$PEND_DIR/$SID"
}

case_stop_interrompido() {
  # a run killed mid-conversion (SessionEnd budget) leaves its work file
  # behind: the next Stop folds it in, converts its paths and removes it
  local d="$TMP_DIR/$MODE/interrompido" a b
  mkdir -p "$d" "$PEND_DIR"; a="$d/FATA060.prw"; b="$d/FATA061.prw"
  new_session interrompido
  printf '// importa\303\247\303\243o\n' >"$a"
  printf '%s\n' "$a" >"$PEND_DIR/$SID.4242"
  stop_hook Stop "[$T_SUBAGENT]"
  check "interrompido: adiado conta o arquivo de trabalho" contains "$SYS" "1 fonte(s) ainda em UTF-8"
  check "interrompido: adiado mantem o arquivo de trabalho" [ -f "$PEND_DIR/$SID.4242" ]
  stop_hook Stop
  check "interrompido: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "interrompido: caminho do arquivo de trabalho convertido" has_bytes "$CP_ACENTO" "$a"
  check "interrompido: arquivo de trabalho removido" [ ! -e "$PEND_DIR/$SID.4242" ]
  # a leftover and a fresh list together
  printf '// importa\303\247\303\243o\n' >"$a"; printf '// importa\303\247\303\243o\n' >"$b"
  printf '%s\n' "$a" >"$PEND_DIR/$SID.4243"; pending_set "$b"
  stop_hook SessionEnd
  check "interrompido+lista: os dois convertidos" has_bytes "$CP_ACENTO" "$a"
  check "interrompido+lista: lista nova convertida" has_bytes "$CP_ACENTO" "$b"
  check "interrompido+lista: nada sobra" pending_none
}

case_stop_fallback() {
  # the converter run over every file exits 2 (a path vanished meanwhile):
  # Stop goes one file at a time; the work file exists while the converter
  # runs and is removed only after
  local d="$TMP_DIR/$MODE/fallback" s a e
  s="$d/root/skills/advpl-code-generation/scripts"
  mkdir -p "$s"; a="$d/FATA070.prw"; e="$d/FATA071.prw"
  new_session fallback
  # shellcheck disable=SC2016 # $@, $a, $n belong to the generated wrapper
  printf '#!/bin/sh\nls "%s" | grep -c -F -- "%s." >>"%s/runs"\nn=0\nfor a in "$@"; do case $a in -*) ;; *) n=$((n + 1)) ;; esac; done\n[ "$n" -le 1 ] || { echo "convert-encoding: cannot read PATH: x" >&2; exit 2; }\nexec "%s" "%s" "$@"\n' \
    "$PEND_DIR" "$SID" "$d" "$HOOK_BASH" "$CONV" >"$s/convert-encoding.sh"
  printf '// importa\303\247\303\243o\n' >"$a"
  printf '// foguete \360\237\232\200\n' >"$e"
  pending_set "$a" "$e"
  CLAUDE_PLUGIN_ROOT="$d/root" stop_hook Stop
  check "fallback: exit 0 sem stderr" [ "$RC$ERR" = 0 ]
  check "fallback: 3 execucoes (1 com todos + 1 por arquivo)" [ "$(wc -l <"$d/runs" | tr -d ' ')" = 3 ]
  check "fallback: arquivo de trabalho presente em cada execucao" [ "$(sort -u "$d/runs")" = 1 ]
  check "fallback: .prw convertido" has_bytes "$CP_ACENTO" "$a"
  check "fallback: emoji convertido para ?" [ "$(cat "$e")" = "// foguete ?" ]
  check "fallback: systemMessage com o translit:" contains "$SYS" "translit: $e (1)"
  check "fallback: lista e arquivo de trabalho removidos depois" pending_none
}

case_fffd_cp1252() {
  # Windows-1252 file holding the bytes EF BF BD as legacy text: not U+FFFD
  # (the file is not UTF-8), so no notice, and the Stop leaves it as it is
  local d="$TMP_DIR/$MODE/fffd-cp1252" f
  mkdir -p "$d"; f="$d/FATA080.prw"
  new_session fffd-cp1252
  printf '#include "totvs.ch"\n// legado %s e a\347\343o\nUser Function FATA080()\n\tLocal nX := 0\nReturn nX\n' "$FFFD" >"$f"
  pre "$f"
  set_line "$f" 4 "$(printf '\tLocal nX := 1')"
  post "$f"
  check "fffd-cp1252: post exit 0 sem saida (sem aviso de U+FFFD)" [ "$RC$OUT$ERR" = 0 ]
  check "fffd-cp1252: na lista" pending_has "$f"
  cp "$f" "$d/antes"
  stop_hook Stop
  check "fffd-cp1252: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "fffd-cp1252: bytes identicos" cmp -s "$f" "$d/antes"
  check "fffd-cp1252: lista removida" pending_gone
}

case_avisos_mesclados() {
  # lint warning and the Windows-1252 warning of the same edit: one JSON
  local d="$TMP_DIR/$MODE/mesclados" f ctx
  mkdir -p "$d"; f="$d/FATA090.prw"
  new_session mesclados
  printf '#include "totvs.ch"\n\nUser Function FATA090()\n\tLocal nX := 0\n\tLocal lOk := .T.\nReturn nX\n' >"$f"
  pre "$f"
  insert_after "$f" 5 "$(printf '\tnX := IIf(lOk, 1, 2) // \360\237\232\200')"
  post "$f"
  ctx="$(json_context "$OUT")"
  check "mesclados: exit 0 sem stderr" [ "$RC$ERR" = 0 ]
  check "mesclados: um JSON valido" valid_hook_json "$OUT"
  check "mesclados: aviso do lint (linha 6)" contains "$ctx" "FATA090.prw:6: warning ADV009"
  check "mesclados: aviso de Windows-1252" contains "$ctx" "$f tem caracteres sem representacao em Windows-1252"
  check "mesclados: lint primeiro, depois o aviso de Windows-1252" \
    [ "$(printf '%s\n' "$ctx" | grep -n 'warning ADV009' | cut -d: -f1)" -lt \
      "$(printf '%s\n' "$ctx" | grep -n 'sem representacao' | cut -d: -f1)" ]
}

# --- PostToolUse(Bash): targets of convert-encoding.sh --to-utf8 --------------

# json_text TEXT: TEXT as the body of a JSON string (\ and " escaped, line
# breaks as \n)
json_text() {
  printf '%s\n' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' |
    awk '{ printf "%s%s", (NR > 1 ? "\\n" : ""), $0 }'
}

# bash_json COMMAND [CWD]: PostToolUse payload of a Bash call run in CWD
# ($TMP_DIR when omitted); the description (before the real key) and
# tool_response carry an escaped "command" decoy with a --to-utf8 run of
# /decoy.prw
bash_json() {
  local decoy='say \"command\": \"bash convert-encoding.sh --to-utf8 /decoy.prw\"'
  printf '{"session_id":"%s","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"description":"%s","command":"%s"},"tool_response":{"stdout":"%s","stderr":"","interrupted":false,"isImage":false},"tool_use_id":"toolu_01"}' \
    "$(json_quote "$SID")" "$(json_quote "${2-$TMP_DIR}")" "$decoy" "$(json_text "$1")" "$decoy"
}

# bash_hook COMMAND [CWD]: run post-tool-use-bash; sets RC, OUT, ERR
bash_hook() {
  bash_json "$@" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$BASHHOOK" >"$TMP_DIR/bash.out" 2>"$TMP_DIR/bash.err"
  RC=$?
  OUT="$(cat "$TMP_DIR/bash.out")"
  ERR="$(cat "$TMP_DIR/bash.err")"
}

case_bash_registra() {
  # converter runs as Claude types them: every target with a lint extension
  # goes on the list as an absolute path, and the hook prints nothing
  local d="$TMP_DIR/$MODE/bash-registra"
  mkdir -p "$d/sub" "$d/com espaco"
  new_session bash-registra
  bash_hook "bash \"$CONV\" --to-utf8 \"$d/FATA001.prw\""
  check "bash-registra: exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "bash-registra: aspas duplas, caminho absoluto" pending_has "$d/FATA001.prw"
  bash_hook "bash \"$CONV\" --to-utf8 sub/FATA002.PRW" "$d"
  check "bash-registra: relativo vira absoluto com o cwd" pending_has "$d/sub/FATA002.PRW"
  bash_hook "bash \"$CONV\" --to-utf8 ./FATA003.prx" "$d"
  check "bash-registra: ./ do relativo removido" pending_has "$d/FATA003.prx"
  bash_hook "bash '$CONV' --to-utf8 '$d/com espaco/FATA004.prw'"
  check "bash-registra: aspas simples (caminho com espaco)" pending_has "$d/com espaco/FATA004.prw"
  bash_hook "bash \"$CONV\" --to-utf8 \"$d/FATA005.tlpp\" \"$d/defs.TH\""
  check "bash-registra: dois arquivos, o primeiro" pending_has "$d/FATA005.tlpp"
  check "bash-registra: dois arquivos, o segundo (.TH)" pending_has "$d/defs.TH"
  bash_hook "bash \"$CONV\" --dry-run --to-utf8 \"$d/FATA006.prw\""
  check "bash-registra: --dry-run --to-utf8 tambem registra" pending_has "$d/FATA006.prw"
  bash_hook "bash \"\${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/scripts/convert-encoding.sh\" --to-utf8 \"$d/FATA007.prw\""
  check "bash-registra: \${CLAUDE_PLUGIN_ROOT} no caminho do script (passo dos comandos)" pending_has "$d/FATA007.prw"
  bash_hook "\"$CONV\" --to-utf8 -- -FATA008.prw" "$d"
  check "bash-registra: script executado direto, caminho com - depois de --" pending_has "$d/-FATA008.prw"
  bash_hook "bash \"$CONV\" \\
  --to-utf8\\
  \"$d/FATA009.prw\" 2>&1"
  check "bash-registra: linhas continuadas com \\ (com e sem espaco antes) e 2>&1" pending_has "$d/FATA009.prw"
  bash_hook "cd \"$d\" && bash \"$CONV\" --to-utf8 \"$d/FATA010.prw\"; echo feito" "$d"
  check "bash-registra: comando composto, caminho absoluto" pending_has "$d/FATA010.prw"
  bash_hook "bash \"$CONV\" --to-utf8 \"C:\\\\src\\\\FATA011.prw\" 'D:\\src\\FATA012.tlpp'"
  check "bash-registra: caminho do Windows entre aspas duplas (\\\\)" pending_has 'C:\src\FATA011.prw'
  check "bash-registra: caminho do Windows entre aspas simples" pending_has 'D:\src\FATA012.tlpp'
  bash_hook "bash \"$CONV\" --to-utf8 \"$d/FATA013.prw\" # converte (|) antes do Edit"
  check "bash-registra: comentario no fim ignorado" pending_has "$d/FATA013.prw"
  bash_hook "bash \"$CONV\" --to-utf8 $d/FATA#014.prw"
  check "bash-registra: # no meio da palavra nao abre comentario" pending_has "$d/FATA#014.prw"
  bash_hook "bash \"$CONV\" --to-utf8 \"$d/FATA001.prw\""
  check "bash-registra: exit 0 sem saida no fim" [ "$RC$OUT$ERR" = 0 ]
  check "bash-registra: 15 entradas, sem repeticao" [ "$(pending_count)" = 15 ]
  check "bash-registra: o decoy fica de fora" not pending_has /decoy.prw
}

case_bash_nada() {
  # nothing registered and nothing printed: no --to-utf8 run, no lint
  # extension, expansions, constructs the hook cannot read, other commands
  local d="$TMP_DIR/$MODE/bash-nada" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  new_session bash-nada
  legacy_cp1252 "$f"; cp "$f" "$d/original"
  quiet_none() { [ "$RC$OUT$ERR" = 0 ] && pending_none; }
  nada() { # nada LABEL COMMAND [CWD]; the list is cleared after each check
    bash_hook "$2" "${3-$TMP_DIR}"
    check "bash-nada: $1" quiet_none
    rm -f "$PEND_DIR/$SID"
  }
  nada "sem --to-utf8" "bash \"$CONV\" \"$f\""
  nada "--to-utf8 depois de -- (e um caminho)" "bash \"$CONV\" -- --to-utf8 \"$f\""
  nada "arquivos nao ADVPL (.ch, .txt)" "bash \"$CONV\" --to-utf8 \"$d/defs.ch\" \"$d/notas.txt\""
  nada "\$VAR entre aspas" "bash \"$CONV\" --to-utf8 \"\$DIR/FATA001.prw\""
  nada "\$VAR em um argumento anula os outros" "bash \"$CONV\" --to-utf8 \"$f\" \$HOME/FATA002.prw"
  nada "\${VAR}" "bash \"$CONV\" --to-utf8 \"\${DIR}/FATA001.prw\""
  nada "glob *" "bash \"$CONV\" --to-utf8 \"$d\"/*.prw"
  nada "glob ?" "bash \"$CONV\" --to-utf8 \"$d\"/FATA00?.prw"
  nada "til" "bash \"$CONV\" --to-utf8 ~/FATA001.prw"
  nada "chaves" "bash \"$CONV\" --to-utf8 \"$d\"/FATA00{1,2}.prw"
  nada "\$(...)" "bash \"$CONV\" --to-utf8 \"\$(pwd)/FATA001.prw\""
  nada "crase" "bash \"$CONV\" --to-utf8 \`pwd\`/FATA001.prw"
  nada "\${VAR:-x} no script" "bash \"\${ROOT:-/x}/convert-encoding.sh\" --to-utf8 \"$f\""
  nada "pipe" "bash \"$CONV\" --to-utf8 \"$f\" | tee log"
  nada "segundo plano (&)" "bash \"$CONV\" --to-utf8 \"$f\" &"
  nada "subshell" "(bash \"$CONV\" --to-utf8 \"$f\")"
  nada "heredoc" "bash \"$CONV\" --to-utf8 \"$f\" <<EOF
x
EOF"
  nada "aspas sem fim" "bash \"$CONV\" --to-utf8 \"$f"
  nada "-r em diretorio" "bash \"$CONV\" --to-utf8 -r \"$d\""
  nada "opcao desconhecida (erro de uso)" "bash \"$CONV\" --to-utf8 --force \"$f\""
  nada "--translit com --to-utf8 (erro de uso)" "bash \"$CONV\" --translit --to-utf8 \"$f\""
  nada "--help" "bash \"$CONV\" --to-utf8 --help \"$f\""
  nada "relativo sem cwd" "bash \"$CONV\" --to-utf8 FATA001.prw" ""
  nada "relativo com cwd relativo" "bash \"$CONV\" --to-utf8 FATA001.prw" "proj/src"
  nada "relativo em comando composto (cd)" "cd \"$d\" && bash \"$CONV\" --to-utf8 FATA001.prw"
  nada "echo do comando" "echo bash \"$CONV\" --to-utf8 \"$f\""
  nada "grep com os dois nomes" "grep -n -- --to-utf8 \"$CONV\" \"$f\""
  nada "comentario" "ls # bash \"$CONV\" --to-utf8 \"$f\""
  nada "outro comando (ls)" "ls -la \"$d\""
  nada "outro comando (git status)" "git status"
  printf '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{}}' |
    ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$BASHHOOK" >"$TMP_DIR/bash.out" 2>&1
  check "bash-nada: payload sem command" [ "$?$(cat "$TMP_DIR/bash.out")" = 0 ]
  printf 'convert-encoding.sh --to-utf8 {"command":' |
    ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$BASHHOOK" >"$TMP_DIR/bash.out" 2>&1
  check "bash-nada: payload que nao e JSON" [ "$?$(cat "$TMP_DIR/bash.out")" = 0 ]
  check "bash-nada: nada na lista" pending_none
  check "bash-nada: arquivo intocado" cmp -s "$f" "$d/original"
}

case_bash_fluxo() {
  # --to-utf8 through Bash with no Read before it and no Edit after it: the
  # Bash hook alone puts the files on the list (it never runs the command),
  # and Stop gives back the original Windows-1252 bytes
  local d="$TMP_DIR/$MODE/bash-fluxo" a b c
  mkdir -p "$d/sub"; a="$d/FATA001.prw"; b="$d/sub/FATA002.tlpp"; c="$d/FATA003.prw"
  new_session bash-fluxo
  legacy_cp1252 "$a"; cp "$a" "$d/a.original"
  legacy_cp1252 "$b"; cp "$b" "$d/b.original"
  legacy_cp1252 "$c"; cp "$c" "$d/c.original"
  bash_hook "bash \"$CONV\" --to-utf8 \"$a\"; touch \"$d/executado\"" "$d"
  check "bash-fluxo: o hook nao executa o comando" [ ! -e "$d/executado" ]
  check "bash-fluxo: o hook nao converte" cmp -s "$a" "$d/a.original"
  check "bash-fluxo: absoluto na lista" pending_has "$a"
  # the runs themselves, as the Bash tool makes them
  "$HOOK_BASH" "$CONV" --to-utf8 "$a" >/dev/null
  (cd "$d" && "$HOOK_BASH" "$CONV" --to-utf8 sub/FATA002.tlpp >/dev/null)
  bash_hook "bash \"$CONV\" --to-utf8 sub/FATA002.tlpp" "$d"
  check "bash-fluxo: relativo na lista" pending_has "$b"
  "$HOOK_BASH" "$CONV" --dry-run --to-utf8 "$c" >/dev/null
  bash_hook "bash \"$CONV\" --dry-run --to-utf8 \"$c\"" "$d"
  check "bash-fluxo: --dry-run na lista" pending_has "$c"
  check "bash-fluxo: absoluto em UTF-8" has_bytes "$UTF8_ACENTO" "$a"
  check "bash-fluxo: relativo em UTF-8" has_bytes "$UTF8_ACENTO" "$b"
  stop_hook Stop
  check "bash-fluxo: Stop exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "bash-fluxo: absoluto de volta, bytes identicos" cmp -s "$a" "$d/a.original"
  check "bash-fluxo: relativo de volta, bytes identicos" cmp -s "$b" "$d/b.original"
  check "bash-fluxo: --dry-run intocado (already-cp1252)" cmp -s "$c" "$d/c.original"
  check "bash-fluxo: lista removida" pending_gone
}

run_cases() {
  echo "[parser: $MODE]"
  case_write_novo
  case_edit_legado_cp1252
  case_edit_legado_reencode
  case_edit_introduz_erro
  case_edit_crlf
  case_caminho_espaco_acento
  case_fffd
  case_translit
  case_legado_utf8
  case_nao_advpl
  case_arquivo_grande
  case_somente_avisos
  case_tlpp
  case_ignore
  case_sem_mudanca
  case_read_dica
  case_read_caminho
  case_read_sem_dica
  case_read_plugin
  case_read_erro_interno
  case_read_ida_volta
  case_read_sem_conversao
  case_tres_edits
  case_stop
  case_sessao
  case_stop_tarefas
  case_caminho_relativo
  case_stop_interrompido
  case_stop_fallback
  case_fffd_cp1252
  case_avisos_mesclados
  case_bash_registra
  case_bash_nada
  case_bash_fluxo
}

check_hooks_json() {
  local j="$ROOT/hooks/hooks.json" c
  echo "[hooks.json]"
  check "hooks.json: post-tool-use-encoding removido" [ ! -e "$ROOT/hooks/post-tool-use-encoding" ]
  for c in session-start pre-tool-use post-tool-use post-tool-use-read post-tool-use-bash stop; do
    check "hooks.json: comando bash \"\${CLAUDE_PLUGIN_ROOT}/hooks/$c\"" \
      grep -qF "\"command\": \"bash \\\"\${CLAUDE_PLUGIN_ROOT}/hooks/$c\\\"\"" "$j"
    check "hooks.json: hooks/$c existe" [ -f "$ROOT/hooks/$c" ]
  done
  if command -v jq >/dev/null 2>&1; then
    check "hooks.json: JSON valido" jq empty "$j"
    check "hooks.json: SessionStart startup|resume" \
      jq -e '.hooks.SessionStart[0].matcher == "startup|resume"' "$j"
    check "hooks.json: Pre/PostToolUse Write|Edit|MultiEdit" \
      jq -e '.hooks.PreToolUse[0].matcher == "Write|Edit|MultiEdit" and .hooks.PostToolUse[0].matcher == "Write|Edit|MultiEdit"' "$j"
    check "hooks.json: PreToolUse com onFailure continue" \
      jq -e '.hooks.PreToolUse[0].hooks[0].onFailure == "continue"' "$j"
    # shellcheck disable=SC2016 # ${CLAUDE_PLUGIN_ROOT} is literal text in hooks.json
    check "hooks.json: PostToolUse Read -> so post-tool-use-read" \
      jq -e '[.hooks.PostToolUse[] | select(.matcher == "Read") | .hooks[] | [.type, .command, .async]]
        == [["command", "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/post-tool-use-read\"", false]]' "$j"
    check "hooks.json: Read fora do PreToolUse" \
      jq -e '[.hooks.PreToolUse[] | select(.matcher | test("Read"))] == []' "$j"
    # shellcheck disable=SC2016 # ${CLAUDE_PLUGIN_ROOT} is literal text in hooks.json
    check "hooks.json: PostToolUse Bash -> so post-tool-use-bash" \
      jq -e '[.hooks.PostToolUse[] | select(.matcher == "Bash") | .hooks[] | [.type, .command, .async]]
        == [["command", "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/post-tool-use-bash\"", false]]' "$j"
    check "hooks.json: Bash fora do PreToolUse" \
      jq -e '[.hooks.PreToolUse[] | select(.matcher | test("Bash"))] == []' "$j"
    # shellcheck disable=SC2016 # ${CLAUDE_PLUGIN_ROOT} is literal text in hooks.json
    check "hooks.json: Stop e SessionEnd -> so hooks/stop (sincrono)" \
      jq -e '["command", "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/stop\"", false] as $s
        | [.hooks.Stop, .hooks.SessionEnd | [.[].hooks[] | [.type, .command, .async]]] == [[$s], [$s]]' "$j"
    check "hooks.json: SubagentStop fora (nao converte no fim de subagente)" \
      jq -e '.hooks.SubagentStop == null' "$j"
    check "hooks.json: eventos" \
      jq -e '(.hooks | keys) == ["PostToolUse", "PreToolUse", "SessionEnd", "SessionStart", "Stop"]' "$j"
  fi
}

check_session_start() {
  local d="$TMP_DIR/ss" fake="$TMP_DIR/ss-bin" home="$TMP_DIR/ss-home" out n
  echo "[session-start]"
  rm -rf "$d" "$fake" "$home"
  mkdir -p "$d" "$fake" "$home/.claude/plugins/cache/advpl-specialist-marketplace/advpl-specialist/0.0.1"
  printf '#!/bin/sh\necho called > "%s/claude-called"\n' "$TMP_DIR" > "$fake/claude"
  chmod +x "$fake/claude"
  rm -f "$TMP_DIR/claude-called"

  out="$(cd "$d" && HOME="$home" PATH="$fake:$PATH" "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1 </dev/null)"
  check "session-start: sem arquivos ADVPL nao imprime nada" [ -z "$out" ]

  touch "$d/FOO.PRW"
  out="$(cd "$d" && HOME="$home" PATH="$fake:$PATH" "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1 </dev/null)"
  check "session-start: FOO.PRW detectado" grep -q "ADVPL/TLPP project detected" <<<"$out"
  n="$(grep -c '/advpl-specialist:' <<<"$out")"
  check "session-start: lista 16 comandos (achou $n)" [ "$n" = 16 ]
  check "session-start: lista /advpl-specialist:validate" grep -q '/advpl-specialist:validate$' <<<"$out"
  check "session-start: dica do fluxo --to-utf8 com o conversor" \
    grep -qF -- "bash \"$ROOT/skills/advpl-code-generation/scripts/convert-encoding.sh\" --to-utf8 FILE" <<<"$out"
  check "session-start: dica fala do lint de cada edicao e da volta no fim do turno" \
    grep -qF -- "lints each edit (introduced lines only) and converts the file back to Windows-1252 at the end of the turn" <<<"$out"
  check "session-start: dica do subagente sem Bash" \
    grep -qF -- "A subagent without Bash must not convert: return the file path to the caller, who converts it" <<<"$out"
  check "session-start: nunca chama claude" [ ! -e "$TMP_DIR/claude-called" ]
  check "session-start: nao apaga cache de plugins" \
    [ -d "$home/.claude/plugins/cache/advpl-specialist-marketplace/advpl-specialist/0.0.1" ]

  rm -f "$d/FOO.PRW"; touch "$d/x.TH"
  out="$(cd "$d" && HOME="$home" "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1 </dev/null)"
  check "session-start: .TH detectado" grep -q "ADVPL/TLPP project detected" <<<"$out"

  # Pending lists left by other sessions: a read-only notice, in any project
  local src="$TMP_DIR/ss-src" a b c i nj sum
  rm -f "$d/x.TH"; rm -rf "$src"; mkdir -p "$src" "$PEND_DIR"
  a="$src/A.prw"; b="$src/B b.tlpp"; c="$src/C.prw"
  printf 'x\303\247\n' >"$a"; printf 'y\303\247\n' >"$b"; printf 'z\n' >"$c"
  printf '%s\n' "$a" rel.prw "$src/sumiu.prw" "$a" >"$PEND_DIR/ss-outra"
  printf '%s\r\n' "$b" >"$PEND_DIR/ss-morta.4242"
  printf '%s\n' "$c" >"$PEND_DIR/ss-atual"
  sum="$(cksum <"$a")$(cksum <"$b")"
  for nj in 0 1; do
    out="$(cd "$d" && printf '{"session_id":"ss-atual","hook_event_name":"SessionStart","source":"startup"}' |
      ADVPL_HOOK_NO_JQ=$nj "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1)"
    check "session-start pendentes ($nj): aviso mesmo sem fontes ADVPL no projeto" \
      grep -qF "advpl-specialist: pending lists of other Claude Code sessions" <<<"$out"
    check "session-start pendentes ($nj): diz que nada foi convertido" grep -qF "Nothing was converted" <<<"$out"
    check "session-start pendentes ($nj): A listado uma vez" [ "$(grep -cxF "  $a" <<<"$out")" = 1 ]
    check "session-start pendentes ($nj): B do arquivo de trabalho (CRLF)" grep -qxF "  $b" <<<"$out"
    check "session-start pendentes ($nj): sem a lista da sessao atual" not grep -qF "$c" <<<"$out"
    check "session-start pendentes ($nj): sem caminho relativo nem arquivo sumido" \
      not grep -qE 'rel\.prw|sumiu\.prw' <<<"$out"
    check "session-start pendentes ($nj): comando do conversor" \
      grep -qF "bash \"$ROOT/skills/advpl-code-generation/scripts/convert-encoding.sh\" FILE" <<<"$out"
    check "session-start pendentes ($nj): nomeia as listas a apagar" \
      grep -qF "\"$PEND_DIR/ss-morta.4242\" \"$PEND_DIR/ss-outra\"" <<<"$out"
  done
  check "session-start pendentes: nenhum fonte convertido" [ "$(cksum <"$a")$(cksum <"$b")" = "$sum" ]
  check "session-start pendentes: lista de outra sessao mantida" [ -f "$PEND_DIR/ss-outra" ]
  check "session-start pendentes: arquivo de trabalho mantido" [ -f "$PEND_DIR/ss-morta.4242" ]
  # more than 10 sources: 10 paths, then the count of the others
  rm -f "$PEND_DIR/ss-morta.4242" "$PEND_DIR/ss-outra"
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    : >"$src/M$i.prw"; printf '%s\n' "$src/M$i.prw" >>"$PEND_DIR/ss-outra"
  done
  out="$(cd "$d" && printf '{"session_id":"ss-atual"}' | "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1)"
  check "session-start pendentes: 10 caminhos" [ "$(grep -cF "  $src/M" <<<"$out")" = 10 ]
  check "session-start pendentes: conta os outros 2" grep -qxF "  ... and 2 more" <<<"$out"
  # only this session's list: no notice
  rm -f "$PEND_DIR/ss-outra"
  out="$(cd "$d" && printf '{"session_id":"ss-atual"}' | "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1)"
  check "session-start pendentes: so a lista da sessao atual, nada impresso" [ -z "$out" ]
  rm -f "$PEND_DIR/ss-atual"; rm -rf "$src"
}

# post-tool-use fast path: a file the converter does not handle never reaches
# convert-encoding.sh (a stub that records its calls); a source does.
check_fast_path() {
  local stub="$TMP_DIR/fp-root" d="$TMP_DIR/fp" m="$TMP_DIR/fp-called" rc
  echo "[post-tool-use: caminho rapido]"
  rm -rf "$stub" "$d" "$m"
  mkdir -p "$stub/skills/advpl-code-generation/scripts" "$d"
  printf '#!/bin/sh\necho "$@" >>"%s"\n' "$m" >"$stub/skills/advpl-code-generation/scripts/convert-encoding.sh"
  printf 'texto\n' >"$d/notas.md"
  hook_json PostToolUse Write "$d/notas.md" | CLAUDE_PLUGIN_ROOT="$stub" "$HOOK_BASH" "$POST" >/dev/null 2>&1
  rc=$?
  check "caminho rapido: .md exit 0" [ "$rc" = 0 ]
  check "caminho rapido: .md nao chama o conversor" [ ! -e "$m" ]
  printf 'User Function FP()\nReturn\n' >"$d/FP.PRW"
  hook_json PostToolUse Write "$d/FP.PRW" | CLAUDE_PLUGIN_ROOT="$stub" "$HOOK_BASH" "$POST" >/dev/null 2>&1
  check "caminho rapido: .PRW chama o conversor (dry run)" grep -qF -- "--dry-run" "$m"
  rm -rf "$stub" "$d" "$m"
}

# crlf_json EVENT PATH [TOOL]: hook payload, one key per line, CRLF line endings
crlf_json() {
  printf '{\r\n  "hook_event_name": "%s",\r\n  "tool_name": "%s",\r\n  "tool_input": {\r\n    "file_path": "%s"\r\n  }\r\n}\r\n' \
    "$1" "${3:-Edit}" "$(json_quote "$2")"
}

# crlf_stop_json TYPE: Stop payload without session_id, one key per line,
# CRLF line endings, background_tasks spread over several lines: one task of
# TYPE (subagent, shell) or none (empty)
crlf_stop_json() {
  local nl=$'\r\n' bg
  if [ "$1" = empty ]; then
    bg="[$nl  ]"
  else
    bg="[$nl    {$nl      \"id\": \"b1\",$nl      \"type\": \"$1\",$nl      \"description\": \"a ] b }\"$nl    }$nl  ]"
  fi
  printf '{\r\n  "hook_event_name": "Stop",\r\n  "stop_hook_active": false,\r\n  "background_tasks": %s,\r\n  "session_crons": []\r\n}\r\n' "$bg"
}

# crlf_bash_json CWD COMMAND: PostToolUse payload of a Bash call without
# session_id, one key per line, CRLF line endings
crlf_bash_json() {
  printf '{\r\n  "hook_event_name": "PostToolUse",\r\n  "tool_name": "Bash",\r\n  "cwd": "%s",\r\n  "tool_input": {\r\n    "command": "%s"\r\n  }\r\n}\r\n' \
    "$(json_quote "$1")" "$(json_text "$2")"
}

# jq.exe on Windows writes CRLF (text-mode stdout). A jq wrapper first in PATH
# that ends every output line with CRLF stands in for it on any OS, and the
# payload itself has CRLF line endings: the hooks must still take the .prw
# path (snapshot, introduced line linted). Both parsers; without a real jq the
# jq half is reported as skipped, not passed.
check_crlf() {
  local d fake="$TMP_DIR/crlf-bin" real p f saved_path="$PATH" NO_JQ
  echo "[CRLF: saida do jq no Windows e payload com CRLF]"
  real="$(command -v jq 2>/dev/null || true)"
  mkdir -p "$fake"
  for p in jq builtin; do
    PATH="$saved_path"
    if [ "$p" = jq ]; then
      if [ -z "$real" ]; then
        echo "  SKIP crlf-jq: jq nao instalado (saida CRLF do jq nao exercitada)"
        continue
      fi
      # shellcheck disable=SC2016 # "$@" and $0 belong to the generated wrapper
      printf '#!/bin/sh\n"%s" "$@" | awk '\''{ sub(/\\r$/, ""); printf "%%s\\r\\n", $0 }'\''\n' "$real" >"$fake/jq"
      chmod +x "$fake/jq"
      PATH="$fake:$saved_path"
      NO_JQ=0
      check "crlf-jq: wrapper termina a linha em CRLF" \
        [ "$(printf '{"a":"x"}' | jq -r .a | od -An -c | tr -d ' \n')" = 'x\r\n' ]
    else
      NO_JQ=1
    fi
    d="$TMP_DIR/crlf/$p"; f="$d/FATA008.prw"
    mkdir -p "$d"
    rm -f "$PEND_DIR/nosession"
    printf '#include "totvs.ch"\n// importa\303\247\303\243o\nUser Function FATA008()\n\tLocal nX := 0\nReturn nX\n' >"$f"
    crlf_json PreToolUse "$f" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$PRE" >"$TMP_DIR/pre.out" 2>&1
    PRE_RC=$?
    check "crlf-$p: pre exit 0" [ "$PRE_RC" = 0 ]
    check "crlf-$p: snapshot criado" [ -f "$SNAP_DIR/$(snap_key "$f")" ]
    set_line "$f" 4 "$(printf '\tConOut("x")')"
    crlf_json PostToolUse "$f" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$POST" >"$TMP_DIR/post.out" 2>"$TMP_DIR/post.err"
    RC=$?
    ERR="$(cat "$TMP_DIR/post.err")"
    check "crlf-$p: post exit 2" [ "$RC" = 2 ]
    check "crlf-$p: acusa so a linha 4" contains "$ERR" "FATA008.prw:4: error ADV003"
    check "crlf-$p: exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
    check "crlf-$p: snapshot removido" snap_empty
    # Read of a Windows-1252 source: the hint names the path without a CR
    legacy_cp1252 "$d/FATA009.prw"
    crlf_json PostToolUse "$d/FATA009.prw" Read |
      ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$READ" >"$TMP_DIR/read.out" 2>"$TMP_DIR/read.err"
    RC=$?
    OUT="$(cat "$TMP_DIR/read.out")"
    check "crlf-$p: Read exit 0 sem stderr" [ "$RC$(cat "$TMP_DIR/read.err")" = 0 ]
    CTX="$(json_context "$OUT" | tr -d '\r')"   # the wrapper's own CRLF
    check "crlf-$p: dica do Read com o caminho exato" has_line "$CTX" "$(to_utf8_line "$d/FATA009.prw")"
    # no session_id: list "nosession", exact paths (no CR)
    check "crlf-$p: lista nosession com os dois caminhos exatos" \
      [ "$(cat "$PEND_DIR/nosession" 2>/dev/null)" = "$f
$d/FATA009.prw" ]
    cp "$d/FATA009.prw" "$d/FATA009.original"
    crlf_stop_json subagent | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$STOP" >"$TMP_DIR/stop.out" 2>&1
    check "crlf-$p: Stop com subagente exit 0" [ "$?" = 0 ]
    check "crlf-$p: Stop com subagente avisa 1 fonte em UTF-8 (o CP1252 lido nao conta)" \
      contains "$(cat "$TMP_DIR/stop.out")" '"systemMessage":"advpl-specialist: 1 fonte(s) ainda em UTF-8'
    check "crlf-$p: Stop com subagente (array em varias linhas) nao converte" has_bytes "$UTF8_ACENTO" "$f"
    check "crlf-$p: Stop com subagente mantem a lista" [ -f "$PEND_DIR/nosession" ]
    crlf_stop_json shell | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$STOP" >"$TMP_DIR/stop.out" 2>&1
    check "crlf-$p: Stop so com shell (array em varias linhas) exit 0 sem saida" [ "$?$(cat "$TMP_DIR/stop.out")" = 0 ]
    check "crlf-$p: Stop so com shell converte" has_bytes "$CP_ACENTO" "$f"
    check "crlf-$p: Stop so com shell mantem o CP1252 lido" cmp -s "$d/FATA009.prw" "$d/FATA009.original"
    check "crlf-$p: lista removida" [ ! -e "$PEND_DIR/nosession" ]
    # Bash: a command continued over two lines (the wrapper ends the inner
    # line with CRLF too) and a relative path joined to cwd
    crlf_bash_json "$d" "bash \"$CONV\" \\
  --to-utf8 FATA010.prw" | ADVPL_HOOK_NO_JQ="$NO_JQ" "$HOOK_BASH" "$BASHHOOK" >"$TMP_DIR/bash.out" 2>&1
    check "crlf-$p: Bash exit 0 sem saida" [ "$?$(cat "$TMP_DIR/bash.out")" = 0 ]
    check "crlf-$p: Bash poe o caminho exato (sem CR) na lista nosession" \
      [ "$(cat "$PEND_DIR/nosession" 2>/dev/null)" = "$d/FATA010.prw" ]
    rm -f "$PEND_DIR/nosession"
  done
  PATH="$saved_path"
}

echo "hook bash: $HOOK_BASH ($("$HOOK_BASH" --version | head -n 1))"
check_hooks_json
check_session_start
check_fast_path
check_crlf
if command -v jq >/dev/null 2>&1; then
  MODE=jq NO_JQ=0 run_cases
fi
MODE=builtin NO_JQ=1 run_cases

echo ""
echo "Resultado: $PASS ok, $FAIL falha(s)"
[ "$FAIL" -eq 0 ]
