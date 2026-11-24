#!/usr/bin/env bash
# lint-docs.sh - lint the ADVPL/TLPP code blocks of Markdown/MDX files with
# skills/advpl-code-review/scripts/advpl-lint.sh (dogfooding of the plugin docs)
#
# Usage: lint-docs.sh [--summary] [--rules PATH] PATH...
#
#   PATH        a file (linted whatever its extension) or a directory (every
#               *.md and *.mdx below it, extension in any case, sorted in byte
#               order; node_modules and .git directories are skipped)
#   --summary   print counts instead of findings: per file (errors, warnings;
#               by errors then warnings, descending), per rule, then the total
#   --rules     rules file handed to the engine (default: the engine's own)
#
# Blocks: fenced blocks (``` or ~~~, at any indentation, closed by a fence of
# the same character at least as long with nothing after it; a fence left open
# runs to the end of the file; a ``` line whose info contains a backtick is
# inline code, not a fence). A block is linted when its language (first word
# of the info string, any case) is advpl, tlpp, prw or xbase, or when it is c
# or empty and some line starts (after blanks, any case) with a strong marker:
# "user function", "static function", "#include" of a .ch/.th file,
# "beginsql", "endif", "return" on a line without ";", or "local ". The .ch/.th
# and ";" conditions keep real C (#include <stdio.h>, return 0;) out.
# A block is skipped when the last non-blank line before its opening fence is
# the anti-example marker (blanks ignored): <!-- advpl-lint: anti-exemplo -->
# in Markdown, {/* advpl-lint: anti-exemplo */} in .mdx files.
# Each block goes to a temporary file, without the fence's indentation, named
# .tlpp (language tlpp, or the word "namespace" followed by a blank anywhere in
# the block) or .prw, and the engine runs once over all of them with
# --scope line (file-scope rules ADV019-ADV021 never apply to snippets).
#
# Output: "FILE:LINE: error|warning ID MESSAGE [REF]" with LINE counted in the
# Markdown file, files in argument order (directory entries sorted), lines in
# ascending order, then the engine's line "advpl-lint: N error(s), M
# warning(s), K suppressed".
# Exit: 0 no errors (warnings allowed), 1 errors, 2 usage error, unreadable
# PATH or engine error (its message is passed through on stderr).
# Portability: bash 3.2+, POSIX awk (BSD awk, mawk, gawk), files read as bytes.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$SCRIPT_DIR/../skills/advpl-code-review/scripts/advpl-lint.sh"
SH="${BASH:-bash}"
USAGE='usage: lint-docs.sh [--summary] [--rules PATH] PATH...'
TAB="$(printf '\t')"

die() { printf 'lint-docs: %s\n%s\n' "$1" "$USAGE" >&2; exit 2; }

summary=0
rules=
while [ $# -gt 0 ]; do
  case "$1" in
    --summary) summary=1; shift ;;
    --rules)
      [ $# -ge 2 ] || die "option --rules requires a value"
      rules="$2"; shift 2 ;;
    --) shift; break ;;
    -?*) die "unknown option: $1" ;;
    *) break ;;
  esac
done
[ $# -gt 0 ] || die "no PATH given"
for p in "$@"; do
  [ -d "$p" ] || { [ -f "$p" ] && [ -r "$p" ]; } || die "cannot read PATH: $p"
done
# The engine runs from the temporary directory: make --rules absolute.
case "$rules" in ''|/*) ;; *) rules="$PWD/$rules" ;; esac

TMP="$(mktemp -d "${TMPDIR:-/tmp}/lint-docs.XXXXXX")" || {
  echo 'lint-docs: cannot create a temporary directory' >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT
trap 'exit 2' HUP INT TERM

: >"$TMP/list"
for p in "$@"; do
  if [ -d "$p" ]; then
    while :; do   # BSD find prints "dir//x" for "dir/"
      case "$p" in /) break ;; */) p="${p%/}" ;; *) break ;; esac
    done
    find "$p" \( -name node_modules -o -name .git \) -prune -o \
      -type f \( -iname '*.md' -o -iname '*.mdx' \) -print | LC_ALL=C sort >>"$TMP/list"
  else
    printf '%s\n' "$p" >>"$TMP/list"
  fi
done

# Extraction: one block per file "bN.prw|bN.tlpp" in $TMP and one map line
# "NAME<TAB>MARKDOWN FILE<TAB>LINE OF THE OPENING FENCE" per block.
LC_ALL=C awk -v tmp="$TMP" '
  function reset_block() { inblk = 0; n = 0; strong = 0; ns = 0 }
  function add(l,   k, ll) {
    for (k = 0; k < bind && (substr(l, 1, 1) == " " || substr(l, 1, 1) == "\t"); k++)
      l = substr(l, 2)
    buf[++n] = l
    ll = tolower(l)
    if (ll ~ /^[ \t]*((user|static)[ \t]+function|beginsql|endif|return)([^a-z0-9_]|$)/ &&
        !(ll ~ /^[ \t]*return/ && index(ll, ";") > 0)) strong = 1
    else if (ll ~ /^[ \t]*local[ \t]/) strong = 1
    else if (ll ~ /^[ \t]*#[ \t]*include.*\.(ch|th)([^a-z0-9_]|$)/) strong = 1
    if (ll ~ /(^|[^a-z0-9_])namespace[ \t]/) ns = 1
  }
  function flush(   i, name) {
    if (!inblk) return
    if (!skip && n > 0 && (lang == "advpl" || lang == "tlpp" || lang == "prw" || lang == "xbase" ||
        ((lang == "" || lang == "c") && strong))) {
      name = "b" (++nb) "." ((lang == "tlpp" || ns) ? "tlpp" : "prw")
      for (i = 1; i <= n; i++) printf "%s\n", buf[i] > (tmp "/" name)
      close(tmp "/" name)
      printf "%s\t%s\t%d\n", name, file, start > (tmp "/map")
    }
    reset_block()
  }
  # Opening fence: sets bind, fch, flen, lang, start and skip.
  function open_fence(l, ln,   rest, info, p) {
    match(l, /^[ \t]*/)
    rest = substr(l, RLENGTH + 1)
    if (substr(rest, 1, 3) == "```") { fch = "`"; match(rest, /^`+/) }
    else if (substr(rest, 1, 3) == "~~~") { fch = "~"; match(rest, /^~+/) }
    else return 0
    info = substr(rest, RLENGTH + 1)
    if (fch == "`" && index(info, "`") > 0) return 0
    bind = length(l) - length(rest); flen = RLENGTH; start = ln
    sub(/^[ \t]+/, "", info)
    match(info, /^[^ \t{]*/)
    lang = tolower(substr(info, 1, RLENGTH))
    p = prev
    gsub(/[ \t]/, "", p)
    skip = (mdx ? p == "{/*advpl-lint:anti-exemplo*/}" : p == "<!--advpl-lint:anti-exemplo-->")
    inblk = 1
    return 1
  }
  function closes(l,   rest) {
    rest = l
    sub(/^[ \t]+/, "", rest)
    sub(/[ \t]+$/, "", rest)
    if (length(rest) < flen) return 0
    return (fch == "`") ? rest ~ /^`+$/ : rest ~ /^~+$/
  }
  {
    file = $0
    mdx = (tolower(file) ~ /\.mdx$/)
    ln = 0; prev = ""
    reset_block()
    while ((r = (getline line < file)) > 0) {
      ln++
      sub(/\r$/, "", line)
      if (inblk) {
        if (closes(line)) { flush(); prev = line } else add(line)
      } else if (!open_fence(line, ln) && line !~ /^[ \t]*$/) prev = line
    }
    if (r < 0) { printf "lint-docs: cannot read PATH: %s\n", file > "/dev/stderr"; exit 2 }
    close(file)
    flush()
  }
' "$TMP/list" || exit 2

blocks=()
if [ -f "$TMP/map" ]; then
  while IFS="$TAB" read -r name _; do blocks[${#blocks[@]}]="$name"; done <"$TMP/map"
fi
nfiles="$(wc -l <"$TMP/list" | tr -d ' ')"

rc=0
: >"$TMP/findings"; : >"$TMP/files"; : >"$TMP/rules"
if [ ${#blocks[@]} -eq 0 ]; then
  echo 'advpl-lint: 0 error(s), 0 warning(s), 0 suppressed' >"$TMP/total"
else
  eopts=(--scope line)
  [ -z "$rules" ] || eopts=(--scope line --rules "$rules")
  (cd "$TMP" && "$SH" "$ENGINE" "${eopts[@]}" -- "${blocks[@]}") >"$TMP/out" 2>"$TMP/err"
  rc=$?
  cat "$TMP/err" >&2
  [ "$rc" -le 1 ] || exit 2
  # Back to Markdown coordinates. Findings go to $TMP/findings; the per-file
  # ("ERRORS<TAB>WARNINGS<TAB>FILE") and per-rule ("ID SEVERITY COUNT") counts
  # to $TMP/files and $TMP/rules; the engine summary to $TMP/total.
  LC_ALL=C awk -v tmp="$TMP" '
    FNR == NR { split($0, m, "\t"); md[m[1]] = m[2]; off[m[1]] = m[3]; next }
    /^advpl-lint: / { print > (tmp "/total"); next }
    {
      i = index($0, ":"); name = substr($0, 1, i - 1); rest = substr($0, i + 1)
      j = index(rest, ":"); lno = substr(rest, 1, j - 1) + off[name]; rest = substr(rest, j)
      f = md[name]
      print f ":" lno rest > (tmp "/findings")
      split(substr(rest, 3), w, " ")
      if (!(f in seen)) { seen[f] = 1; order[++nf] = f; e[f] = 0; wn[f] = 0 }
      if (w[1] == "error") e[f]++; else wn[f]++
      cnt[w[2]]++; sev[w[2]] = w[1]
    }
    END {
      for (k = 1; k <= nf; k++) printf "%d\t%d\t%s\n", e[order[k]], wn[order[k]], order[k] > (tmp "/files")
      for (id in cnt) printf "%s %s %d\n", id, sev[id], cnt[id] > (tmp "/rules")
    }
  ' "$TMP/map" "$TMP/out"
fi

if [ "$summary" = 1 ]; then
  echo "# lint-docs: $nfiles file(s), ${#blocks[@]} ADVPL/TLPP block(s); per file: errors warnings file (errors, then warnings, descending)"
  LC_ALL=C sort -t "$TAB" -k1,1nr -k2,2nr -k3,3 "$TMP/files" |
    LC_ALL=C awk -F '\t' '{ f = $0; sub(/^[^\t]*\t[^\t]*\t/, "", f); printf "%6d %6d  %s\n", $1, $2, f }'
  echo "# per rule: id severity count"
  LC_ALL=C sort "$TMP/rules"
else
  cat "$TMP/findings"
fi
cat "$TMP/total"
exit "$rc"
