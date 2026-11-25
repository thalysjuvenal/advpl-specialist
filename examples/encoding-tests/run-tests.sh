#!/usr/bin/env bash
# Fixture-based runner for the standalone UTF-8 -> Windows-1252 converters
#   skills/advpl-code-generation/scripts/convert-encoding.sh
#   skills/advpl-code-generation/scripts/convert-encoding.ps1
# Usage: bash examples/encoding-tests/run-tests.sh   (on macOS, /bin/bash = 3.2)
#
# Every case starts from a fresh copy of fixtures/ plus generated inputs, runs
# convert-encoding.sh with that copy as cwd (relative paths, so the output is
# deterministic) and checks stdout, exit code, stderr and the resulting bytes
# (cmp / od against an oracle that does not depend on the converter; never the
# `file` command).
#
# PowerShell parity: when pwsh or powershell exists (ENC_PS=BINARY forces
# one), every step is repeated with convert-encoding.ps1 in a twin copy, which
# must print the same stdout and stderr byte for byte, exit with the same code
# and leave every file of the copy with the same bytes. Without PowerShell the
# parity checks are reported as skipped. Linux check (GNU coreutils, mawk and
# pwsh 7.4):
#   docker run --rm -v "$PWD":/w -w /w mcr.microsoft.com/dotnet/sdk:8.0 \
#     bash examples/encoding-tests/run-tests.sh
# The unreadable/read-only case is skipped as root (root reads and writes any
# file); add `--user 1000:1000 -e HOME=/tmp` to run it there with pwsh parity.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONV="$PLUGIN_ROOT/skills/advpl-code-generation/scripts/convert-encoding.sh"
CONV_PS1="$PLUGIN_ROOT/skills/advpl-code-generation/scripts/convert-encoding.ps1"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
SH="${BASH:-bash}"            # run the converter with the same bash as this runner
# A locale the system lacks makes every child bash warn on stderr; fall back
# to C so that the stderr checks only see the converters' own messages.
if [ -n "$("$SH" -c : 2>&1)" ]; then export LC_ALL=C; fi
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASS=0; FAIL=0
pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

# Each case collects problems in PROB and reports one ✓/✗ line.
begin_case() { PROB=""; }
expect_that() {   # DESCRIPTION COMMAND...
  local desc="$1" out
  shift
  out=$("$@" 2>&1) || PROB="$PROB; $desc${out:+ [$out]}"
}
end_case() { if [ -z "$PROB" ]; then pass "$1"; else fail "$1:${PROB#;}"; fi; }

# ---- PowerShell --------------------------------------------------------------
PS_WIN=0
case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) PS_WIN=1 ;; esac
PS_BIN="${ENC_PS:-}"
if [ -z "$PS_BIN" ]; then
  # Windows prefers powershell (5.1, the compatibility floor), elsewhere pwsh.
  if [ "$PS_WIN" = 1 ]; then ps_candidates="powershell pwsh"; else ps_candidates="pwsh powershell"; fi
  for c in $ps_candidates; do
    if command -v "$c" >/dev/null 2>&1; then PS_BIN="$c"; break; fi
  done
fi
PS_SCRIPT="$CONV_PS1"
if [ -n "$PS_BIN" ] && [ "$PS_WIN" = 1 ]; then PS_SCRIPT="$(cygpath -w "$CONV_PS1")"; fi
PARITY_RUNS=0

# ---- byte helpers ------------------------------------------------------------
same_file() { cmp "$1" "$2"; }
# decodes_to FILE EXPECTED_UTF8: FILE read as Windows-1252 is EXPECTED_UTF8.
# The decode direction is exact on every iconv (only defined bytes occur).
decodes_to() {
  iconv -f WINDOWS-1252 -t UTF-8 <"$1" >"$1.decoded" && cmp "$1.decoded" "$2"
  local rc=$?
  rm -f "$1.decoded"
  return $rc
}
first3() { head -c 3 "$1" | od -An -tx1 | tr -d ' \n'; }
no_bom() { [ "$(first3 "$1")" != efbbbf ]; }
# shellcheck disable=SC2059  # byte sequences are passed as printf escapes
has_bytes() { LC_ALL=C grep -q "$(printf "$1")" "$2"; }
# strip_bom IN OUT / subst_q IN OUT SEQ...: oracle inputs, built with byte
# operations only (each SEQ, given as printf escapes, becomes "?")
strip_bom() { tail -c +4 "$1" >"$2"; }
subst_q() {
  local in="$1" out="$2" s
  local -a script=()
  shift 2
  # shellcheck disable=SC2059  # each SEQ is a printf escape string
  for s in "$@"; do script[${#script[@]}]="-e"; script[${#script[@]}]="s/$(printf "$s")/?/g"; done
  LC_ALL=C sed "${script[@]}" "$in" >"$out"
}
# no byte >= 0x80 (CR allowed: .gitattributes checks *.ps1 out with CRLF)
ascii_only() { ! LC_ALL=C grep -q "$(printf '[\200-\377]')" "$1"; }
tree_sum() {   # DIR: "PATH CRC SIZE" for every file, sorted
  (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s %s\n' "$f" "$(cksum 2>/dev/null <"$f" || echo unreadable)"
  done)
}

# ---- inputs --------------------------------------------------------------------
# $BASE = fixtures/ + generated inputs; every case copies it.
BASE="$TMP_DIR/base"
make_base() {
  mkdir -p "$BASE"
  cp -R "$FIXTURES_DIR/." "$BASE/"
  # the CP1252 .th rewritten as UTF-8, uppercase extension
  iconv -f WINDOWS-1252 -t UTF-8 <"$BASE/09-tlpp-header.th" >"$BASE/09-utf8.TH"
  # BOM + pure ASCII
  printf '\357\273\277#include "totvs.ch"\nUser Function BOMASC()\nReturn Nil\n' >"$BASE/bom-ascii.prw"
  printf '\357\273\277' >"$BASE/bom-only.prw"   # od -j 3 reaches EOF: empty, not a read error
  # not UTF-8 (RFC 3629), one rule per file, each next to a valid C3 A9: the
  # file is taken as Windows-1252 and left alone (iconv accepts the first one)
  printf '// \364\220\200\200 \365\200\200\200 \303\251\nReturn Nil\n' >"$BASE/bad-utf8.prw"
  printf '// \303\251 \300\257 overlong\n' >"$BASE/bad-overlong.prw"
  printf '// \303\251 \355\240\200 surrogate\n' >"$BASE/bad-surrogate.prw"
  printf '// \303\251 \200 stray continuation\n' >"$BASE/bad-stray.prw"
  printf '// \303\251 truncated \303' >"$BASE/bad-truncated.prw"
  # a 2-byte sequence across byte offset 1024 (macOS 27 iconv fails there)
  LC_ALL=C awk 'BEGIN { for (i = 0; i < 1023; i++) printf "a"; printf "\303\251\n" }' >"$BASE/boundary.prw"
  LC_ALL=C awk 'BEGIN { for (i = 0; i < 1023; i++) printf "a"; printf "\351\n" }' >"$BASE/boundary.expected"
  # directory tree for -r: CRLF, uppercase extension, space, hidden dir, .txt
  mkdir -p "$BASE/tree/sub/deep" "$BASE/tree/.hidden"
  printf '#include "totvs.ch"\r\n// Fun\303\247\303\243o\r\nReturn Nil\r\n' >"$BASE/tree/a.prw"
  printf 'namespace custom.teste.servico\n// a\303\247\303\243o\n' >"$BASE/tree/sub/B.TLPP"
  printf '#define CMSG "a\347\343o"\n' >"$BASE/tree/sub/deep/c.ch"
  printf 'texto com acentua\303\247\303\243o\n' >"$BASE/tree/sub/notes.txt"
  printf '// cache\n' >"$BASE/tree/.hidden/z.prw"
  printf '// espa\303\247o no nome\n' >"$BASE/tree/x y.prw"
  # paths starting with "-": a file and a directory
  printf '// in\303\255cio\n' >"$BASE/-x.prw"
  mkdir -p "$BASE/-dir"
  printf '// a\303\247\303\243o\n' >"$BASE/-dir/y.prw"
  # every code point U+0080..U+FFFF (no surrogates) + 3 astral, one per line,
  # and the expected Windows-1252 result of --translit (the CP1252 table is
  # written here from the code page itself, independently of the converters)
  LC_ALL=C awk -v want="$BASE/sweep.expected" '
    function u(c) {
      if (c < 2048) printf "%c%c", 192 + int(c / 64), 128 + c % 64
      else if (c < 65536) printf "%c%c%c", 224 + int(c / 4096), 128 + int(c / 64) % 64, 128 + c % 64
      else printf "%c%c%c%c", 240 + int(c / 262144), 128 + int(c / 4096) % 64, 128 + int(c / 64) % 64, 128 + c % 64
      printf "\n"
      if (c >= 160 && c <= 255) printf "%c\n", c > want
      else if (c in cp) printf "%c\n", cp[c] > want
      else printf "?\n" > want
    }
    BEGIN {
      n = split("128:8364 130:8218 131:402 132:8222 133:8230 134:8224 135:8225 136:710 137:8240 138:352 139:8249 140:338 142:381 145:8216 146:8217 147:8220 148:8221 149:8226 150:8211 151:8212 152:732 153:8482 154:353 155:8250 156:339 158:382 159:376", t, " ")
      for (i = 1; i <= n; i++) { split(t[i], p, ":"); cp[p[2] + 0] = p[1] + 0 }
      for (c = 128; c <= 65535; c++) if (c < 55296 || c > 57343) u(c)
      u(65536); u(128640); u(1114111)
    }' >"$BASE/sweep.prw"
}

# ---- case machinery ------------------------------------------------------------
# new_case NAME: fresh copies $CS (bash) and $CP (PowerShell twin).
new_case() {
  CASE="$1"
  CS="$TMP_DIR/$1/sh"; CP="$TMP_DIR/$1/ps"
  mkdir -p "$CS"; cp -R "$BASE/." "$CS/"
  if [ -n "$PS_BIN" ]; then mkdir -p "$CP"; cp -R "$BASE/." "$CP/"; fi
  STEP=0
  begin_case
}
# step ARGS...: run the bash converter in $CS (-> $OUT_F, $ERR_F, $RC) and,
# with PowerShell, the .ps1 in $CP; any difference is a problem of the case.
step() {
  STEP=$((STEP + 1))
  OUT_F="$TMP_DIR/$CASE/$STEP.out"; ERR_F="$TMP_DIR/$CASE/$STEP.err"
  (cd "$CS" && "$SH" "$CONV" "$@") >"$OUT_F" 2>"$ERR_F"
  RC=$?
  [ -n "$PS_BIN" ] || return 0
  local po="$TMP_DIR/$CASE/$STEP.ps.out" pe="$TMP_DIR/$CASE/$STEP.ps.err" prc
  (cd "$CP" && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
    "$PS_BIN" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$PS_SCRIPT" "$@") >"$po" 2>"$pe"
  prc=$?
  PARITY_RUNS=$((PARITY_RUNS + 1))
  expect_that "step $STEP parity: exit ps1=$prc bash=$RC" [ "$prc" = "$RC" ]
  expect_that "step $STEP parity: stdout differs (< bash, > ps1)" same_file "$OUT_F" "$po"
  expect_that "step $STEP parity: stderr differs (< bash, > ps1)" same_file "$ERR_F" "$pe"
  tree_sum "$CS" >"$TMP_DIR/$CASE/$STEP.sum.sh"
  tree_sum "$CP" >"$TMP_DIR/$CASE/$STEP.sum.ps"
  expect_that "step $STEP parity: file bytes differ (< bash, > ps1)" \
    diff "$TMP_DIR/$CASE/$STEP.sum.sh" "$TMP_DIR/$CASE/$STEP.sum.ps"
}
expect_stdout() {   # LINE...: stdout of the last step is exactly these lines
  local want="$TMP_DIR/$CASE/$STEP.want"
  if [ $# -eq 0 ]; then : >"$want"; else printf '%s\n' "$@" >"$want"; fi
  expect_that "step $STEP: stdout" diff "$want" "$OUT_F"
}
expect_rc() { expect_that "step $STEP: exit $RC, expected $1" [ "$RC" = "$1" ]; }
expect_no_stderr() { expect_that "step $STEP: stderr not empty" [ ! -s "$ERR_F" ]; }
expect_stderr_has() { expect_that "step $STEP: stderr lacks '$1'" grep -qF -- "$1" "$ERR_F"; }
untouched() {   # FILE...: same bytes as in $BASE
  local f
  for f in "$@"; do expect_that "$f changed" same_file "$BASE/$f" "$CS/$f"; done
}

# ---- cases -----------------------------------------------------------------------
case_strict() {
  new_case strict
  step 01-ascii-puro.prw 02-acentos-ptbr.prw 05-already-cp1252.prw 06-utf8-bom.prw \
    07-not-advpl.txt 08-tlpp-class.tlpp 09-tlpp-header.th 09-utf8.TH bom-ascii.prw bad-utf8.prw \
    bad-overlong.prw bad-surrogate.prw bad-stray.prw bad-truncated.prw boundary.prw bom-only.prw
  expect_rc 0
  expect_no_stderr
  expect_stdout \
    "already-cp1252: 01-ascii-puro.prw" \
    "converted: 02-acentos-ptbr.prw" \
    "already-cp1252: 05-already-cp1252.prw" \
    "converted: 06-utf8-bom.prw" \
    "skipped: 07-not-advpl.txt (not advpl)" \
    "converted: 08-tlpp-class.tlpp" \
    "already-cp1252: 09-tlpp-header.th" \
    "converted: 09-utf8.TH" \
    "converted: bom-ascii.prw" \
    "already-cp1252: bad-utf8.prw" \
    "already-cp1252: bad-overlong.prw" \
    "already-cp1252: bad-surrogate.prw" \
    "already-cp1252: bad-stray.prw" \
    "already-cp1252: bad-truncated.prw" \
    "converted: boundary.prw" \
    "converted: bom-only.prw"
  expect_that "bom-only: not emptied" [ ! -s "$CS/bom-only.prw" ]
  untouched 01-ascii-puro.prw 05-already-cp1252.prw 07-not-advpl.txt 09-tlpp-header.th bad-utf8.prw \
    bad-overlong.prw bad-surrogate.prw bad-stray.prw bad-truncated.prw
  expect_that "boundary: C3 A9 across offset 1024 not E9" same_file "$BASE/boundary.expected" "$CS/boundary.prw"
  expect_that "02: not Windows-1252 of the fixture" decodes_to "$CS/02-acentos-ptbr.prw" "$BASE/02-acentos-ptbr.prw"
  expect_that "02: no byte E1 (a acute)" has_bytes '\341' "$CS/02-acentos-ptbr.prw"
  expect_that "08: not Windows-1252 of the fixture" decodes_to "$CS/08-tlpp-class.tlpp" "$BASE/08-tlpp-class.tlpp"
  strip_bom "$BASE/06-utf8-bom.prw" "$TMP_DIR/strict.06"
  expect_that "06: BOM kept" no_bom "$CS/06-utf8-bom.prw"
  expect_that "06: not Windows-1252 of the fixture" decodes_to "$CS/06-utf8-bom.prw" "$TMP_DIR/strict.06"
  expect_that "09-utf8.TH: not the CP1252 .th fixture" same_file "$BASE/09-tlpp-header.th" "$CS/09-utf8.TH"
  strip_bom "$BASE/bom-ascii.prw" "$TMP_DIR/strict.bom"
  expect_that "bom-ascii: not the ASCII body" same_file "$TMP_DIR/strict.bom" "$CS/bom-ascii.prw"
  # idempotent: a second run finds everything in Windows-1252 already
  step 02-acentos-ptbr.prw 06-utf8-bom.prw 08-tlpp-class.tlpp
  expect_rc 0
  expect_stdout \
    "already-cp1252: 02-acentos-ptbr.prw" \
    "already-cp1252: 06-utf8-bom.prw" \
    "already-cp1252: 08-tlpp-class.tlpp"
  end_case "strict: converted / already-cp1252 / skipped, BOM, .th, invalid UTF-8, 1024-byte boundary, idempotent"
}

case_strict_fails() {
  new_case strict-fails
  step 02-acentos-ptbr.prw 10-emoji-rocket.prw 04-emoji-fail.prw 03-translit-symbols.prw
  expect_rc 1
  expect_no_stderr
  expect_stdout \
    "converted: 02-acentos-ptbr.prw" \
    "failed: 10-emoji-rocket.prw (incompatible char)" \
    "failed: 04-emoji-fail.prw (incompatible char)" \
    "failed: 03-translit-symbols.prw (incompatible char)"
  untouched 10-emoji-rocket.prw 04-emoji-fail.prw 03-translit-symbols.prw
  expect_that "02: not converted next to the failures" decodes_to "$CS/02-acentos-ptbr.prw" "$BASE/02-acentos-ptbr.prw"
  end_case "strict: emoji, kanji and arrows fail, files byte-identical, exit 1"
}

case_translit() {
  new_case translit
  step --translit 03-translit-symbols.prw 04-emoji-fail.prw 10-emoji-rocket.prw 02-acentos-ptbr.prw 06-utf8-bom.prw
  expect_rc 0
  expect_no_stderr
  expect_stdout \
    "translit: 03-translit-symbols.prw (2)" \
    "translit: 04-emoji-fail.prw (2)" \
    "translit: 10-emoji-rocket.prw (1)" \
    "converted: 02-acentos-ptbr.prw" \
    "converted: 06-utf8-bom.prw"
  subst_q "$BASE/03-translit-symbols.prw" "$TMP_DIR/tr.03" '\342\206\222' '\342\211\244'
  subst_q "$BASE/04-emoji-fail.prw" "$TMP_DIR/tr.04" '\346\227\245' '\346\234\254'
  subst_q "$BASE/10-emoji-rocket.prw" "$TMP_DIR/tr.10" '\360\237\232\200'
  expect_that "03: arrows not one ? each" decodes_to "$CS/03-translit-symbols.prw" "$TMP_DIR/tr.03"
  expect_that "04: kanji not one ? each" decodes_to "$CS/04-emoji-fail.prw" "$TMP_DIR/tr.04"
  expect_that "10: emoji not one ?" decodes_to "$CS/10-emoji-rocket.prw" "$TMP_DIR/tr.10"
  step --translit 03-translit-symbols.prw
  expect_rc 0
  expect_stdout "already-cp1252: 03-translit-symbols.prw"
  end_case "--translit: one ? per code point, count reported, idempotent"
}

case_dry_run() {
  new_case dry-run
  step --dry-run 02-acentos-ptbr.prw 06-utf8-bom.prw 04-emoji-fail.prw 07-not-advpl.txt
  expect_rc 1
  expect_no_stderr
  expect_stdout \
    "converted: 02-acentos-ptbr.prw" \
    "converted: 06-utf8-bom.prw" \
    "failed: 04-emoji-fail.prw (incompatible char)" \
    "skipped: 07-not-advpl.txt (not advpl)"
  untouched 02-acentos-ptbr.prw 06-utf8-bom.prw 04-emoji-fail.prw 07-not-advpl.txt
  step --dry-run --translit -r 03-translit-symbols.prw tree
  expect_rc 0
  expect_stdout \
    "translit: 03-translit-symbols.prw (2)" \
    "already-cp1252: tree/.hidden/z.prw" \
    "converted: tree/a.prw" \
    "converted: tree/sub/B.TLPP" \
    "already-cp1252: tree/sub/deep/c.ch" \
    "converted: tree/x y.prw"
  untouched 03-translit-symbols.prw tree/a.prw "tree/sub/B.TLPP" "tree/x y.prw"
  end_case "--dry-run: same report and exit code, nothing written"
}

case_recursive() {
  new_case recursive
  step -r tree/
  expect_rc 0
  expect_no_stderr
  expect_stdout \
    "already-cp1252: tree/.hidden/z.prw" \
    "converted: tree/a.prw" \
    "converted: tree/sub/B.TLPP" \
    "already-cp1252: tree/sub/deep/c.ch" \
    "converted: tree/x y.prw"
  untouched tree/sub/notes.txt tree/sub/deep/c.ch tree/.hidden/z.prw
  expect_that "a.prw: not Windows-1252 with CRLF kept" decodes_to "$CS/tree/a.prw" "$BASE/tree/a.prw"
  expect_that "B.TLPP: not Windows-1252" decodes_to "$CS/tree/sub/B.TLPP" "$BASE/tree/sub/B.TLPP"
  # options may follow the paths (GNU style); second run: nothing left to do
  step 01-ascii-puro.prw -r tree
  expect_rc 0
  expect_no_stderr
  expect_stdout \
    "already-cp1252: 01-ascii-puro.prw" \
    "already-cp1252: tree/.hidden/z.prw" \
    "already-cp1252: tree/a.prw" \
    "already-cp1252: tree/sub/B.TLPP" \
    "already-cp1252: tree/sub/deep/c.ch" \
    "already-cp1252: tree/x y.prw"
  end_case "-r: ADVPL files only, sorted, hidden dirs, trailing slash, CRLF"
}

case_usage() {
  new_case usage
  step
  expect_rc 2
  expect_stdout
  expect_stderr_has "usage: convert-encoding [--dry-run] [--translit] [-r] PATH..."
  step --bogus 02-acentos-ptbr.prw
  expect_rc 2
  expect_stdout
  expect_stderr_has "unknown option: --bogus"
  step 02-acentos-ptbr.prw missing.prw
  expect_rc 2
  expect_stdout
  expect_stderr_has "cannot read PATH: missing.prw"
  step tree
  expect_rc 2
  expect_stdout
  expect_stderr_has "tree is a directory (use -r)"
  untouched 02-acentos-ptbr.prw tree/a.prw
  step -- 02-acentos-ptbr.prw
  expect_rc 0
  expect_stdout "converted: 02-acentos-ptbr.prw"
  step --help
  expect_rc 0
  expect_stdout "usage: convert-encoding [--dry-run] [--translit] [-r] PATH..."
  end_case "usage: exit 2 before touching any file, --, --help"
}

case_sweep() {
  new_case sweep
  step sweep.prw
  expect_rc 1
  expect_stdout "failed: sweep.prw (incompatible char)"
  untouched sweep.prw
  step --translit sweep.prw
  expect_rc 0
  expect_no_stderr
  expect_stdout "translit: sweep.prw (63240)"
  expect_that "sweep: result differs from the CP1252 table" same_file "$BASE/sweep.expected" "$CS/sweep.prw"
  end_case "sweep U+0080..U+FFFF + astral: exactly the 123 CP1252 chars kept"
}

case_dash_paths() {
  new_case dash-paths
  step -x.prw
  expect_rc 2
  expect_stdout
  expect_stderr_has "unknown option: -x.prw"
  untouched -x.prw
  step -- -x.prw
  expect_rc 0
  expect_no_stderr
  expect_stdout "converted: -x.prw"
  expect_that "-x.prw: not Windows-1252" decodes_to "$CS/-x.prw" "$BASE/-x.prw"
  step -r -- -dir
  expect_rc 0
  expect_no_stderr
  expect_stdout "converted: -dir/y.prw"
  expect_that "-dir/y.prw: not Windows-1252" decodes_to "$CS/-dir/y.prw" "$BASE/-dir/y.prw"
  end_case "paths starting with -: option without --, converted after -- (file and -r dir)"
}

# set_mode MODE PATH: chmod in the bash copy and in the PowerShell twin
set_mode() {
  chmod "$1" "$CS/$2"
  if [ -n "$PS_BIN" ]; then chmod "$1" "$CP/$2"; fi
}

case_unreadable() {
  if [ "$(id -u)" = 0 ]; then
    echo "  - unreadable / read-only files: skipped (running as root, which reads and writes any file)"
    return 0
  fi
  if [ "$PS_WIN" = 1 ]; then
    # Git Bash chmod on NTFS only toggles the read-only attribute: mode 000
    # leaves the file readable, so the "read error" half cannot be staged.
    echo "  - unreadable / read-only files: skipped (Windows: chmod cannot make a file unreadable)"
    return 0
  fi
  new_case unreadable
  set_mode 000 tree/sub/B.TLPP
  set_mode 444 "tree/x y.prw"
  step tree/sub/B.TLPP
  expect_rc 2
  expect_stdout
  expect_stderr_has "cannot read PATH: tree/sub/B.TLPP"
  step -r tree
  expect_rc 1
  expect_no_stderr
  expect_stdout \
    "already-cp1252: tree/.hidden/z.prw" \
    "converted: tree/a.prw" \
    "failed: tree/sub/B.TLPP (read error)" \
    "already-cp1252: tree/sub/deep/c.ch" \
    "failed: tree/x y.prw (write error)"
  set_mode 644 tree/sub/B.TLPP
  set_mode 644 "tree/x y.prw"
  untouched tree/sub/B.TLPP "tree/x y.prw"
  end_case "-r: unreadable file = read error, read-only file = write error, run goes on, exit 1"
}

# ---- run -------------------------------------------------------------------------
echo "converter: $CONV"
echo "bash: $SH ($("$SH" --version | head -n 1))"
if [ -n "$PS_BIN" ]; then
  echo "PowerShell parity: on ($PS_BIN)"
else
  echo "PowerShell parity: skipped (no pwsh/powershell found; convert-encoding.ps1 not exercised)"
fi
begin_case
expect_that "convert-encoding.sh missing" [ -f "$CONV" ]
expect_that "convert-encoding.ps1 missing" [ -f "$CONV_PS1" ]
expect_that "old hooks/lib/convert-encoding.sh still present" [ ! -e "$PLUGIN_ROOT/hooks/lib/convert-encoding.sh" ]
expect_that "convert-encoding.ps1 is not ASCII-only" ascii_only "$CONV_PS1"
end_case "layout: both scripts in the skill, old lib removed, .ps1 ASCII-only"
make_base
case_strict
case_strict_fails
case_translit
case_dry_run
case_recursive
case_usage
case_sweep
case_dash_paths
case_unreadable

echo ""
if [ -n "$PS_BIN" ]; then
  echo "PowerShell parity: $PARITY_RUNS steps compared with $PS_BIN"
else
  echo "PowerShell parity: skipped"
fi
echo "============================="
echo "TOTAL: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
