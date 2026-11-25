#!/usr/bin/env bash
# lint-outputs.sh - run the plugin's lint engine over the ADVPL/TLPP sources that
# the latest local eval run (`claude plugin eval`) produced.
#
# Usage: bash evals/lint-outputs.sh [RESULTS_DIR]
#
#   RESULTS_DIR  one run's results directory (default: the newest directory in
#                evals/results/, by name - the names are timestamps)
#
# Where the sources come from: the run's results (aggregate-result.json,
# report.html) do not keep the files the agent created. They live in each run's
# temporary workspace, removed at the end unless the suite runs with
# --keep-temp, which keeps the directory and prints "kept temp: <root>" (or
# "kept temp (run failed): <root>"). The runbook in CONTRIBUTING.md therefore
# runs the suite with --keep-temp and --output-dir RESULTS_DIR and saves the
# CLI output to RESULTS_DIR/eval.log. This script:
#   1. reads every "kept temp...: <root>" line of RESULTS_DIR/eval.log and
#      collects the sources of that run's workspace. In Claude Code 2.1.332 the
#      workspace is <root>/home/cwd; when kept, home/ is moved to
#      <root>/sealed/home/cwd and <root>/sealed gets mode 000, so the script
#      makes it readable with "chmod u+rx" (the CLI's own advice to inspect it);
#   2. also collects sources placed directly under RESULTS_DIR;
#   3. drops files byte-identical to a fixture under evals/*/fixtures/ (inputs
#      copied by a scaffold script and left unchanged by the agent);
#   4. runs advpl-lint.sh --scope all with an empty ignore file, so a local
#      .advpl-specialist-ignore cannot hide findings.
# A run with the no-plugin baseline arm ("Ablation: 2 arms" in the log) is
# refused: its sources do not come from the plugin. Run with --ablation none.
#
# Extensions: .prw .prx .tlpp .th (any case), the lint engine's own set.
# Output (stdout): the list of linted sources, then the engine's lines.
# Exit: 0 no lint error (warnings allowed), 1 lint errors, 2 no results, no
#   produced source, a baseline run, a usage error or an engine error.
# Portability: bash 3.2+, no jq/Node/Python.

set -u
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/../skills/advpl-code-review/scripts/advpl-lint.sh"
RESULTS_ROOT="$SCRIPT_DIR/results"
USAGE='usage: bash evals/lint-outputs.sh [RESULTS_DIR]'
RUNBOOK='see "Runbook de release" in CONTRIBUTING.md'

fail() { printf 'lint-outputs: %s\n' "$1" >&2; exit 2; }

case "${1:-}" in
  -h|--help) printf '%s\n' "$USAGE"; exit 0 ;;
  -?*) fail "unknown option: $1 ($USAGE)" ;;
esac
[ $# -le 1 ] || fail "too many arguments ($USAGE)"
[ -f "$LINT" ] || fail "lint engine not found: $LINT"

if [ $# -eq 1 ]; then
  results_dir=${1%/}
  [ -d "$results_dir" ] || fail "not a directory: $1"
else
  latest=""
  if [ -d "$RESULTS_ROOT" ]; then
    for d in "$RESULTS_ROOT"/*/; do
      [ -d "$d" ] && latest=${d%/}
    done
  fi
  [ -n "$latest" ] || fail "no eval results in $RESULTS_ROOT - run the suite first ($RUNBOOK)"
  results_dir=$latest
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/lint-outputs.XXXXXX") || fail "cannot create a temporary directory"
trap 'rm -rf "$tmp"' EXIT

# Kept workspaces listed in the CLI output (ANSI colours and CRs stripped).
log="$results_dir/eval.log"
: > "$tmp/roots"
if [ -f "$log" ]; then
  if grep -q 'Ablation: 2 arms' "$log"; then
    fail "$log is a run with the no-plugin baseline arm; lint only a single-arm run (--ablation none)"
  fi
  esc=$(printf '\033')
  sed "s/${esc}\[[0-9;]*m//g" "$log" | tr -d '\r' |
    sed -n 's/^.*kept temp[^:]*: \(\/.*[^ ]\) *$/\1/p' > "$tmp/roots"
fi

: > "$tmp/candidates"
while IFS= read -r root; do
  [ -n "$root" ] || continue
  if [ ! -d "$root" ]; then
    printf 'lint-outputs: kept directory not found (already removed?): %s\n' "$root" >&2
    continue
  fi
  if [ -d "$root/sealed" ] && { [ ! -r "$root/sealed" ] || [ ! -x "$root/sealed" ]; }; then
    chmod u+rx "$root/sealed" 2>/dev/null ||
      printf 'lint-outputs: cannot open %s (chmod u+rx failed)\n' "$root/sealed" >&2
  fi
  found_ws=0
  for ws in "$root/sealed/home/cwd" "$root/home/cwd"; do
    [ -d "$ws" ] || continue
    found_ws=1
    find "$ws" -type f \( -iname '*.prw' -o -iname '*.prx' -o -iname '*.tlpp' -o -iname '*.th' \) \
      >> "$tmp/candidates"
  done
  [ "$found_ws" = 1 ] ||
    printf 'lint-outputs: no workspace under %s (expected home/cwd or sealed/home/cwd)\n' "$root" >&2
done < "$tmp/roots"

find "$results_dir" -type f \( -iname '*.prw' -o -iname '*.prx' -o -iname '*.tlpp' -o -iname '*.th' \) \
  >> "$tmp/candidates"

# Fixtures: the cases' inputs, not outputs.
find "$SCRIPT_DIR" -path "$RESULTS_ROOT" -prune -o -type f -path '*/fixtures/*' -print > "$tmp/fixtures"

files=()
skipped=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  same=0
  while IFS= read -r fx; do
    if cmp -s "$f" "$fx"; then
      same=1
      break
    fi
  done < "$tmp/fixtures"
  if [ "$same" = 1 ]; then
    skipped=$((skipped + 1))
  else
    files+=("$f")
  fi
done < <(sort -u "$tmp/candidates")

if [ ${#files[@]} -eq 0 ]; then
  if [ -s "$tmp/roots" ]; then
    fail "no ADVPL/TLPP source produced by the run in $results_dir ($skipped unchanged fixture(s) skipped)"
  elif [ -f "$log" ]; then
    fail "$log lists no kept workspace and $results_dir holds no source - run the suite with --keep-temp ($RUNBOOK)"
  else
    fail "no $log and no source in $results_dir - save the CLI output of a --keep-temp run there ($RUNBOOK)"
  fi
fi

printf 'lint-outputs: %d source(s) from %s (%d unchanged fixture(s) skipped)\n' \
  "${#files[@]}" "$results_dir" "$skipped"
for f in "${files[@]}"; do
  printf '  %s\n' "$f"
done

: > "$tmp/empty-ignore"
bash "$LINT" --scope all --ignore-file "$tmp/empty-ignore" -- "${files[@]}"
rc=$?
case $rc in
  0|1) exit "$rc" ;;
  *) fail "advpl-lint.sh failed (exit $rc)" ;;
esac
