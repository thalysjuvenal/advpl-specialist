#!/usr/bin/env bash
# advpl-lint.sh - static lint for ADVPL/TLPP sources (.prw .prx .tlpp .th)
#
# Usage: advpl-lint.sh [--scope line|all] [--lines-file PATH] [--ignore-file PATH]
#                      [--rules PATH] FILE...
#
#   --scope line|all    line: only SCOPE=line rules (default: all)
#   --lines-file PATH   1-based line numbers, one per line (blank or non-numeric
#                       lines skipped); SCOPE=line findings are restricted to
#                       them and SCOPE=file rules are disabled
#   --ignore-file PATH  default ./.advpl-specialist-ignore (missing = empty)
#   --rules PATH        default advpl-lint.rules next to this script
#
# Options come before the FILEs ("--" ends them). Every FILE must be a readable
# file; FILEs whose extension (any case) is not prw/prx/tlpp/th are skipped.
#
# Output (stdout): "FILE:LINE: error|warning ID MESSAGE [REF]" per finding
# (" [REF]" omitted when REF is "-"), FILEs in argument order, then line, then
# ID (byte order); last line "advpl-lint: N error(s), M warning(s), K suppressed".
# Exit: 0 no errors (warnings allowed), 1 errors, 2 usage error, unreadable FILE
# or invalid rules file.
#
# advpl-lint.ps1 is a twin that must print byte-identical stdout: any change to
# the semantics below (stripping, matching, ignore, ordering) must be mirrored.
# Portability: bash 3.2+, POSIX awk (BSD awk, mawk, gawk), files read as bytes.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USAGE='usage: advpl-lint.sh [--scope line|all] [--lines-file PATH] [--ignore-file PATH] [--rules PATH] FILE...'

die() { printf 'advpl-lint: %s\n%s\n' "$1" "$USAGE" >&2; exit 2; }
readable() { [ -f "$1" ] && [ -r "$1" ]; }

scope=all
lines_file=
ignore_file=./.advpl-specialist-ignore
rules_file="$SCRIPT_DIR/advpl-lint.rules"

while [ $# -gt 0 ]; do
  case "$1" in
    --scope|--lines-file|--ignore-file|--rules)
      [ $# -ge 2 ] || die "option $1 requires a value"
      case "$1" in
        --scope)
          case "$2" in
            line|all) scope="$2" ;;
            *) die "invalid --scope value: $2" ;;
          esac ;;
        --lines-file) lines_file="$2" ;;
        --ignore-file) ignore_file="$2" ;;
        --rules) rules_file="$2" ;;
      esac
      shift 2 ;;
    --) shift; break ;;
    -?*) die "unknown option: $1" ;;
    *) break ;;
  esac
done

[ $# -gt 0 ] || die "no FILE given"
readable "$rules_file" || die "cannot read rules file: $rules_file"
if [ -n "$lines_file" ]; then
  readable "$lines_file" || die "cannot read lines file: $lines_file"
fi
for f in "$@"; do
  readable "$f" || die "cannot read FILE: $f"
done

# The whole lint runs inside BEGIN: rules, ignore and lines files and every FILE
# are read with getline, so empty files and argument order are fully controlled.
# ARGV: 1 scope, 2 rules file, 3 ignore file, 4 lines file ("" = none), 5.. FILEs.
IFS= read -r -d '' AWK_PROG <<'AWK' || true
function warn(msg) { print "advpl-lint: " msg > "/dev/stderr" }
function fatal(msg) { warn(msg); exit 2 }

function spaces(n) {
  while (length(SP) < n) SP = SP SP
  return substr(SP, 1, n)
}

# ---- .advpl-specialist-ignore -------------------------------------------
# One directive per line: "rule ID|REF", "field NAME", "function NAME",
# "path GLOB" (the GLOB may contain spaces). "#" starts a comment line; CRLF
# and surrounding blanks are tolerated. Anything else: warning on stderr, the
# line is skipped. A missing or unreadable file means no directives.
function load_ignore(path,    line, lineno, kw, arg) {
  if (path == "") return
  lineno = 0
  while ((getline line < path) > 0) {
    lineno++
    sub(/\r$/, "", line)
    sub(/^[ \t]+/, "", line)
    sub(/[ \t]+$/, "", line)
    if (line == "" || substr(line, 1, 1) == "#") continue
    kw = line; arg = ""
    if (match(line, /[ \t]+/)) {
      kw = substr(line, 1, RSTART - 1)
      arg = substr(line, RSTART + RLENGTH)
    }
    if (kw == "path" && arg != "") {
      NPATH++
      PATH_RX[NPATH] = glob_to_ere(arg)
    } else if (arg != "" && arg !~ /[ \t]/ && kw == "rule") {
      IGN_RULE[toupper(arg)] = 1
    } else if (arg != "" && arg !~ /[ \t]/ && kw == "field") {
      IGN_FIELD[tolower(arg)] = 1
    } else if (arg != "" && arg !~ /[ \t]/ && kw == "function") {
      IGN_FUNC[tolower(arg)] = 1
    } else {
      warn("warning: " path ":" lineno ": unknown or malformed directive ignored: " line)
    }
  }
  close(path)
}

# Path glob -> ERE, matched against FILE with "\" turned into "/". "**/" is
# zero or more directories, "**" anything, "*" and "?" stay inside one path
# segment; the glob must match a trailing part of the path that starts at a
# segment boundary, so "legacy/**" also matches "/abs/proj/legacy/a.prw".
# A leading "./" is dropped. Matching is case-sensitive.
function glob_to_ere(g,    re, i, n, c) {
  gsub(/\\/, "/", g)
  while (substr(g, 1, 2) == "./") g = substr(g, 3)
  re = ""
  n = length(g)
  i = 1
  while (i <= n) {
    c = substr(g, i, 1)
    if (substr(g, i, 3) == "**/") { re = re "(.*/)?"; i += 3; continue }
    if (substr(g, i, 2) == "**") { re = re ".*"; i += 2; continue }
    if (c == "*") re = re "[^/]*"
    else if (c == "?") re = re "[^/]"
    else if (c == "^") re = re "\\^"
    else if (index(".[]()|+{}$", c)) re = re "[" c "]"
    else re = re c
    i++
  }
  return "(^|/)" re "$"
}

# ---- advpl-lint.rules -------------------------------------------------------
# TAB-separated: ID SEVERITY SCOPE KIND TARGET CASE EXTS REGEX REGEX2 MESSAGE REF
function load_rules(path,    line, lineno, n, f, r, ok, uid, uref) {
  lineno = 0
  while ((getline line < path) > 0) {
    lineno++
    sub(/\r$/, "", line)
    if (line ~ /^[ \t]*(#|$)/) continue
    n = split(line, f, "\t")
    ok = (n == 11 && f[1] ~ /^[A-Za-z0-9_]+$/)
    ok = ok && (f[2] == "error" || f[2] == "warn")
    ok = ok && (f[3] == "line" || f[3] == "file")
    ok = ok && f[4] ~ /^(forbid|require|balance|undeclared)$/
    ok = ok && (f[5] == "code" || f[5] == "raw") && (f[6] == "i" || f[6] == "c")
    ok = ok && f[7] != "" && f[8] != "" && f[8] != "-" && f[9] != ""
    ok = ok && f[10] != "" && f[11] != ""
    if (!ok) fatal("invalid rule at " path ":" lineno)
    r = ++NRULES
    ID[r] = f[1] ""
    SEV[r] = (f[2] == "error") ? "error" : "warning"
    KIND[r] = f[4]
    CODE[r] = (f[5] == "code")
    CASEI[r] = (f[6] == "i")
    EXTS[r] = "," tolower(f[7]) ","
    # "\t" in a regex becomes a real TAB (same meaning in every awk and .NET)
    gsub(/\\t/, "\t", f[8])
    gsub(/\\t/, "\t", f[9])
    RX[r] = f[8]
    RX2[r] = (f[9] == "-") ? "" : f[9]
    ANCHORED[r] = (substr(RX[r], 1, 1) == "^")
    # compile both regexes now: a broken one aborts before any output
    ok = ("" ~ RX[r])
    if (RX2[r] != "") ok = ("" ~ RX2[r])
    # forbid rules run per line; require/balance/undeclared are not implemented
    # yet and are skipped. SCOPE=file rules only run with --scope all and
    # without --lines-file.
    ENABLED[r] = (KIND[r] == "forbid") && (f[3] == "line" || (OPT_SCOPE == "all" && !USE_LINES))
    uid = toupper(ID[r])
    uref = toupper(f[11])
    RULE_IGNORED[r] = (uid in IGN_RULE) || (uref != "-" && (uref in IGN_RULE))
    TAIL[r] = SEV[r] " " ID[r] " " f[10] ((f[11] == "-") ? "" : " [" f[11] "]")
  }
  close(path)
}

function load_lines(path,    line) {
  while ((getline line < path) > 0) {
    sub(/\r$/, "", line)
    sub(/^[ \t]+/, "", line)
    sub(/[ \t]+$/, "", line)
    if (line ~ /^[0-9]+$/) WANT[line + 0] = 1
  }
  close(path)
}

# ---- TARGET=code view of a line (C7-C9) -------------------------------------
# Comment text and literal contents become spaces, so columns are preserved.
# Literals "..." and '...' keep their delimiters, never span lines and run to
# the end of the line when unterminated. Comments: "//" and "&&" (outside
# literals) to the end of the line; "/* ... */" across lines (state kept in
# IN_BLOCK); "*" when it is the first non-blank character of the line.
function code_of(line,    n, i, out, rest, c, c2, j) {
  n = length(line)
  i = 1
  out = ""
  if (IN_BLOCK) {
    j = index(line, "*/")
    if (j == 0) return spaces(n)
    out = spaces(j + 1)
    i = j + 2
    IN_BLOCK = 0
  } else if (line ~ /^[ \t]*\*/) {
    return spaces(n)
  }
  while (i <= n) {
    rest = substr(line, i)
    if (!match(rest, SPECIAL)) { out = out rest; break }
    out = out substr(rest, 1, RSTART - 1)
    i += RSTART - 1
    c = substr(line, i, 1)
    c2 = substr(line, i, 2)
    if (c == "\"" || c == "'") {
      j = index(substr(line, i + 1), c)
      if (j == 0) { out = out c spaces(n - i); i = n + 1 }
      else { out = out c spaces(j - 1) c; i += j + 1 }
    } else if (c2 == "//" || c2 == "&&") {
      out = out spaces(n - i + 1)
      i = n + 1
    } else if (c2 == "/*") {
      j = index(substr(line, i + 2), "*/")
      if (j == 0) { out = out spaces(n - i + 1); i = n + 1; IN_BLOCK = 1 }
      else { out = out spaces(j + 3); i += j + 3 }
    } else {
      out = out c
      i++
    }
  }
  return out
}

# ---- matching ---------------------------------------------------------------
# Matched text without leading characters outside [A-Za-z0-9_#] (C1).
function trimmed(m) {
  sub(/^[^A-Za-z0-9_#]+/, "", m)
  return m
}

# First identifier of the trimmed match, lowercased: the field (ADV018) or
# function (ADV017) name compared with "field"/"function" directives.
function token_of(m) {
  m = trimmed(m)
  if (match(m, /^[A-Za-z0-9_]+/)) m = substr(m, 1, RLENGTH)
  return tolower(m)
}

function ignored(r, m,    tok) {
  if (PATH_IGNORED || RULE_IGNORED[r]) return 1
  if (ID[r] != FIELD_RULE && ID[r] != FUNC_RULE) return 0
  tok = token_of(m)
  if (ID[r] == FIELD_RULE) return (tok in IGN_FIELD)
  return (tok in IGN_FUNC)
}

function add_finding(r, ln, m) {
  if (ignored(r, m)) { SUPPRESSED++; return }
  if (SEV[r] == "error") ERRORS++; else WARNINGS++
  NFIND++
  FL[NFIND] = ln
  FR[NFIND] = r
  FI[NFIND] = ID[r]
}

# forbid: one finding per match not covered by the REGEX2 exception (searched,
# unanchored, in the trimmed matched text). After a match the search goes on in
# the remainder of the string, so a REGEX starting with "^" reports at most once
# per line; an empty match ends the search.
function scan(r, s, ln,    st, len, m) {
  while (match(s, RX[r])) {
    st = RSTART
    len = RLENGTH
    if (len < 1) break
    m = substr(s, st, len)
    if (RX2[r] == "" || trimmed(m) !~ RX2[r]) add_finding(r, ln, m)
    if (ANCHORED[r]) break
    s = substr(s, st + len)
  }
}

# Stable insertion sort by (line, ID), then print. Findings arrive almost
# sorted (line order), so this stays close to linear.
function flush(path,    i, j, kl, kr, ki) {
  for (i = 2; i <= NFIND; i++) {
    kl = FL[i]; kr = FR[i]; ki = FI[i]
    j = i - 1
    while (j >= 1 && (FL[j] > kl || (FL[j] == kl && FI[j] > ki))) {
      FL[j + 1] = FL[j]; FR[j + 1] = FR[j]; FI[j + 1] = FI[j]
      j--
    }
    FL[j + 1] = kl; FR[j + 1] = kr; FI[j + 1] = ki
  }
  for (i = 1; i <= NFIND; i++) print path ":" FL[i] ": " TAIL[FR[i]]
}

function ext_of(path,    b) {
  b = path
  gsub(/\\/, "/", b)
  sub(/.*\//, "", b)
  if (!match(b, /\.[^.]*$/)) return ""
  return tolower(substr(b, RSTART + 1))
}

function lint_file(path,    ext, r, nr, list, i, norm, line, ln, code, lcode, lraw) {
  ext = ext_of(path)
  if (ext == "" || !index(",prw,prx,tlpp,th,", "," ext ",")) return
  nr = 0
  for (r = 1; r <= NRULES; r++)
    if (ENABLED[r] && (EXTS[r] == ",*," || index(EXTS[r], "," ext ","))) list[++nr] = r
  norm = path
  gsub(/\\/, "/", norm)
  PATH_IGNORED = 0
  for (i = 1; i <= NPATH; i++) if (norm ~ PATH_RX[i]) PATH_IGNORED = 1
  NFIND = 0
  IN_BLOCK = 0
  ln = 0
  while ((getline line < path) > 0) {
    ln++
    sub(/\r$/, "", line)
    code = code_of(line)
    if (USE_LINES && !(ln in WANT)) continue
    lcode = tolower(code)
    lraw = tolower(line)
    for (i = 1; i <= nr; i++) {
      r = list[i]
      if (CODE[r]) scan(r, CASEI[r] ? lcode : code, ln)
      else scan(r, CASEI[r] ? lraw : line, ln)
    }
  }
  close(path)
  flush(path)
}

BEGIN {
  SP = " "
  SPECIAL = "[\"'/&]"
  FIELD_RULE = "ADV018"
  FUNC_RULE = "ADV017"
  ERRORS = 0; WARNINGS = 0; SUPPRESSED = 0
  OPT_SCOPE = ARGV[1]
  USE_LINES = (ARGV[4] != "")
  load_ignore(ARGV[3])
  load_rules(ARGV[2])
  if (USE_LINES) load_lines(ARGV[4])
  for (a = 5; a < ARGC; a++) lint_file(ARGV[a])
  print "advpl-lint: " ERRORS " error(s), " WARNINGS " warning(s), " SUPPRESSED " suppressed"
  exit (ERRORS > 0) ? 1 : 0
}
AWK

LC_ALL=C awk "$AWK_PROG" "$scope" "$rules_file" "$ignore_file" "$lines_file" "$@"
