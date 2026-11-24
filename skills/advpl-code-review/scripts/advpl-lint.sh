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
#   --ignore-file PATH  must be a readable file; when not given,
#                       ./.advpl-specialist-ignore is used if it is a readable
#                       file and silently skipped otherwise
#   --rules PATH        default advpl-lint.rules next to this script
#
# Options come before the FILEs ("--" ends them). Every FILE must be a readable
# file; FILEs whose extension (any case) is not prw/prx/tlpp/th are skipped.
#
# Output (stdout): "FILE:LINE: error|warning ID MESSAGE [REF]" per finding
# (" [REF]" omitted when REF is "-"), FILEs in argument order, then line, then
# ID (byte order); last line "advpl-lint: N error(s), M warning(s), K suppressed".
# Exit: 0 no errors (warnings allowed), 1 errors, 2 usage error, unreadable FILE,
# lines file or explicit ignore file, or invalid rules file.
#
# Rule kinds: forbid runs line by line; require, balance and undeclared
# (SCOPE=file) analyse the whole file after it is read, on function blocks
# (see "SCOPE=file kinds" below).
#
# advpl-lint.ps1 is a twin that must print byte-identical stdout: any change to
# the semantics below (stripping, matching, blocks, ignore, ordering) must be
# mirrored.
# Portability: bash 3.2+, POSIX awk (BSD awk, mawk, gawk), files read as bytes.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USAGE='usage: advpl-lint.sh [--scope line|all] [--lines-file PATH] [--ignore-file PATH] [--rules PATH] FILE...'

die() { printf 'advpl-lint: %s\n%s\n' "$1" "$USAGE" >&2; exit 2; }
readable() { [ -f "$1" ] && [ -r "$1" ]; }

scope=all
lines_file=
ignore_file=
ignore_given=0
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
        --ignore-file) ignore_file="$2"; ignore_given=1 ;;
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
if [ "$ignore_given" = 1 ]; then
  readable "$ignore_file" || die "cannot read ignore file: $ignore_file"
elif readable ./.advpl-specialist-ignore; then
  ignore_file=./.advpl-specialist-ignore
fi
for f in "$@"; do
  readable "$f" || die "cannot read FILE: $f"
done

# The whole lint runs inside BEGIN: rules, ignore and lines files and every FILE
# are read with getline, so empty files and argument order are fully controlled.
# ARGV: 1 scope, 2 rules file, 3 ignore file, 4 lines file ("" = none for 3 and
# 4), 5.. FILEs.
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
# line is skipped. The bash side passes "" when no ignore file applies.
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

# Copy of a rule regex whose "^" anchors (outside bracket expressions) become a
# newline, which never occurs in a line read by getline. Used for every search
# after the first one on a line, so "^" only ever matches the real line start.
function no_bol(re,    out, i, j, n, c) {
  out = ""
  n = length(re)
  i = 1
  while (i <= n) {
    c = substr(re, i, 1)
    if (c == "\\") {
      out = out substr(re, i, 2)
      i += 2
    } else if (c == "[") {
      j = i + 1
      if (substr(re, j, 1) == "^") j++
      if (substr(re, j, 1) == "]") j++
      while (j <= n && substr(re, j, 1) != "]") j += (substr(re, j, 1) == "\\") ? 2 : 1
      out = out substr(re, i, j - i + 1)
      i = j + 1
    } else {
      out = out ((c == "^") ? "\n" : c)
      i++
    }
  }
  return out
}

# C24: a leading "(^|[^a-z0-9_])" (CASE=i) or "(^|[^A-Za-z0-9_])" (CASE=c) is a
# left word boundary that next_match() checks itself. Returns the regex without
# it (the "core"; the boundary applies to all its alternatives) and sets
# CORE_BOUND to 1 when it was stripped.
function core_of(re, casei) {
  CORE_BOUND = 0
  if (casei && substr(re, 1, 14) == "(^|[^a-z0-9_])") {
    CORE_BOUND = 1
    return substr(re, 15)
  }
  if (!casei && substr(re, 1, 17) == "(^|[^A-Za-z0-9_])") {
    CORE_BOUND = 1
    return substr(re, 18)
  }
  return re
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
    ok = ok && (f[5] == "code" || f[5] == "nocomment" || f[5] == "raw") && (f[6] == "i" || f[6] == "c")
    ok = ok && f[7] != "" && f[8] != "" && f[8] != "-" && f[9] != ""
    ok = ok && f[10] != "" && f[11] != ""
    # require/balance/undeclared look at the whole file: SCOPE must be file;
    # balance needs its counterpart REGEX2; undeclared parses the lowercased
    # code view, so it must be TARGET=code and CASE=i
    ok = ok && (f[4] == "forbid" || f[3] == "file")
    ok = ok && (f[4] != "balance" || f[9] != "-")
    ok = ok && (f[4] != "undeclared" || (f[5] == "code" && f[6] == "i"))
    if (!ok) fatal("invalid rule at " path ":" lineno)
    r = ++NRULES
    ID[r] = f[1] ""
    SEV[r] = (f[2] == "error") ? "error" : "warning"
    KIND[r] = f[4]
    TGT[r] = f[5]
    if (TGT[r] == "nocomment") HAS_NC = 1
    CASEI[r] = (f[6] == "i")
    EXTS[r] = "," tolower(f[7]) ","
    # "\t" in a regex becomes a real TAB (same meaning in every awk and .NET)
    gsub(/\\t/, "\t", f[8])
    gsub(/\\t/, "\t", f[9])
    # C24: RX keeps only the core of REGEX (boundary prefix stripped, BOUND
    # set); RXC is the core whose "^" can never match (searches from q > 1).
    RX[r] = core_of(f[8], CASEI[r])
    BOUND[r] = CORE_BOUND
    if (RX[r] == "") fatal("invalid rule at " path ":" lineno)
    RXC[r] = no_bol(RX[r])
    RX2[r] = (f[9] == "-") ? "" : f[9]
    # balance: REGEX2 is a second matcher with the same C24 semantics; forbid:
    # REGEX2 is the C1 exception, used as written; require/undeclared: unused
    BOUND2[r] = 0
    if (KIND[r] == "balance") {
      RX2[r] = core_of(RX2[r], CASEI[r])
      BOUND2[r] = CORE_BOUND
      if (RX2[r] == "") fatal("invalid rule at " path ":" lineno)
      RX2C[r] = no_bol(RX2[r])
      ok = ("" ~ RX2C[r])
    }
    # compile the regexes now: a broken one aborts before any output
    ok = ("" ~ RX[r])
    ok = ("" ~ RXC[r])
    if (RX2[r] != "") ok = ("" ~ RX2[r])
    # SCOPE=file rules only run with --scope all and without --lines-file
    ENABLED[r] = (f[3] == "line" || (OPT_SCOPE == "all" && !USE_LINES))
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
# The same pass leaves the TARGET=nocomment view in NC_VIEW: comments blanked
# exactly as above, literals kept intact (delimiters and contents).
function code_of(line,    n, i, out, nc, rest, s, c, c2, j) {
  n = length(line)
  i = 1
  out = ""
  if (IN_BLOCK) {
    j = index(line, "*/")
    if (j == 0) { NC_VIEW = spaces(n); return NC_VIEW }
    out = spaces(j + 1)
    i = j + 2
    IN_BLOCK = 0
  } else if (line ~ /^[ \t]*\*/) {
    NC_VIEW = spaces(n)
    return NC_VIEW
  }
  nc = out
  while (i <= n) {
    rest = substr(line, i)
    if (!match(rest, SPECIAL)) { out = out rest; nc = nc rest; break }
    s = substr(rest, 1, RSTART - 1)
    out = out s
    nc = nc s
    i += RSTART - 1
    c = substr(line, i, 1)
    c2 = substr(line, i, 2)
    if (c == "\"" || c == "'") {
      j = index(substr(line, i + 1), c)
      if (j == 0) { out = out c spaces(n - i); nc = nc substr(line, i); i = n + 1 }
      else { out = out c spaces(j - 1) c; nc = nc substr(line, i, j + 1); i += j + 1 }
    } else if (c2 == "//" || c2 == "&&") {
      s = spaces(n - i + 1)
      out = out s
      nc = nc s
      i = n + 1
    } else if (c2 == "/*") {
      j = index(substr(line, i + 2), "*/")
      if (j == 0) { s = spaces(n - i + 1); i = n + 1; IN_BLOCK = 1 }
      else { s = spaces(j + 3); i += j + 3 }
      out = out s
      nc = nc s
    } else {
      out = out c
      nc = nc c
      i++
    }
  }
  NC_VIEW = nc
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

# C24 matcher: the first accepted match of a core regex in s at or after
# position q. Returns its start (0 when there is none) and sets MLEN. The
# search from q = 1 uses rx; any search from q > 1 uses rxc (no "^"), so "^"
# only matches the real line start. With bound, a candidate at st is rejected
# when st > 1 and the character at st-1 is [A-Za-z0-9_]; the search then
# restarts at st+1. Callers continue after an accepted match [st, st+MLEN-1]
# at st+MLEN (st+1 when MLEN is 0), so matches never overlap.
# Examples: "aa" on "aaaa" = 2; boundary "ab" on "abab" = 1, on "x ab ab" = 2.
# Performance: gawk recompiles a dynamic regex whenever its text changes at a
# given match() call site, so rx and rxc get one call site each and callers
# run one regex over many lines in a row (rule-major) instead of alternating.
function next_match(rx, rxc, bound, s, q,    n, st, ok) {
  n = length(s)
  while (q <= n + 1) {
    if (q == 1) ok = match(s, rx)
    else ok = match(substr(s, q), rxc)
    if (!ok) return 0
    st = q + RSTART - 1
    if (bound && st > 1 && substr(s, st - 1, 1) ~ /[A-Za-z0-9_]/) {
      q = st + 1
      continue
    }
    MLEN = RLENGTH
    return st
  }
  return 0
}

# Number of C24 matches of a core regex in s.
function count_rx(rx, rxc, bound, s,    q, st, c) {
  c = 0
  q = 1
  while ((st = next_match(rx, rxc, bound, s, q)) > 0) {
    c++
    q = st + ((MLEN > 0) ? MLEN : 1)
  }
  return c
}

# Text of line ln that rule r looks at: the code view (TARGET=code), the
# nocomment view (TARGET=nocomment) or the raw line (TARGET=raw), lowercased
# when CASE=i (C14, ASCII only).
function view(r, ln) {
  if (TGT[r] == "code") return CASEI[r] ? LCL[ln] : CL[ln]
  if (TGT[r] == "nocomment") return CASEI[r] ? LNL[ln] : NL[ln]
  return CASEI[r] ? LRL[ln] : RL[ln]
}

# forbid: one finding per C24 match of REGEX not covered by the REGEX2
# exception (searched, unanchored, in the trimmed core match text; the
# boundary character is never part of it).
function scan(r, s, ln,    q, st, m) {
  q = 1
  while ((st = next_match(RX[r], RXC[r], BOUND[r], s, q)) > 0) {
    m = substr(s, st, MLEN)
    if (RX2[r] == "" || trimmed(m) !~ RX2[r]) add_finding(r, ln, m)
    q = st + ((MLEN > 0) ? MLEN : 1)
  }
}

# ---- SCOPE=file kinds (require, balance, undeclared) -----------------------
# "Matches" means next_match() finds an accepted match from q = 1.

# require: one finding at line 1 when no line's view matches REGEX (an empty
# file has no line, so it reports too).
function run_require(r, n,    ln) {
  for (ln = 1; ln <= n; ln++)
    if (next_match(RX[r], RXC[r], BOUND[r], view(r, ln), 1)) return
  add_finding(r, 1, "")
}

# Blocks (C25), computed on the lowercased code view. Logical lines: a line
# whose code view ends with ";" (trailing blanks allowed) is joined with the
# next one, that ";" becoming a space, so LTXT[k] keeps every column and
# LOFF[ln] is the position where physical line ln starts in it. Regions per
# logical line (LREG) and per physical line (REG): 0 file level, -1 class
# region, b > 0 block b. A logical line matching
#   ^[ \t]*((user|static|main)[ \t]+)?function[ \t]+[a-z_]   or
#   ^[ \t]*method[ \t]+[a-z_][a-z0-9_]*[ \t]*\(
# starts block b (LHDR[k] = 1, its header). A logical line matching
# ^[ \t]*class[ \t]+[a-z_] starts a class region, which ends the current block
# and runs through the next logical line matching
# ^[ \t]*end[ \t]*class([^a-z0-9_]|$) (or to the end of the file); no block
# starts inside it, and the lines after it are file level until the next
# block starts.
function build_blocks(n,    ln, k, s, t, state) {
  NLOG = 0
  NBLK = 0
  state = 0
  ln = 1
  while (ln <= n) {
    k = ++NLOG
    LFIRST[k] = ln
    s = ""
    while (ln <= n) {
      t = CL[ln]
      LOFF[ln] = length(s) + 1
      LOGOF[ln] = k
      ln++
      if (!match(t, /;[ \t]*$/)) {
        s = s t
        break
      }
      s = s substr(t, 1, RSTART - 1) " " substr(t, RSTART + 1)
    }
    LLAST[k] = ln - 1
    s = tolower(s)
    LTXT[k] = s
    LHDR[k] = 0
    if (state == -1) {
      LREG[k] = -1
      if (s ~ /^[ \t]*end[ \t]*class([^a-z0-9_]|$)/) state = 0
      continue
    }
    if (s ~ /^[ \t]*class[ \t]+[a-z_]/) {
      LREG[k] = -1
      state = -1
      continue
    }
    if (s ~ /^[ \t]*((user|static|main)[ \t]+)?function[ \t]+[a-z_]/ || s ~ /^[ \t]*method[ \t]+[a-z_][a-z0-9_]*[ \t]*\(/) {
      state = ++NBLK
      LHDR[k] = 1
    }
    LREG[k] = state
  }
  for (ln = 1; ln <= n; ln++) REG[ln] = LREG[LOGOF[ln]]
}

# Physical line of position p of logical line k.
function phys_of(k, p,    ln) {
  ln = LLAST[k]
  while (ln > LFIRST[k] && LOFF[ln] > p) ln--
  return ln
}

# balance (C26): per block, count the C24 matches of REGEX and of REGEX2 in
# the view of every physical line of the block; when count(REGEX) >
# count(REGEX2), one finding at the line of the block's first REGEX match.
# File-level and class-region lines are not counted. (Two passes, one regex
# each: see the performance note of next_match().)
function run_balance(r, n,    ln, b, c) {
  split("", BAL1)
  split("", BAL2)
  split("", BALF)
  for (ln = 1; ln <= n; ln++) {
    b = REG[ln]
    if (b <= 0) continue
    c = count_rx(RX[r], RXC[r], BOUND[r], view(r, ln))
    if (c > 0 && !(b in BALF)) BALF[b] = ln
    BAL1[b] += c
  }
  for (ln = 1; ln <= n; ln++) {
    b = REG[ln]
    if (b > 0) BAL2[b] += count_rx(RX2[r], RX2C[r], BOUND2[r], view(r, ln))
  }
  for (b = 1; b <= NBLK; b++)
    if (BAL1[b] + 0 > BAL2[b] + 0) add_finding(r, BALF[b], "")
}

# Declared names of a comma list (C27), recorded as DECL[b, name]. s is split
# on "," outside (), [] and {}; the list ends at the end of s or at a ")", "]"
# or "}" that closes nothing. An item declares the identifier
# [a-z_][a-z0-9_]* its first non-blank characters form, if any ("cX as
# character := 1" declares cx; "&cX" declares nothing).
function names_from_list(s, b,    i, n, c, depth, start, last) {
  n = length(s)
  last = n
  depth = 0
  start = 1
  i = 1
  while (i <= n) {
    if (!match(substr(s, i), /[(){},]|\[|\]/)) break
    i += RSTART - 1
    c = substr(s, i, 1)
    if (c == "(" || c == "[" || c == "{") {
      depth++
    } else if (c == ",") {
      if (depth == 0) {
        add_decl(substr(s, start, i - start), b)
        start = i + 1
      }
    } else if (depth == 0) {
      last = i - 1
      break
    } else {
      depth--
    }
    i++
  }
  add_decl(substr(s, start, last - start + 1), b)
}

function add_decl(item, b) {
  if (!match(item, /^[ \t]*[a-z_][a-z0-9_]*/)) return
  item = substr(item, 1, RLENGTH)
  sub(/^[ \t]+/, "", item)
  DECL[b, item] = 1
}

# Parameters of block b from its header t: the list after "(" that follows
# the name (no "(" after a function name: no parameters).
function header_params(t, b,    rest) {
  if (match(t, /^[ \t]*method[ \t]+[a-z_][a-z0-9_]*[ \t]*\(/)) {
    rest = substr(t, RLENGTH + 1)
  } else {
    match(t, /^[ \t]*((user|static|main)[ \t]+)?function[ \t]+[a-z_][a-z0-9_]*/)
    rest = substr(t, RLENGTH + 1)
    if (!match(rest, /^[ \t]*\(/)) return
    rest = substr(rest, RLENGTH + 1)
  }
  names_from_list(rest, b)
}

# Assignments of statement [p, e-1] of logical line k (text t) in block b:
# every non-overlapping match of [a-z_][a-z0-9_]*[ \t]*:= whose start is not
# preceded by [a-z0-9_] and whose last non-blank character before it is not
# ":" ("::x", "Self:x", "oObj:x"), "[" or the ">" of "->" ("Alias->FIELD").
# "aX[1] :=" never matches (the name is not right before ":=").
function find_assign(k, t, p, e, b,    q, st, j, c, nm) {
  q = p
  while (q < e) {
    if (!match(substr(t, q, e - q), /[a-z_][a-z0-9_]*[ \t]*:=/)) return
    st = q + RSTART - 1
    nm = substr(t, st, RLENGTH)
    q = st + RLENGTH
    if (st > 1 && substr(t, st - 1, 1) ~ /[a-z0-9_]/) continue
    j = st - 1
    while (j >= 1 && (substr(t, j, 1) == " " || substr(t, j, 1) == "\t")) j--
    if (j >= 1) {
      c = substr(t, j, 1)
      if (c == ":" || c == "[" || (c == ">" && j > 1 && substr(t, j - 1, 1) == "-")) continue
    }
    sub(/[ \t]*:=$/, "", nm)
    NASN++
    ASN_B[NASN] = b
    ASN_N[NASN] = nm
    ASN_L[NASN] = phys_of(k, st)
  }
}

# undeclared (H4, C27). Every logical line outside class regions is split
# into statements at each ";". A statement matching
# ^[ \t]*(local|private|public|static)[ \t]+ declares the names of the list
# that follows (in a block: all four keywords; at file level: static,
# private and public only, recorded as block 0); declaration statements are
# not searched for assignments. Other statements of a block are searched with
# find_assign(); headers only contribute their parameters. Then, in order of
# appearance, the first assignment of each NAME per block is a finding at its
# physical line unless NAME is declared in its block or at file level, or
# matches REGEX (names that never need a declaration).
function run_undeclared(r,    k, t, b, n, p, e, stmt, i, nm) {
  split("", DECL)
  split("", SEEN)
  NASN = 0
  for (k = 1; k <= NLOG; k++) {
    b = LREG[k]
    if (b < 0) continue
    t = LTXT[k]
    if (LHDR[k]) {
      header_params(t, b)
      continue
    }
    n = length(t)
    p = 1
    while (p <= n) {
      e = index(substr(t, p), ";")
      e = (e > 0) ? p + e - 1 : n + 1
      stmt = substr(t, p, e - p)
      if (match(stmt, /^[ \t]*(local|private|public|static)[ \t]+/)) {
        if (b > 0 || stmt !~ /^[ \t]*local/) names_from_list(substr(stmt, RLENGTH + 1), b)
      } else if (b > 0) {
        find_assign(k, t, p, e, b)
      }
      p = e + 1
    }
  }
  for (i = 1; i <= NASN; i++) {
    b = ASN_B[i]
    nm = ASN_N[i]
    if ((b, nm) in DECL || (0, nm) in DECL || (b, nm) in SEEN) continue
    if (next_match(RX[r], RXC[r], BOUND[r], nm, 1)) continue
    SEEN[b, nm] = 1
    add_finding(r, ASN_L[i], "")
  }
}

# Print the findings sorted by (line, ID in byte order); ties keep the order
# in which they were added (rule order, then match order). Findings are
# bucketed per line and each bucket gets a stable insertion sort by ID, so the
# cost stays linear whatever order the findings were added in.
function flush(path,    i, l, j, k, m, n, maxl) {
  split("", BN)
  split("", BK)
  maxl = 0
  for (i = 1; i <= NFIND; i++) {
    l = FL[i]
    BK[l, ++BN[l]] = i
    if (l > maxl) maxl = l
  }
  for (l = 1; l <= maxl; l++) {
    if (!(l in BN)) continue
    n = BN[l]
    for (j = 2; j <= n; j++) {
      k = BK[l, j]
      m = j - 1
      while (m >= 1 && FI[BK[l, m]] > FI[k]) {
        BK[l, m + 1] = BK[l, m]
        m--
      }
      BK[l, m + 1] = k
    }
    for (j = 1; j <= n; j++) print path ":" l ": " TAIL[FR[BK[l, j]]]
  }
}

function ext_of(path,    b) {
  b = path
  gsub(/\\/, "/", b)
  sub(/.*\//, "", b)
  if (!match(b, /\.[^.]*$/)) return ""
  return tolower(substr(b, RSTART + 1))
}

# The file is read first: CL/RL hold the code view and the raw line (CR
# removed) of every line, LCL/LRL their lowercased copies, NL/LNL the
# nocomment view when some rule uses it (HAS_NC). forbid rules (any
# SCOPE) are then scanned rule by rule over the lines (only the --lines-file
# lines when given; see the performance note of next_match()), and
# require/balance/undeclared run after them, in rules-file order. flush()
# sorts every finding by (line, ID), so file findings interleave with forbid
# findings by ID on a shared line.
function lint_file(path,    ext, r, nr, nf, list, flist, i, norm, line, ln, l) {
  ext = ext_of(path)
  if (ext == "" || !index(",prw,prx,tlpp,th,", "," ext ",")) return
  nr = 0
  nf = 0
  for (r = 1; r <= NRULES; r++) {
    if (!ENABLED[r] || (EXTS[r] != ",*," && !index(EXTS[r], "," ext ","))) continue
    if (KIND[r] == "forbid") list[++nr] = r
    else flist[++nf] = r
  }
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
    CL[ln] = code_of(line)
    RL[ln] = line
    LCL[ln] = tolower(CL[ln])
    LRL[ln] = tolower(line)
    if (HAS_NC) { NL[ln] = NC_VIEW; LNL[ln] = tolower(NC_VIEW) }
  }
  close(path)
  for (i = 1; i <= nr; i++) {
    r = list[i]
    for (l = 1; l <= ln; l++)
      if (!USE_LINES || (l in WANT)) scan(r, view(r, l), l)
  }
  if (nf) {
    build_blocks(ln)
    for (i = 1; i <= nf; i++) {
      r = flist[i]
      if (KIND[r] == "require") run_require(r, ln)
      else if (KIND[r] == "balance") run_balance(r, ln)
      else run_undeclared(r)
    }
  }
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
