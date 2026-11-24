#!/usr/bin/env bash
# Fixture-based runner for skills/advpl-code-review/scripts/advpl-lint.sh
# Usage: bash tests/lint/run-tests.sh   (on macOS, /bin/bash exercises bash 3.2)
#
# Fixture convention: a line that must produce finding(s) ends with
# "// expect: ID[,ID]"; a line without "expect" must produce none.
# Scope per fixture (C17): file-scope.* runs with --scope all; the others
# (rules.*, fffd.*) run with --scope line. Fixture sets ignore repeated
# findings, so finding COUNTS are checked by dedicated cases (found_list).
#
# PowerShell parity: when pwsh or powershell exists (LINT_PS=BINARY forces
# one), every engine run is repeated with advpl-lint.ps1, which must print the
# same stdout byte for byte, exit with the same code and write the same stderr
# (its usage line names advpl-lint.ps1). Without PowerShell those checks are
# skipped and reported as skipped. Linux check (bash + mawk + pwsh 7):
#   docker run --rm -v "$PWD":/w -w /w mcr.microsoft.com/powershell \
#     bash tests/lint/run-tests.sh                       (x86_64 hosts)
#   docker run --rm -v "$PWD":/w -w /w mcr.microsoft.com/dotnet/sdk:8.0 \
#     bash tests/lint/run-tests.sh                       (arm64 hosts: the
#   powershell image has no arm64 variant and pwsh crashes under emulation)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINT="$PLUGIN_ROOT/skills/advpl-code-review/scripts/advpl-lint.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
IGNORE_DIR="$FIXTURES_DIR/ignore-cases"
SH="${BASH:-bash}"            # run the engine with the same bash as this runner
# A locale the system lacks (LC_ALL=en_US.UTF-8 in the PowerShell Docker image)
# makes every child bash warn on stderr; fall back to C so that the stderr
# checks only see the engines' own messages.
if [ -n "$("$SH" -c : 2>&1)" ]; then export LC_ALL=C; fi
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
RUN_DIR="$TMP_DIR/cwd"        # empty cwd: no stray ./.advpl-specialist-ignore
mkdir -p "$RUN_DIR" "$TMP_DIR/crlf"

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

# run_lint_in DIR NAME [ARGS...] -> $TMP_DIR/NAME.{out,err,rc}
# Every run is followed by the advpl-lint.ps1 parity check (see parity_check);
# NO_PARITY=1 skips it (timed runs call parity_check themselves).
run_lint_in() {
  local dir="$1" name="$2"
  shift 2
  (cd "$dir" && "$SH" "$LINT" "$@") >"$TMP_DIR/$name.out" 2>"$TMP_DIR/$name.err"
  echo "$?" >"$TMP_DIR/$name.rc"
  [ -n "${NO_PARITY:-}" ] || parity_check "$dir" "$name" "$@"
}
run_lint() { run_lint_in "$RUN_DIR" "$@"; }
rc_of() { cat "$TMP_DIR/$1.rc"; }
suppressed_of() { tail -n 1 "$TMP_DIR/$1.out" | awk '{ print $6 }'; }

# Finding lines of run NAME as TSV: file, line, severity, id.
parse_findings() {
  LC_ALL=C awk '
    match($0, /:[0-9]+: (error|warning) [A-Za-z0-9_]+ /) {
      f = substr($0, 1, RSTART - 1)
      split(substr($0, RSTART + 1, RLENGTH - 1), w, /[: ]+/)
      print f "\t" w[1] "\t" w[2] "\t" w[3]
    }' "$TMP_DIR/$1.out"
}
# Set "LINE:ID" reported for FILE by run NAME.
found_set() {
  parse_findings "$1" | F="$2" LC_ALL=C awk -F '\t' '$1 == ENVIRON["F"] { print $2 ":" $4 }' | LC_ALL=C sort -u
}
# Same as found_set but keeps duplicates, so finding COUNTS are compared.
found_list() {
  parse_findings "$1" | F="$2" LC_ALL=C awk -F '\t' '$1 == ENVIRON["F"] { print $2 ":" $4 }' | LC_ALL=C sort
}
# Set "LINE:ID" declared by the "// expect:" annotations of a fixture.
expected_set() {
  LC_ALL=C awk '
    match($0, /\/\/ expect:[ \t]*[A-Za-z0-9_,]+/) {
      s = substr($0, RSTART, RLENGTH)
      sub(/^\/\/ expect:[ \t]*/, "", s)
      n = split(s, ids, ",")
      for (i = 1; i <= n; i++) if (ids[i] != "") print FNR ":" ids[i]
    }' "$1" | LC_ALL=C sort -u
}
count_id() { parse_findings "$1" | ID="$2" awk -F '\t' '$4 == ENVIRON["ID"] { c++ } END { print c + 0 }'; }

# Output contract: finding lines grouped by file and sorted by line then ID,
# summary as the last line with counts matching the findings, exit 1 iff errors.
wellformed() {
  RC="$(rc_of "$1")" LC_ALL=C awk '
    { l[NR] = $0 }
    END {
      if (NR == 0) { print "empty output (exit " ENVIRON["RC"] ")"; exit 1 }
      e = 0; w = 0; cur = ""
      for (i = 1; i < NR; i++) {
        if (!match(l[i], /:[0-9]+: (error|warning) [A-Za-z0-9_]+ [^ ]/)) { print "malformed: " l[i]; exit 1 }
        f = substr(l[i], 1, RSTART - 1)
        split(substr(l[i], RSTART + 1), x, /[: ]+/)
        if (x[2] == "error") e++; else w++
        if (f != cur) {
          if (f in seen) { print "file not grouped: " f; exit 1 }
          seen[f] = 1; cur = f; pl = -1; pid = ""
        }
        if (x[1] + 0 < pl || (x[1] + 0 == pl && x[3] < pid)) { print "not sorted: " l[i]; exit 1 }
        pl = x[1] + 0; pid = x[3]
      }
      if (l[NR] !~ /^advpl-lint: [0-9]+ error\(s\), [0-9]+ warning\(s\), [0-9]+ suppressed$/) { print "bad summary: " l[NR]; exit 1 }
      split(l[NR], y, " ")
      if (y[2] + 0 != e || y[4] + 0 != w) { print "summary " y[2] "/" y[4] " != findings " e "/" w; exit 1 }
      if (ENVIRON["RC"] + 0 != (e > 0 ? 1 : 0)) { print "exit " ENVIRON["RC"] " with " e " error(s)"; exit 1 }
    }' "$TMP_DIR/$1.out"
}
same_file() { cmp -s "$1" "$2" || { diff "$1" "$2" | head -20; return 1; }; }
no_stderr() { [ ! -s "$TMP_DIR/$1.err" ] || { head -5 "$TMP_DIR/$1.err"; return 1; }; }

# ---- advpl-lint.ps1 parity ---------------------------------------------------
LINT_PS1="$PLUGIN_ROOT/skills/advpl-code-review/scripts/advpl-lint.ps1"
PS_WIN=0
case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) PS_WIN=1 ;; esac
PS_BIN="${LINT_PS:-}"
if [ -z "$PS_BIN" ]; then
  # Windows prefers powershell (5.1, the compatibility floor), elsewhere pwsh.
  if [ "$PS_WIN" = 1 ]; then ps_candidates="powershell pwsh"; else ps_candidates="pwsh powershell"; fi
  for c in $ps_candidates; do
    if command -v "$c" >/dev/null 2>&1; then PS_BIN="$c"; break; fi
  done
fi
PARITY_RUNS=0

# Windows (Git Bash; not exercised locally): absolute POSIX paths are handed
# to PowerShell as C:/... (cygpath -m) with MSYS path conversion off, and the
# converted paths in its output are mapped back before comparing.
to_win_args() {   # ARGS... -> WIN_ARGS, $TMP_DIR/winmap ("WINPATH<TAB>PATH")
  local a w
  WIN_ARGS=()
  : >"$TMP_DIR/winmap"
  for a in "$@"; do
    case "$a" in
      /*) w="$(cygpath -m "$a")"; printf '%s\t%s\n' "$w" "$a" >>"$TMP_DIR/winmap" ;;
      *) w="$a" ;;
    esac
    WIN_ARGS[${#WIN_ARGS[@]}]="$w"
  done
}
from_win() {   # FILE: replace every converted path listed in winmap
  [ -s "$TMP_DIR/winmap" ] || return 0
  LC_ALL=C awk -F '\t' '
    NR == FNR { from[NR] = $1; to[NR] = $2; n = NR; next }
    {
      s = $0
      for (i = 1; i <= n; i++) {
        out = ""
        while ((k = index(s, from[i])) > 0) {
          out = out substr(s, 1, k - 1) to[i]
          s = substr(s, k + length(from[i]))
        }
        s = out s
      }
      print s
    }' "$TMP_DIR/winmap" "$1" >"$1.map" && mv "$1.map" "$1"
}

# parity_check DIR NAME ARGS...: run advpl-lint.ps1 like run NAME and compare
# stdout (bytes), exit code and stderr (usage line normalized).
parity_check() {
  [ -n "$PS_BIN" ] || return 0
  local dir="$1" name="$2" script="$LINT_PS1" ps="$2.ps" a label=""
  shift 2
  for a in "$@"; do
    a="${a#"$TMP_DIR"/}"
    a="${a#"$FIXTURES_DIR"/}"
    label="$label $a"
  done
  if [ "$PS_WIN" = 1 ]; then
    to_win_args "$@"
    set -- ${WIN_ARGS[@]+"${WIN_ARGS[@]}"}
    script="$(cygpath -w "$LINT_PS1")"
  fi
  (cd "$dir" && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
    "$PS_BIN" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$script" "$@") \
    >"$TMP_DIR/$ps.out" 2>"$TMP_DIR/$ps.err"
  echo "$?" >"$TMP_DIR/$ps.rc"
  if [ "$PS_WIN" = 1 ]; then
    from_win "$TMP_DIR/$ps.out"
    from_win "$TMP_DIR/$ps.err"
  fi
  LC_ALL=C sed 's/advpl-lint\.ps1/advpl-lint.sh/' "$TMP_DIR/$ps.err" >"$TMP_DIR/$ps.errn"
  PARITY_RUNS=$((PARITY_RUNS + 1))
  begin_case
  expect_that "exit $(rc_of "$ps"), bash $(rc_of "$name")" [ "$(rc_of "$ps")" = "$(rc_of "$name")" ]
  expect_that "stdout differs (< bash, > ps1)" same_file "$TMP_DIR/$name.out" "$TMP_DIR/$ps.out"
  expect_that "stderr differs (< bash, > ps1)" same_file "$TMP_DIR/$name.err" "$TMP_DIR/$ps.errn"
  end_case "parity [$name]:$label"
}

if [ -n "$PS_BIN" ]; then
  echo "PowerShell parity: on ($PS_BIN)"
else
  echo "PowerShell parity: skipped (no pwsh/powershell found; advpl-lint.ps1 not exercised)"
fi

check_fixture() {   # LABEL NAME FILE EXPECT_SOURCE SCOPE
  local label="$1" name="$2" file="$3" src="$4" scope="$5"
  run_lint "$name" --scope "$scope" "$file"
  expected_set "$src" >"$TMP_DIR/$name.exp"
  found_set "$name" "$file" >"$TMP_DIR/$name.got"
  begin_case
  expect_that "output contract" wellformed "$name"
  expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/$name.exp" "$TMP_DIR/$name.got"
  expect_that "no stderr" no_stderr "$name"
  end_case "$label ($(wc -l <"$TMP_DIR/$name.exp" | tr -d ' ') expected findings, --scope $scope)"
}

echo "=== Fixtures (// expect: annotations) ==="
for fixture in "$FIXTURES_DIR"/*.prw "$FIXTURES_DIR"/*.prx "$FIXTURES_DIR"/*.tlpp "$FIXTURES_DIR"/*.th; do
  [ -f "$fixture" ] || continue
  base="$(basename "$fixture")"
  case "$base" in file-scope.*) scope=all ;; *) scope=line ;; esac
  check_fixture "$base" "fx-$base" "$fixture" "$fixture" "$scope"
  LC_ALL=C awk '{ printf "%s\r\n", $0 }' "$fixture" >"$TMP_DIR/crlf/$base"
  check_fixture "$base (CRLF copy)" "fx-crlf-$base" "$TMP_DIR/crlf/$base" "$fixture" "$scope"
done

F="$FIXTURES_DIR/rules.prw"
run_lint base --scope line "$F"
found_set base "$F" >"$TMP_DIR/base.got"

echo "=== CLI and output ==="
cp "$F" "$TMP_DIR/RULES.PRW"
run_lint upper --scope line "$TMP_DIR/RULES.PRW"
found_set upper "$TMP_DIR/RULES.PRW" >"$TMP_DIR/upper.got"
begin_case
expect_that "output contract" wellformed upper
expect_that "findings differ from rules.prw" same_file "$TMP_DIR/base.got" "$TMP_DIR/upper.got"
end_case "uppercase extension .PRW is linted"

cp "$F" "$TMP_DIR/rules.txt"
run_lint other "$TMP_DIR/rules.txt"
begin_case
expect_that "stdout is not just the zero summary" [ "$(cat "$TMP_DIR/other.out")" = "advpl-lint: 0 error(s), 0 warning(s), 0 suppressed" ]
expect_that "exit 0" [ "$(rc_of other)" = 0 ]
expect_that "no stderr" no_stderr other
end_case "non-ADVPL extension is skipped silently"

run_lint multi --scope line "$F" "$TMP_DIR/crlf/rules.prw"
begin_case
expect_that "output contract" wellformed multi
expect_that "first finding is not from the first FILE" [ "$(parse_findings multi | head -n 1 | cut -f 1)" = "$F" ]
expect_that "last finding is not from the second FILE" [ "$(parse_findings multi | tail -n 1 | cut -f 1)" = "$TMP_DIR/crlf/rules.prw" ]
expect_that "errors are not summed" [ "$(parse_findings multi | wc -l | tr -d ' ')" = "$(( $(parse_findings base | wc -l) * 2 ))" ]
end_case "several FILEs: argument order and summed summary"

first_line="$(cut -d: -f1 "$TMP_DIR/fx-rules.prw.exp" | sort -n | head -n 1)"
last_line="$(cut -d: -f1 "$TMP_DIR/fx-rules.prw.exp" | sort -n | tail -n 1)"
printf '\nabc\n%s\r\n %s \n1\n' "$first_line" "$last_line" >"$TMP_DIR/lines.txt"
run_lint lines --scope line --lines-file "$TMP_DIR/lines.txt" "$F"
found_set lines "$F" >"$TMP_DIR/lines.got"
FIRST="$first_line" LAST="$last_line" awk -F: '$1 == ENVIRON["FIRST"] || $1 == ENVIRON["LAST"]' "$TMP_DIR/fx-rules.prw.exp" >"$TMP_DIR/lines.exp"
begin_case
expect_that "output contract" wellformed lines
expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/lines.exp" "$TMP_DIR/lines.got"
end_case "--lines-file keeps only listed lines (blank/non-numeric/CRLF tolerated)"

printf 'ADV001\tfatal\tline\tforbid\tcode\ti\t*\tx\t-\tmsg\t-\n' >"$TMP_DIR/bad.rules"
usage_case() {   # LABEL STDERR_FRAGMENT ARGS...
  local label="$1" fragment="$2"
  shift 2
  run_lint usage "$@"
  begin_case
  expect_that "exit $(rc_of usage), want 2" [ "$(rc_of usage)" = 2 ]
  expect_that "stdout not empty" [ ! -s "$TMP_DIR/usage.out" ]
  expect_that "stderr lacks '$fragment'" grep -q -e "$fragment" "$TMP_DIR/usage.err"
  end_case "usage error: $label"
}
usage_case "no FILE" "no FILE given"
usage_case "unknown option" "unknown option: --bogus" --bogus "$F"
usage_case "invalid --scope value" "invalid --scope value: file" --scope file "$F"
usage_case "option without value" "option --rules requires a value" --scope line --rules
usage_case "nonexistent FILE" "cannot read FILE: " "$TMP_DIR/missing.prw"
usage_case "unreadable --rules" "cannot read rules file: " --rules "$TMP_DIR/missing.rules" "$F"
usage_case "nonexistent --lines-file" "cannot read lines file: " --lines-file "$TMP_DIR/missing.txt" "$F"
usage_case "invalid rule in --rules" "invalid rule at .*bad.rules:1" --rules "$TMP_DIR/bad.rules" "$F"
printf 'ADV019\terror\tline\trequire\traw\ti\t*\tx\t-\tmsg\t-\n' >"$TMP_DIR/bad-scope.rules"
printf 'ADV020\twarn\tfile\tbalance\tcode\ti\t*\tx\t-\tmsg\t-\n' >"$TMP_DIR/bad-balance.rules"
printf 'ADV021\twarn\tfile\tundeclared\traw\ti\t*\tx\t-\tmsg\t-\n' >"$TMP_DIR/bad-undecl.rules"
usage_case "require/balance/undeclared with SCOPE=line" "invalid rule at .*bad-scope.rules:1" --rules "$TMP_DIR/bad-scope.rules" "$F"
usage_case "balance without REGEX2" "invalid rule at .*bad-balance.rules:1" --rules "$TMP_DIR/bad-balance.rules" "$F"
usage_case "undeclared with TARGET=raw" "invalid rule at .*bad-undecl.rules:1" --rules "$TMP_DIR/bad-undecl.rules" "$F"
usage_case "nonexistent --ignore-file" "cannot read ignore file: " --ignore-file "$TMP_DIR/missing.ignore" "$F"
usage_case "--ignore-file is a directory" "cannot read ignore file: " --ignore-file "$TMP_DIR" "$F"

echo "=== Ignore file ==="
run_lint ign-valid --scope line --ignore-file "$IGNORE_DIR/valid.advpl-specialist-ignore" "$F"
found_set ign-valid "$F" >"$TMP_DIR/ign-valid.got"
grep -v -e ':ADV003$' -e ':ADV004$' -e ':ADV017$' "$TMP_DIR/base.got" >"$TMP_DIR/ign-valid.exp"
want=$(( $(count_id base ADV003) + $(count_id base ADV004) + $(count_id base ADV017) ))
begin_case
expect_that "output contract" wellformed ign-valid
expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/ign-valid.exp" "$TMP_DIR/ign-valid.got"
expect_that "suppressed $(suppressed_of ign-valid), want $want" [ "$(suppressed_of ign-valid)" = "$want" ]
expect_that "nothing to suppress in baseline" [ "$want" -gt 0 ]
expect_that "no stderr" no_stderr ign-valid
end_case "valid: rule ADV003, rule CA2022 (REF code) and function MA410IMPOS suppress ADV003/ADV004/ADV017"

# Generated rules (ADV017/ADV018): field/function directives act on the real rules file.
printf 'MA410IMPOS(1)\nSA1->A1_NOMEX := "x"\n' >"$TMP_DIR/gen.prw"
run_lint gen-base --scope line "$TMP_DIR/gen.prw"
printf 'field a1_nomex\nfunction ma410impos\n' >"$TMP_DIR/gen.ignore"
run_lint gen-ign --scope line --ignore-file "$TMP_DIR/gen.ignore" "$TMP_DIR/gen.prw"
begin_case
expect_that "baseline reports both generated rules" [ "$(found_set gen-base "$TMP_DIR/gen.prw" | tr '\n' ' ')" = "1:ADV017 2:ADV018 " ]
expect_that "field A1_NOMEX + function MA410IMPOS suppress both" [ "$(cat "$TMP_DIR/gen-ign.out")" = "advpl-lint: 0 error(s), 0 warning(s), 2 suppressed" ]
end_case "generated ADV017/ADV018 honour function/field ignore directives"

mkdir -p "$TMP_DIR/proj"
cp "$IGNORE_DIR/valid.advpl-specialist-ignore" "$TMP_DIR/proj/.advpl-specialist-ignore"
run_lint_in "$TMP_DIR/proj" ign-default --scope line "$F"
begin_case
expect_that "stdout differs from --ignore-file run" same_file "$TMP_DIR/ign-valid.out" "$TMP_DIR/ign-default.out"
end_case "default ./.advpl-specialist-ignore is read from the current directory"

run_lint ign-empty --scope line --ignore-file "$IGNORE_DIR/empty.advpl-specialist-ignore" "$F"
begin_case
expect_that "stdout differs from baseline" same_file "$TMP_DIR/base.out" "$TMP_DIR/ign-empty.out"
expect_that "exit differs from baseline" [ "$(rc_of ign-empty)" = "$(rc_of base)" ]
expect_that "no stderr" no_stderr ign-empty
end_case "empty ignore file changes nothing"

printf '#include "totvs.ch"\n' >"$TMP_DIR/clean.prw"
run_lint ign-absent "$TMP_DIR/clean.prw"
begin_case
expect_that "stdout is not just the zero summary" [ "$(cat "$TMP_DIR/ign-absent.out")" = "advpl-lint: 0 error(s), 0 warning(s), 0 suppressed" ]
expect_that "exit $(rc_of ign-absent), want 0" [ "$(rc_of ign-absent)" = 0 ]
expect_that "no stderr" no_stderr ign-absent
end_case "default ./.advpl-specialist-ignore absent: silent, exit 0"

mkdir -p "$TMP_DIR/dirproj/.advpl-specialist-ignore"
run_lint_in "$TMP_DIR/dirproj" ign-defdir "$TMP_DIR/clean.prw"
begin_case
expect_that "stdout differs from the absent-default run" same_file "$TMP_DIR/ign-absent.out" "$TMP_DIR/ign-defdir.out"
expect_that "exit $(rc_of ign-defdir), want 0" [ "$(rc_of ign-defdir)" = 0 ]
expect_that "no stderr" no_stderr ign-defdir
end_case "default ./.advpl-specialist-ignore that is a directory is skipped silently"

run_lint ign-unknown --scope line --ignore-file "$IGNORE_DIR/unknown-crlf.advpl-specialist-ignore" "$F"
found_set ign-unknown "$F" >"$TMP_DIR/ign-unknown.got"
grep -v ':ADV005$' "$TMP_DIR/base.got" >"$TMP_DIR/ign-unknown.exp"
begin_case
expect_that "output contract" wellformed ign-unknown
expect_that "exit $(rc_of ign-unknown) differs from baseline $(rc_of base)" [ "$(rc_of ign-unknown)" = "$(rc_of base)" ]
expect_that "no stderr warning naming the directive" grep -q bogus "$TMP_DIR/ign-unknown.err"
expect_that "findings differ (CRLF 'rule ADV005' must apply)" same_file "$TMP_DIR/ign-unknown.exp" "$TMP_DIR/ign-unknown.got"
expect_that "suppressed $(suppressed_of ign-unknown), want $(count_id base ADV005)" [ "$(suppressed_of ign-unknown)" = "$(count_id base ADV005)" ]
end_case "unknown directive + CRLF: stderr warning, exit unchanged, other lines apply"

total="$(parse_findings base | wc -l | tr -d ' ')"
path_case() {   # GLOB SHOULD_MATCH(1|0)
  printf 'path %s\n' "$1" >"$TMP_DIR/path.ignore"
  run_lint path --scope line --ignore-file "$TMP_DIR/path.ignore" "$F"
  begin_case
  expect_that "output contract" wellformed path
  if [ "$2" = 1 ]; then
    expect_that "suppressed $(suppressed_of path), want $total" [ "$(suppressed_of path)" = "$total" ]
    end_case "path $1 matches $F"
  else
    expect_that "stdout differs from baseline" same_file "$TMP_DIR/base.out" "$TMP_DIR/path.out"
    end_case "path $1 does not match"
  fi
}
path_case '**/fixtures/rules.prw' 1
path_case 'fixtures/*.prw' 1
path_case '**/rules.pr?' 1
path_case 'lint/**/*.prw' 1
path_case 'lint/*.prw' 0
path_case '*.tlpp' 0
path_case 'fixtures' 0
path_case 'rules' 0

echo "=== Generic rule mechanics (custom --rules) ==="
{
  echo "# custom rules: generic engine behaviour (rule order differs from ID order)"
  printf 'ADV018\twarn\tline\tforbid\tcode\ti\t*\t%s\t%s\tcampo fora do dicionario\t-\n' \
    '(^|[^a-z0-9_])(a1)_[a-z0-9]+' '^a1_(cod|nome)$'
  printf 'ADV017\twarn\tline\tforbid\tcode\ti\tprw,prx\t%s\t-\tfuncao sem suporte\tCA9999\n' \
    '(^|[^a-z0-9_])ma410impos[ \t]*\('
  printf 'ADV020\terror\tline\tforbid\tcode\ti\ttlpp,th\t%s\t-\tsomente tlpp\t-\n' 'ma410impos'
  printf 'ADV019\terror\tfile\trequire\traw\tc\tprw\t%s\t-\trequire de teste\t-\n' '^#include'
} >"$TMP_DIR/custom.rules"
printf '%s\n' \
  'MA410IMPOS(SA1->A1_XPROJ)' \
  'SA1->A1_NOME := MA410IMPOS(MA410IMPOS(1))' \
  'cX := "A1_XPROJ" + u_MA410IMPOS(1)' >"$TMP_DIR/custom.prw"
CF="$TMP_DIR/custom.prw"
run_lint custom --rules "$TMP_DIR/custom.rules" "$CF"
found_set custom "$CF" >"$TMP_DIR/custom.got"
printf '%s\n' 1:ADV017 1:ADV018 1:ADV019 2:ADV017 >"$TMP_DIR/custom.exp"
begin_case
expect_that "output contract" wellformed custom
expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/custom.exp" "$TMP_DIR/custom.got"
expect_that "two matches on one line are not two findings" [ "$(count_id custom ADV017)" = 3 ]
expect_that "first line format" [ "$(head -n 1 "$TMP_DIR/custom.out")" = "$CF:1: warning ADV017 funcao sem suporte [CA9999]" ]
expect_that "REF '-' must omit the brackets" [ "$(sed -n 2p "$TMP_DIR/custom.out")" = "$CF:1: warning ADV018 campo fora do dicionario" ]
expect_that "file finding not sorted by ID among the line-1 findings" [ "$(sed -n 3p "$TMP_DIR/custom.out")" = "$CF:1: error ADV019 require de teste" ]
expect_that "summary" [ "$(tail -n 1 "$TMP_DIR/custom.out")" = "advpl-lint: 1 error(s), 4 warning(s), 0 suppressed" ]
end_case "forbid: one finding per match, REGEX2 exception on trimmed text, EXTS; require finding sorted by ID on line 1"

printf 'field a1_xproj\nfunction Ma410Impos\n' >"$TMP_DIR/custom.ignore"
run_lint custom-ign --rules "$TMP_DIR/custom.rules" --ignore-file "$TMP_DIR/custom.ignore" "$CF"
begin_case
expect_that "only the require finding is left" [ "$(found_set custom-ign "$CF")" = "1:ADV019" ]
expect_that "summary" [ "$(tail -n 1 "$TMP_DIR/custom-ign.out")" = "advpl-lint: 1 error(s), 0 warning(s), 4 suppressed" ]
end_case "field X suppresses ADV018 and function X suppresses ADV017 (any case)"

printf 'field ma410impos\nfunction a1_xproj\n' >"$TMP_DIR/custom-swap.ignore"
run_lint custom-swap --rules "$TMP_DIR/custom.rules" --ignore-file "$TMP_DIR/custom-swap.ignore" "$CF"
begin_case
expect_that "stdout differs from the run without ignore" same_file "$TMP_DIR/custom.out" "$TMP_DIR/custom-swap.out"
end_case "field/function only apply to their own rule"

printf 'ADV090\twarn\tline\tforbid\tcode\tc\t*\t%s\t-\tlinha termina com ponto e virgula\t-\n' ';$' >"$TMP_DIR/eol.rules"
printf 'nX := 1 ;\r\nnY := 2\r\n/* a ;\r\nb */ nZ := 3 ;\r\n' >"$TMP_DIR/eol.prw"
run_lint eol --rules "$TMP_DIR/eol.rules" "$TMP_DIR/eol.prw"
found_set eol "$TMP_DIR/eol.prw" >"$TMP_DIR/eol.got"
printf '%s\n' 1:ADV090 4:ADV090 >"$TMP_DIR/eol.exp"
begin_case
expect_that "output contract" wellformed eol
expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/eol.exp" "$TMP_DIR/eol.got"
end_case "CRLF input: \"\$\" anchors at end of line, /* */ spans CRLF lines"

echo "=== Finding counts (successive matches on one line) ==="
printf '%s\n' '? ?' 'ConOut(ConOut("x"))' '?? "x"' 'u_ConOutConOut("x")' 'ConOutConOut("x")' >"$TMP_DIR/counts.prw"
run_lint counts --scope line "$TMP_DIR/counts.prw"
found_list counts "$TMP_DIR/counts.prw" >"$TMP_DIR/counts.got"
printf '%s\n' 1:ADV003 2:ADV003 2:ADV003 3:ADV003 >"$TMP_DIR/counts.exp"
begin_case
expect_that "output contract" wellformed counts
expect_that "finding counts differ (< expected, > actual)" same_file "$TMP_DIR/counts.exp" "$TMP_DIR/counts.got"
end_case "'? ?' and '?? x' give 1 ADV003, nested ConOut( gives 2, ConOut glued to identifiers gives 0"

# count_case LABEL CASE REGEX REGEX2 LINE WANT: one custom rule on a one-line file (C24).
count_case() {
  printf 'ADV090\twarn\tline\tforbid\tcode\t%s\t*\t%s\t%s\tcontagem\t-\n' "$2" "$3" "$4" >"$TMP_DIR/cc.rules"
  printf '%s\n' "$5" >"$TMP_DIR/cc.prw"
  run_lint cc --rules "$TMP_DIR/cc.rules" "$TMP_DIR/cc.prw"
  begin_case
  expect_that "output contract" wellformed cc
  expect_that "count $(count_id cc ADV090), want $6" [ "$(count_id cc ADV090)" = "$6" ]
  end_case "$1"
}
count_case "'aa' on 'aaaa': matches never overlap (2)" i 'aa' - 'aaaa' 2
count_case "'[a-z]a' on 'aaaa': matches never overlap (2)" i '[a-z]a' - 'aaaa' 2
count_case "'^x' on 'xx': ^ only at the real line start (1)" i '^x' - 'xx' 1
count_case "boundary 'ab' on 'abab' (1)" i '(^|[^a-z0-9_])ab' - 'abab' 1
count_case "boundary 'ab' on 'x ab ab' (2)" i '(^|[^a-z0-9_])ab' - 'x ab ab' 2
count_case "boundary 'ab' on 'abab ab xab ab_ab' (3)" i '(^|[^a-z0-9_])ab' - 'abab ab xab ab_ab' 3
count_case "CASE=c boundary 'Ab(' on 'Ab(Ab( xAb( _Ab(' (2)" c '(^|[^A-Za-z0-9_])Ab\(' - 'Ab(Ab( xAb( _Ab(' 2
count_case "REGEX2 sees the core text, not the '#' context char: '#ab_ok' excepted, 'ab_no' reported (1)" i '(^|[^a-z0-9_])ab_[a-z]+' '^ab_ok$' '#ab_ok ab_no' 1
# awk returns the leftmost-LONGEST match (a backtracking engine such as .NET
# would stop at the first alternative): the matched text decides the REGEX2
# exception and where the next search starts.
count_case "longest match: 'x(a|ab)' on 'xab' is 'xab', not excepted by '^xa\$' (1)" i 'x(a|ab)' '^xa$' 'xab' 1
count_case "longest match: '(a|aa)' on 'aaa' = 'aa' + 'a' (2)" i '(a|aa)' - 'aaa' 2
count_case "longest match: 'a+(ab)?' on 'aab' is 'aab', not excepted by '^aa\$' (1)" i 'a+(ab)?' '^aa$' 'aab' 1
count_case "longest match: 'a(b|bc\$)?' on 'abcd abc': '\$' only at the line end (1)" i 'a(b|bc$)?' '^ab$' 'abcd abc' 1
count_case "longest match: '(a|^ab)' on 'xab' is 'a' ('^' only at the line start), excepted by '^a\$' (0)" i '(a|^ab)' '^a$' 'xab' 0
# awk regex escapes and bracket expressions (the PowerShell engine translates them)
count_case "escape: '\\t' in REGEX is a TAB (1)" i 'a\tb' - "$(printf 'a\tb')" 1
count_case "escape: '\\/' is a slash (1)" i '\/x' - '/x' 1
count_case "escape: octal '\\101' is 'A' (CASE=c) (1)" c '\101b' - 'Ab' 1
count_case "bracket: ']' first is literal in '[]x]' (2)" i '[]x]' - ']x' 2
count_case "bracket: '[-[]' holds '-' and '[' (2)" i '[-[]' - '-[' 2
# CASE=i lowercases ASCII only (awk tolower under LC_ALL=C): byte 0xC7 stays.
count_case "CASE=i keeps Latin-1 0xC7: '\\307' matches (1)" i '\307' - "$(printf 'x\307y')" 1
count_case "CASE=i keeps Latin-1 0xC7: '\\347' does not match (0)" i '\347' - "$(printf 'x\307y')" 0

echo "=== File-scope rules (ADV019-ADV021) ==="
# --scope line, and --lines-file even when it lists every line, turn SCOPE=file
# rules off: what is left must be exactly the fixture's line-rule expectations.
for fixture in "$FIXTURES_DIR"/file-scope.*; do
  [ -f "$fixture" ] || continue
  base="$(basename "$fixture")"
  LC_ALL=C awk '{ print NR }' "$fixture" >"$TMP_DIR/fs-all.lines"
  grep -v -e ':ADV019$' -e ':ADV020$' -e ':ADV021$' "$TMP_DIR/fx-$base.exp" >"$TMP_DIR/fs-line.exp"
  run_lint fs-lines --scope all --lines-file "$TMP_DIR/fs-all.lines" "$fixture"
  run_lint fs-line --scope line "$fixture"
  found_set fs-lines "$fixture" >"$TMP_DIR/fs-lines.got"
  found_set fs-line "$fixture" >"$TMP_DIR/fs-line.got"
  begin_case
  expect_that "fixture has no ADV019-ADV021 expectation" [ "$(( $(wc -l <"$TMP_DIR/fx-$base.exp") ))" -gt "$(( $(wc -l <"$TMP_DIR/fs-line.exp") ))" ]
  expect_that "output contract (--lines-file)" wellformed fs-lines
  expect_that "--lines-file findings differ (< expected, > actual)" same_file "$TMP_DIR/fs-line.exp" "$TMP_DIR/fs-lines.got"
  expect_that "output contract (--scope line)" wellformed fs-line
  expect_that "--scope line findings differ (< expected, > actual)" same_file "$TMP_DIR/fs-line.exp" "$TMP_DIR/fs-line.got"
  end_case "$base: --lines-file (every line listed) and --scope line turn ADV019-ADV021 off"
done

# ADV019 (require): any line of the file may satisfy it; EXTS limits it to .tlpp.
REQ_DIR="$TMP_DIR/req"
mkdir -p "$REQ_DIR"
printf '// cabecalho\n#include "tlpp-core.th"\n' >"$REQ_DIR/ok.tlpp"
printf '#include <tlpp-core.th>\n' >"$REQ_DIR/angle.tlpp"
printf '#INCLUDE "TLPP-CORE.TH"\n' >"$REQ_DIR/upper.tlpp"
printf 'User Function LintTh()\nReturn\n' >"$REQ_DIR/noinc.th"
: >"$REQ_DIR/empty.tlpp"
run_lint_in "$REQ_DIR" req ok.tlpp angle.tlpp upper.tlpp noinc.th empty.tlpp
begin_case
expect_that "output contract" wellformed req
expect_that "findings [$(parse_findings req | cut -f 1,2,4 | tr '\t\n' ': ')]" \
  [ "$(parse_findings req | cut -f 1,2,4 | tr '\t\n' ': ')" = "upper.tlpp:1:ADV002 empty.tlpp:1:ADV019 " ]
end_case "ADV019: include on any line (\"\" or <>, any case) satisfies it, .th is exempt, empty .tlpp reports line 1"

FS="$FIXTURES_DIR/file-scope.prw"
printf 'rule ADV020\nrule adv021\n' >"$TMP_DIR/fs.ignore"
run_lint fs-ign --scope all --ignore-file "$TMP_DIR/fs.ignore" "$FS"
found_set fs-ign "$FS" >"$TMP_DIR/fs-ign.got"
grep -v -e ':ADV020$' -e ':ADV021$' "$TMP_DIR/fx-file-scope.prw.exp" >"$TMP_DIR/fs-ign.exp"
want=$(( $(count_id fx-file-scope.prw ADV020) + $(count_id fx-file-scope.prw ADV021) ))
begin_case
expect_that "output contract" wellformed fs-ign
expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/fs-ign.exp" "$TMP_DIR/fs-ign.got"
expect_that "suppressed $(suppressed_of fs-ign), want $want" [ "$(suppressed_of fs-ign)" = "$want" ]
expect_that "nothing to suppress in baseline" [ "$want" -gt 0 ]
end_case "rule ADV020 / rule adv021 suppress file-scope findings (counted as suppressed)"

printf 'path **/file-scope.tlpp\n' >"$TMP_DIR/fs-path.ignore"
run_lint fs-path --scope all --ignore-file "$TMP_DIR/fs-path.ignore" "$FIXTURES_DIR/file-scope.tlpp"
total="$(parse_findings fx-file-scope.tlpp | wc -l | tr -d ' ')"
begin_case
expect_that "stdout [$(cat "$TMP_DIR/fs-path.out")], want only $total suppressed" \
  [ "$(cat "$TMP_DIR/fs-path.out")" = "advpl-lint: 0 error(s), 0 warning(s), $total suppressed" ]
expect_that "nothing to suppress in baseline" [ "$total" -gt 0 ]
end_case "path glob suppresses file-scope findings too"

# ADV021 counts: one finding per NAME per block, file-level Local does not
# declare, "[" before the NAME or a digit glued to it excludes it; ADV020 per
# block.
printf '%s\n' \
  'Public cPub := ""' \
  'Private cPriv' \
  'Local cLoc' \
  'Function LintU01()' \
  '  cPub := "x"' \
  '  cPriv := "y"' \
  '  cLoc := "z"' \
  '  nA := nB := 0' \
  '  nA := 1; SA1 -> A1_XCOD := "1"' \
  '  aX[nI := 1] := 2; 9nQ := 1' \
  'Return' \
  'main function LintU02' \
  '  nA := 1' \
  '  RecLock("SA1", .F.)' \
  'Return' \
  'method Foo(nA) class Bar' \
  '  nA := 1' \
  '  nB := 2' \
  'Return' >"$TMP_DIR/undecl.prw"
run_lint undecl --scope all "$TMP_DIR/undecl.prw"
found_list undecl "$TMP_DIR/undecl.prw" >"$TMP_DIR/undecl.got"
printf '%s\n' 7:ADV021 8:ADV021 8:ADV021 13:ADV021 14:ADV020 18:ADV021 | LC_ALL=C sort >"$TMP_DIR/undecl.exp"
begin_case
expect_that "output contract" wellformed undecl
expect_that "finding counts differ (< expected, > actual)" same_file "$TMP_DIR/undecl.exp" "$TMP_DIR/undecl.got"
end_case "ADV021: one finding per name per block (2 names on one line = 2), file-level Public/Private declare, Local does not"

# arquivo-grande: ~5,000 generated lines with --scope all must take < 2 s.
LC_ALL=C awk 'BEGIN {
  print "#include \"totvs.ch\""
  for (i = 1; i <= 250; i++) {
    printf "Static Function F%04d(cPar, nPar)\n", i
    print "\tLocal nOk := 0"
    print "\tLocal cA, ;"
    print "\t\tcB"
    print "\tLocal aItens := {}, nPos := Max(1, 2)"
    print "\tLocal nI"
    print "\tnOk := Len(aItens) + nPos"
    print "\tcA := \"x\" + cPar"
    print "\tcB := \"y\""
    print "\tFor nI := 1 To 10"
    print "\t\tnOk += nI"
    print "\tNext nI"
    print "\tIf RecLock(\"SA1\", .F.)"
    print "\t\tSA1->A1_NOME := cA"
    if (i % 5 == 0) print "\t\tnSemDecl := IIf(nOk > 0, 1, 2)"
    else print "\t\tSA1->(MsUnlock())"
    print "\tEndIf"
    print "\tnPar := nPar + 1"
    print "\t// comentario nTotal := 0"
    print "\tcPar := \"MsUnlock()\""
    print "Return nOk"
  }
}' >"$TMP_DIR/big.prw"
TIMEFORMAT='%R'
NO_PARITY=1
{ time run_lint big --scope all "$TMP_DIR/big.prw"; } 2>"$TMP_DIR/big.time"
NO_PARITY=
secs="$(tail -n 1 "$TMP_DIR/big.time")"
begin_case
expect_that "output contract" wellformed big
expect_that "generated $(( $(wc -l <"$TMP_DIR/big.prw") )) lines, want 5001" [ "$(( $(wc -l <"$TMP_DIR/big.prw") ))" = 5001 ]
expect_that "ADV020 $(count_id big ADV020), want 50" [ "$(count_id big ADV020)" = 50 ]
expect_that "ADV021 $(count_id big ADV021), want 50" [ "$(count_id big ADV021)" = 50 ]
expect_that "ADV009 $(count_id big ADV009), want 50" [ "$(count_id big ADV009)" = 50 ]
expect_that "$(parse_findings big | wc -l | tr -d ' ') findings, want 150" [ "$(parse_findings big | wc -l | tr -d ' ')" = 150 ]
expect_that "took ${secs}s, want < 2s" awk -v s="$secs" 'BEGIN { exit !(s + 0 < 2) }'
end_case "arquivo-grande: 5001 lines, --scope all, ${secs}s (< 2 s)"
parity_check "$RUN_DIR" big --scope all "$TMP_DIR/big.prw"

echo "=== Parity matrix (every fixture and edge file, every mode) ==="
# Each run checks the output contract of the bash engine; with PowerShell,
# run_lint also compares advpl-lint.ps1 (stdout, exit code, stderr). Edge
# files: Latin-1 bytes (uppercase accented letters must survive CASE=i), a CR
# inside a line, "\r\r\n", a last line without newline or with a lone CR, an
# empty file, a blank .tlpp, extensions in any case, a skipped .txt, a path
# with spaces and a non-ASCII (UTF-8) path.
PAR="$TMP_DIR/par"
mkdir -p "$PAR/dir with space" "$PAR/ação"
LC_ALL=C awk 'BEGIN {
  n = 0
  L[++n] = "#INCLUDE \"TOTVS.CH\""
  L[++n] = "#include \047Protheus.ch\047"
  L[++n] = "  #  include <totvs.ch>"
  L[++n] = "User Function EdgeA(cPar, ;"
  L[++n] = "   nPar)"
  L[++n] = "\tLocal cX := \"\307\303O\" + \047it\047\047s\047 // \311 coment\341rio"
  L[++n] = "\tLocal nOk := 0, aL[2, 3], bB := {|x| x := 1}"
  L[++n] = "\tConOut(\"a\") ; nSem := 1 ; ConOut( \"b\" )"
  L[++n] = "\t/* bloco ConOut(\"no\")"
  L[++n] = "\t   */ ConOut(\"yes\") /* inline */ IIf(.T., 1, 2) /*/ ConOut(\"in comment\")"
  L[++n] = "\tstill comment */ nPos := 2"
  L[++n] = "\t* comentario ConOut(\"no\")"
  L[++n] = "\tcQuery := \"SELECT \" + cTab + \" WHERE \" + cWhere"
  L[++n] = "\tcSql += cX"
  L[++n] = "\tIIf(.T., 1, 2) && ConOut(\"x\")"
  L[++n] = "\tA\307\303O := 1"
  L[++n] = "\t\303\307 := 2 ; CONOUT(\"\311\") ; conout(\"\351\")"
  L[++n] = "\tabcd := abc + ab"
  L[++n] = "\tRecLock(\"SA1\", .F.)"
  L[++n] = "\tRecLock(\"SA2\", .F.)"
  L[++n] = "\tSA2->(MsUnlock())"
  L[++n] = "\tDbSelectArea(\"SX3\") ; DbSelectArea(\047SM0\047)"
  L[++n] = "\tcSel := \"SELECT * FROM SA1 WITH (NOLOCK)\""
  L[++n] = "\tStaticCall(MATA010, x) ; PTInternal(1)"
  L[++n] = "\t__cUserID := \"x\" ; cEmpAnt := \"01\""
  L[++n] = "\tLocal cEmpAnt, cFilAnt"
  L[++n] = "\tDbCreate(x) ; MsCreate(y) ; CriaTrab(nil, .F.)"
  L[++n] = "\tusing namespace tlpp.core ; using namespace tlpp.probat"
  L[++n] = "\tMA410IMPOS(1) ; SA1->A1_NOMEX := 1 ; FT_FUse(\"x\") ; SA1->A1_XPROJ := 2"
  L[++n] = "\tx\ry := 1"
  L[++n] = "\tFor nI := 1 To 10 ; Next"
  L[++n] = "\tcStr := \"unterminated"
  L[++n] = "\tnZ := 1\r\r"
  L[++n] = "\t? \"x\""
  L[++n] = "\t?? \"y\""
  L[++n] = "Return"
  L[++n] = "Static Function EdgeB()"
  L[++n] = "Class EdgeC"
  L[++n] = "  Method New() Constructor"
  L[++n] = "EndClass"
  L[++n] = "Method New(nArg) Class EdgeC"
  L[++n] = "\tnArg := 1 ; nW := 1"
  L[++n] = "Return Self"
  L[++n] = "ConOut(\"\357\277\275 last line, no newline\")"
  for (i = 1; i < n; i++) print L[i]
  printf "%s", L[n]
}' >"$PAR/edge.prw"
printf 'IIf(a, b, c)\n\r' >"$PAR/lone-cr.PRX"
printf 'ConOut("x")\r\r\nnA := 1\n' >"$PAR/crcr.Th"
: >"$PAR/empty.prw"
printf '\n' >"$PAR/blank.tlpp"
cp "$PAR/edge.prw" "$PAR/skip.txt"
cp "$F" "$PAR/dir with space/rules copy.prw"
cp "$FIXTURES_DIR/rules.tlpp" "$PAR/ação/regras.TLPP"
PAR_FILES=("$FIXTURES_DIR"/*.prw "$FIXTURES_DIR"/*.tlpp "$TMP_DIR"/crlf/* "$PAR/edge.prw" \
  "$PAR/lone-cr.PRX" "$PAR/crcr.Th" "$PAR/empty.prw" "$PAR/blank.tlpp" "$PAR/skip.txt" \
  "$PAR/dir with space/rules copy.prw" "$PAR/ação/regras.TLPP")

LC_ALL=C awk 'BEGIN { for (i = 1; i <= 199; i += 2) print i; print "x"; print ""; print " 004\r" }' >"$PAR/odd.lines"
{
  echo '# mistura de diretivas validas e invalidas'
  echo 'path **/dir with space/*.prw'
  printf '\tpath ação/*.TLPP\r\n'
  echo 'rule ca4000'
  echo 'rule adv021'
  echo 'field A1_NomeX'
  echo 'function MA410IMPOS'
  echo 'rule a b'
  echo 'path'
  echo 'function'
  echo 'bogus x'
} >"$PAR/mix.ignore"
{
  printf 'PAR001\terror\tline\tforbid\tcode\tc\t*\t%s\t-\tConOut exato\t-\n' '(^|[^A-Za-z0-9_])ConOut[ \t]*\('
  printf 'PAR002\twarn\tline\tforbid\traw\ti\t*\t%s\t-\tmaiuscula latin-1\tREF-1\n' '\307|\311'
  printf 'PAR003\twarn\tline\tforbid\traw\tc\tprw,tlpp\t%s\t-\tminuscula latin-1\t-\n' '\351|\341|\303'
  printf 'PAR004\twarn\tline\tforbid\tcode\ti\t*\t%s\t%s\talternativa curta primeiro\t-\n' '(iif|iif[ \t]*\()' '^iif$'
  printf 'PAR005\twarn\tline\tforbid\traw\ti\t*\t%s\t-\ttab antes de comentario\t-\n' '\t\/\/'
  printf 'PAR006\twarn\tline\tforbid\tcode\ti\t*\t%s\t-\tcolchetes\t-\n' '[;]|[]x[]'
  printf 'PAR007\terror\tfile\trequire\traw\tc\tprw,prx\t%s\t-\tsem include minusculo\t-\n' '^#include'
  printf 'PAR008\twarn\tfile\tbalance\traw\ti\t*\t%s\t%s\tbalance raw\t-\n' '(^|[^a-z0-9_])reclock' '(^|[^a-z0-9_])(msunlock|msunlockall)'
  printf 'PAR009\twarn\tfile\tundeclared\tcode\ti\t*\t%s\t-\tsem declaracao\t-\n' '^(nsem|x)$'
  printf 'PAR010\twarn\tline\tforbid\tcode\ti\t*\t%s\t-\talternancia\t-\n' '(a|ab)(c|bcd)?'
  printf 'PAR011\twarn\tline\tforbid\tcode\ti\t*\t%s\t-\tfim de linha\t-\n' ':=$|\.f\.'
  printf 'PAR012\twarn\tline\tforbid\traw\tc\tTH,PRX\t%s\t%s\textensao maiuscula\t-\n' '.' '^[^A-Z]'
} >"$PAR/par.rules"

par_case() {   # DIR NAME ARGS...: one matrix run (output contract + parity)
  local dir="$1" name="$2"
  shift 2
  run_lint_in "$dir" "$name" "$@"
  begin_case
  expect_that "output contract" wellformed "$name"
  end_case "matrix: $name"
}
par_case "$RUN_DIR" par-all --scope all "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-line --scope line "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-lines --scope all --lines-file "$PAR/odd.lines" "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-nolines --lines-file "" "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-ign-valid --ignore-file "$IGNORE_DIR/valid.advpl-specialist-ignore" "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-ign-crlf --ignore-file "$IGNORE_DIR/unknown-crlf.advpl-specialist-ignore" "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-ign-mix --scope all --ignore-file "$PAR/mix.ignore" "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-dashdash --scope line --scope all --rules "$PLUGIN_ROOT/skills/advpl-code-review/scripts/advpl-lint.rules" -- "${PAR_FILES[@]}"
par_case "$RUN_DIR" par-custom --rules "$PAR/par.rules" "${PAR_FILES[@]}"
cp "$PAR/mix.ignore" "$PAR/.advpl-specialist-ignore"
par_case "$PAR" par-relative edge.prw "dir with space/rules copy.prw" "ação/regras.TLPP" crcr.Th
usage_case "lone '-' is a FILE" "cannot read FILE: -" -
usage_case "single-dash option" "unknown option: -x" -x "$F"
usage_case "FILE is a directory" "cannot read FILE: " "$TMP_DIR"
usage_case "option after the first FILE is a FILE" "cannot read FILE: --scope" "$F" --scope line
usage_case "--lines-file is a directory" "cannot read lines file: " --lines-file "$PAR" "$F"

echo ""
echo "============================="
if [ -n "$PS_BIN" ]; then
  echo "PowerShell parity: $PARITY_RUNS runs compared with $PS_BIN"
else
  echo "PowerShell parity: skipped (no pwsh/powershell found)"
fi
echo "TOTAL: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
