#!/usr/bin/env bash
# Fixture-based runner for skills/advpl-code-review/scripts/advpl-lint.sh
# Usage: bash tests/lint/run-tests.sh   (on macOS, /bin/bash exercises bash 3.2)
#
# Fixture convention: a line that must produce finding(s) ends with
# "// expect: ID[,ID]"; a line without "expect" must produce none.
# Scope per fixture (C17): file-scope.* runs with --scope all; the others
# (rules.*, fffd.*) run with --scope line.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINT="$PLUGIN_ROOT/skills/advpl-code-review/scripts/advpl-lint.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
IGNORE_DIR="$FIXTURES_DIR/ignore-cases"
SH="${BASH:-bash}"            # run the engine with the same bash as this runner
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
run_lint_in() {
  local dir="$1" name="$2"
  shift 2
  (cd "$dir" && "$SH" "$LINT" "$@") >"$TMP_DIR/$name.out" 2>"$TMP_DIR/$name.err"
  echo "$?" >"$TMP_DIR/$name.rc"
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
  printf 'ADV019\terror\tfile\trequire\traw\tc\tprw\t%s\t-\tkind still unimplemented\t-\n' '^#include'
} >"$TMP_DIR/custom.rules"
printf '%s\n' \
  'MA410IMPOS(SA1->A1_XPROJ)' \
  'SA1->A1_NOME := MA410IMPOS(MA410IMPOS(1))' \
  'cX := "A1_XPROJ" + u_MA410IMPOS(1)' >"$TMP_DIR/custom.prw"
CF="$TMP_DIR/custom.prw"
run_lint custom --rules "$TMP_DIR/custom.rules" "$CF"
found_set custom "$CF" >"$TMP_DIR/custom.got"
printf '%s\n' 1:ADV017 1:ADV018 2:ADV017 >"$TMP_DIR/custom.exp"
begin_case
expect_that "output contract" wellformed custom
expect_that "findings differ (< expected, > actual)" same_file "$TMP_DIR/custom.exp" "$TMP_DIR/custom.got"
expect_that "two matches on one line are not two findings" [ "$(count_id custom ADV017)" = 3 ]
expect_that "first line format" [ "$(head -n 1 "$TMP_DIR/custom.out")" = "$CF:1: warning ADV017 funcao sem suporte [CA9999]" ]
expect_that "REF '-' must omit the brackets" [ "$(sed -n 2p "$TMP_DIR/custom.out")" = "$CF:1: warning ADV018 campo fora do dicionario" ]
expect_that "summary" [ "$(tail -n 1 "$TMP_DIR/custom.out")" = "advpl-lint: 0 error(s), 4 warning(s), 0 suppressed" ]
end_case "forbid: one finding per match, REGEX2 exception on trimmed text, EXTS, unimplemented kind skipped"

printf 'field a1_xproj\nfunction Ma410Impos\n' >"$TMP_DIR/custom.ignore"
run_lint custom-ign --rules "$TMP_DIR/custom.rules" --ignore-file "$TMP_DIR/custom.ignore" "$CF"
begin_case
expect_that "summary" [ "$(cat "$TMP_DIR/custom-ign.out")" = "advpl-lint: 0 error(s), 0 warning(s), 4 suppressed" ]
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

echo ""
echo "============================="
echo "TOTAL: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
