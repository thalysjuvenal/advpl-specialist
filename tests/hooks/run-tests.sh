#!/usr/bin/env bash
# Runner for hooks/pre-tool-use + hooks/post-tool-use: simulates the stdin JSON
# Claude Code sends to PreToolUse/PostToolUse for Write|Edit|MultiEdit, in a
# temporary directory, and checks exit codes, stderr/stdout and file bytes.
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
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export CLAUDE_PLUGIN_ROOT="$ROOT"
export CLAUDE_PLUGIN_DATA="$TMP_DIR/plugin-data"
export CLAUDE_PROJECT_DIR="$TMP_DIR"
SNAP_DIR="$CLAUDE_PLUGIN_DATA/advpl-specialist-snapshots"
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
  printf '{"session_id":"t","cwd":"%s","hook_event_name":"%s","tool_name":"%s","tool_input":{"old_string":"say \\"file_path\\": \\"/decoy.prw\\"","new_string":"a\\\\\\"file_path\\\\\\":x","file_path":"%s"},"tool_response":{"filePath":"%s"}}' \
    "$(json_quote "$TMP_DIR")" "$1" "$2" "$p" "$p"
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
  pre "$f" Write
  printf '#include "totvs.ch"\n\nUser Function FATA002()\n\tLocal cMsg := "importa\303\247\303\243o"\n\tConOut(cMsg)\nReturn Nil\n' >"$f"
  post "$f" Write
  check "write-novo: exit 2" [ "$RC" = 2 ]
  check "write-novo: stderr cita ADV003 na linha 5" contains "$ERR" "FATA002.prw:5: error ADV003"
  check "write-novo: stderr traz a dica do ignore" contains "$ERR" ".advpl-specialist-ignore"
  check "write-novo: stdout vazio" [ -z "$OUT" ]
  check "write-novo: UTF-8 convertido para CP1252" has_bytes "$(printf '\347\343')" "$f"
  check "write-novo: sem bytes UTF-8 remanescentes" lacks_bytes "$UTF8_ACENTO" "$f"
  check "write-novo: snapshot removido" snap_empty
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
  # the editor rewrote the whole CP1252 file as UTF-8: conversion runs first,
  # so the legacy lines match the snapshot again
  local d="$TMP_DIR/$MODE/edit-reencode" f
  mkdir -p "$d"; f="$d/FATA001.prw"
  legacy_cp1252 "$f"
  pre "$f"
  set_line "$f" 12 "$(printf '\tnX := 1')"
  iconv -f WINDOWS-1252 -t UTF-8 "$f" >"$f.u" && cat "$f.u" >"$f" && rm -f "$f.u"
  post "$f"
  check "edit-legado-utf8: exit 0" [ "$RC" = 0 ]
  check "edit-legado-utf8: sem saida" [ -z "$OUT$ERR" ]
  check "edit-legado-utf8: reconvertido para CP1252" has_bytes "$CP_ACENTO" "$f"
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
  printf '#include "totvs.ch"\n\nUser Function FATA001()\n\tLocal nX := 0\n\tConOut("legado")\nReturn nX\n' >"$f"
  pre "$f"
  check "caminho-espaco-acento: snapshot criado" [ -f "$SNAP_DIR/$(snap_key "$f")" ]
  insert_after "$f" 4 "$(printf '\tConOut("novo")')"
  post "$f"
  check "caminho-espaco-acento: exit 2" [ "$RC" = 2 ]
  check "caminho-espaco-acento: cita o caminho completo" contains "$ERR" "$f:5: error ADV003"
  check "caminho-espaco-acento: exatamente 1 achado" [ "$(finding_count "$ERR")" = 1 ]
  check "caminho-espaco-acento: snapshot removido" snap_empty
}

case_fffd() {
  local d="$TMP_DIR/$MODE/fffd" f g
  mkdir -p "$d"; f="$d/FATA004.prw"; g="$d/FATA005.prw"
  pre "$f" Write
  printf '#include "totvs.ch"\n\nUser Function FATA004()\n\tLocal cMsg := "importa%s%so"\nReturn cMsg\n' "$FFFD" "$FFFD" >"$f"
  post "$f" Write
  check "fffd: exit 2" [ "$RC" = 2 ]
  check "fffd: stderr cita ADV014 na linha 4" contains "$ERR" "FATA004.prw:4: error ADV014"
  check "fffd: conversao pulada (bytes EF BF BD mantidos)" has_bytes "$FFFD" "$f"
  check "fffd: stderr avisa que a conversao foi pulada" contains "$ERR" "conversao para Windows-1252 nao executada"
  check "fffd: snapshot removido" snap_empty
  # U+FFFD already in the file before the edit is legacy debt: not reported,
  # only the non-blocking note that the conversion was skipped
  printf '#include "totvs.ch"\n\nUser Function FATA005()\n\tLocal cMsg := "importa%so"\n\tLocal nX := 0\nReturn cMsg\n' "$FFFD" >"$g"
  pre "$g"
  set_line "$g" 5 "$(printf '\tLocal nX := 1')"
  post "$g"
  check "fffd-legado: exit 0" [ "$RC" = 0 ]
  check "fffd-legado: sem stderr" [ -z "$ERR" ]
  check "fffd-legado: JSON valido" valid_hook_json "$OUT"
  check "fffd-legado: contexto avisa conversao pulada" contains "$(json_context "$OUT")" "conversao para Windows-1252 nao executada"
  check "fffd-legado: nenhum achado do lint" [ "$(finding_count "$(json_context "$OUT")")" = 0 ]
  check "fffd-legado: U+FFFD legado nao e transliterado" has_bytes "$FFFD" "$g"
}

case_legado_utf8() {
  # legacy files never converted (still UTF-8, maybe with BOM): the snapshot is
  # normalized like the file, so untouched accented/BOM lines are not "introduced"
  local d="$TMP_DIR/$MODE/legado-utf8" f g h
  mkdir -p "$d"; f="$d/FATA010.prw"; g="$d/FATA011.PRW"; h="$d/defs.th"
  printf '#include "totvs.ch"\n\nUser Function FATA010()\n\tLocal nX := 0\n\tConOut("In\303\255cio da importa\303\247\303\243o")\nReturn nX\n' >"$f"
  pre "$f"
  set_line "$f" 4 "$(printf '\tLocal nX := 1')"
  post "$f"
  check "legado-utf8: exit 0" [ "$RC" = 0 ]
  check "legado-utf8: sem saida (ConOut legado acentuado nao acusado)" [ -z "$OUT$ERR" ]
  check "legado-utf8: arquivo convertido para CP1252" has_bytes "$CP_ACENTO" "$f"
  check "legado-utf8: snapshot e copia removidos" snap_empty
  # UTF-8 with BOM, editor kept the BOM: the conversion strips it from the file
  printf '\357\273\277#Include "Protheus.ch"\n\nUser Function FATA011()\n\tLocal cMsg := "a\303\247\303\243o"\n\tLocal nX := 0\nReturn cMsg\n' >"$g"
  pre "$g"
  set_line "$g" 5 "$(printf '\tLocal nX := 1')"
  post "$g"
  check "legado-utf8-bom: exit 0" [ "$RC" = 0 ]
  check "legado-utf8-bom: sem saida (#Include Protheus.ch legado nao acusado)" [ -z "$OUT$ERR" ]
  check "legado-utf8-bom: BOM removido do arquivo" lacks_bytes "$(printf '\357\273\277')" "$g"
  check "legado-utf8-bom: snapshot e copia removidos" snap_empty
  # .th with BOM, editor dropped the BOM: the snapshot copy goes through the
  # converter too (BOM stripped), so line 1 still matches
  printf '\357\273\277#Include "Protheus.ch"\n#define CMSG "x"\n' >"$h"
  pre "$h"
  printf '#Include "Protheus.ch"\n#define CMSG "y"\n' >"$h"
  post "$h"
  check "legado-bom-removido (.th): exit 0 sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "legado-bom-removido (.th): snapshot removido" snap_empty
}

case_translit() {
  # emoji in a comment: transliterated to "?" (never blocks), the rest of the
  # file converted, and a non-blocking note names the file and the count
  local d="$TMP_DIR/$MODE/translit" f ctx
  mkdir -p "$d"; f="$d/FATA012.prw"
  pre "$f" Write
  printf '#include "totvs.ch"\n\n// lan\303\247amento \360\237\232\200\nUser Function FATA012()\nReturn Nil\n' >"$f"
  post "$f" Write
  check "translit: exit 0" [ "$RC" = 0 ]
  check "translit: sem stderr" [ -z "$ERR" ]
  check "translit: JSON valido" valid_hook_json "$OUT"
  ctx="$(json_context "$OUT")"
  check "translit: contexto traz a linha translit: com a contagem" contains "$ctx" "translit: $f (1)"
  check "translit: contexto pede revisao dos '?'" contains "$ctx" "viraram '?'"
  check "translit: emoji virou ? e acento em CP1252" has_bytes "$(printf 'lan\347amento ?')" "$f"
  check "translit: sem bytes UTF-8" lacks_bytes "$UTF8_ACENTO" "$f"
  check "translit: snapshot removido" snap_empty
}

case_nao_advpl() {
  local d="$TMP_DIR/$MODE/nao-advpl" f c
  mkdir -p "$d"; f="$d/notas.txt"; c="$d/defs.ch"
  printf 'ConOut("x")\n' >"$f"
  pre "$f"
  check "nao-advpl: pre nao cria snapshot" snap_empty
  printf 'ConOut("y")\n' >>"$f"
  post "$f"
  check "nao-advpl: exit 0" [ "$RC" = 0 ]
  check "nao-advpl: sem saida" [ -z "$OUT$ERR" ]
  # .ch: still converted to CP1252 by the encoding step, never linted
  pre "$c" Write
  printf '#define CMSG "importa\303\247\303\243o"\nConOut(CMSG)\n' >"$c"
  post "$c" Write
  check "ch: exit 0 e sem saida" [ "$RC$OUT$ERR" = 0 ]
  check "ch: convertido para CP1252" has_bytes "$CP_ACENTO" "$c"
}

big_ops() {
  pre "$1"
  set_line "$1" 2500 "$(printf '\tConOut("x")')"
  post "$1"
}

case_arquivo_grande() {
  local d="$TMP_DIR/$MODE/grande" f elapsed
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
  check "arquivo-grande: < 2 s" awk -v t="$elapsed" 'BEGIN { exit !(t + 0 < 2) }'
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

json_context() { # additionalContext, decoded when jq is available
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext'
  else
    printf '%s' "$1"
  fi
}

case_somente_avisos() {
  # name with a double quote and a backslash: the JSON must escape both
  local d="$TMP_DIR/$MODE/avisos" f ctx
  mkdir -p "$d"; f="$d/aspas\"e\\barra.prw"
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
}

check_hooks_json() {
  local j="$ROOT/hooks/hooks.json" c
  echo "[hooks.json]"
  check "hooks.json: post-tool-use-encoding removido" [ ! -e "$ROOT/hooks/post-tool-use-encoding" ]
  for c in session-start pre-tool-use post-tool-use; do
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

  out="$(cd "$d" && HOME="$home" PATH="$fake:$PATH" "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1)"
  check "session-start: sem arquivos ADVPL nao imprime nada" [ -z "$out" ]

  touch "$d/FOO.PRW"
  out="$(cd "$d" && HOME="$home" PATH="$fake:$PATH" "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1)"
  check "session-start: FOO.PRW detectado" grep -q "ADVPL/TLPP project detected" <<<"$out"
  n="$(grep -c '/advpl-specialist:' <<<"$out")"
  check "session-start: lista 15 comandos (achou $n)" [ "$n" = 15 ]
  check "session-start: nunca chama claude" [ ! -e "$TMP_DIR/claude-called" ]
  check "session-start: nao apaga cache de plugins" \
    [ -d "$home/.claude/plugins/cache/advpl-specialist-marketplace/advpl-specialist/0.0.1" ]

  rm -f "$d/FOO.PRW"; touch "$d/x.TH"
  out="$(cd "$d" && HOME="$home" "$HOOK_BASH" "$ROOT/hooks/session-start" 2>&1)"
  check "session-start: .TH detectado" grep -q "ADVPL/TLPP project detected" <<<"$out"
}

echo "hook bash: $HOOK_BASH ($("$HOOK_BASH" --version | head -n 1))"
check_hooks_json
check_session_start
if command -v jq >/dev/null 2>&1; then
  MODE=jq NO_JQ=0 run_cases
fi
MODE=builtin NO_JQ=1 run_cases

echo ""
echo "Resultado: $PASS ok, $FAIL falha(s)"
[ "$FAIL" -eq 0 ]
