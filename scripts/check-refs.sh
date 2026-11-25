#!/usr/bin/env bash
# check-refs.sh - cross-reference checks of the plugin layout
#
# Usage: bash scripts/check-refs.sh   (run from anywhere; paths are resolved
#                                      against the repository root)
#
# Checks:
#   1. Plugin paths cited in commands/*.md, agents/*.md and ai-commands/src/*.md
#      exist: "${CLAUDE_PLUGIN_ROOT}/skills/..." and "${CLAUDE_PLUGIN_ROOT}/agents/..."
#      (the variable is the repository root) and relative "skills/<skill>/..."
#      paths. A relative path glued to a longer path ("../skills/x",
#      "/plugin-path/skills/x") is not one of them. Placeholders such as
#      <arquivo> count as "*"; a path with "*" must match at least one entry; a
#      path ending in "/" must be a directory. Finding no cited path at all is
#      a problem too (the extraction failed).
#   2. Every skills/<name>/ has documentation/content/docs/skills/<name>.mdx and
#      "<name>" is an entry of the "pages" array of that directory's meta.json;
#      a site page or a pages entry without skills/<name>/ is a problem.
#   3. Every name in the "skills:" frontmatter list of agents/*.md has
#      skills/<name>/SKILL.md whose frontmatter "name:" is that name.
#   4. The command list printed by hooks/session-start ("/advpl-specialist:NAME")
#      is the set of commands/*.md.
#
# Output: one line per problem, then "check-refs: N problem(s) ...".
# Exit: 0 no problems, 1 otherwise.
# Portability: bash 3.2+, POSIX awk; no jq, Node or Python.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SITE_DIR="documentation/content/docs/skills"
SITE_META="$SITE_DIR/meta.json"
PROBLEMS=0
PATHS=0
problem() { echo "$1"; PROBLEMS=$((PROBLEMS + 1)); }

# ---- 1. cited paths -----------------------------------------------------------
# Prints "FILE:LINE<TAB>PATH" for every cited path, PATH relative to the root
# (the "${CLAUDE_PLUGIN_ROOT}/" prefix removed), trailing dots dropped.
cited_paths() {
  LC_ALL=C awk '
    {
      line = $0
      sub(/\r$/, "", line)
      # Mark the rooted prefix with a byte that is not a path character.
      gsub(/\$\{CLAUDE_PLUGIN_ROOT\}\//, "\001", line)
      pos = 1
      while (pos <= length(line)) {
        rest = substr(line, pos)
        if (!match(rest, /(skills|agents)\/[A-Za-z0-9._*<>\/-]+/)) break
        start = pos + RSTART - 1
        tok = substr(line, start, RLENGTH)
        pos = start + RLENGTH
        prev = (start > 1) ? substr(line, start - 1, 1) : ""
        if (prev == "\001") {
          rooted = 1
        } else if (prev ~ /[A-Za-z0-9_.\/$}-]/) {
          continue                      # part of a longer path
        } else if (tok ~ /^skills\//) {
          rooted = 0
        } else {
          continue                      # relative agents/... is prose
        }
        sub(/\.+$/, "", tok)
        if (tok ~ /^(skills|agents)\/$/) continue
        print FILENAME ":" FNR "\t" tok
      }
    }' "$@"
}

path_exists() {   # PATTERN, relative to the root
  local pat m
  pat="$(printf '%s' "$1" | sed 's/<[^>]*>/*/g')"
  case "$pat" in
    *'*'*)
      # shellcheck disable=SC2086 # the pattern is meant to be expanded
      for m in $pat; do [ -e "$m" ] && return 0; done
      return 1 ;;
    */) [ -d "$pat" ] ;;
    *) [ -e "$pat" ] ;;
  esac
}

while IFS="$(printf '\t')" read -r where path; do
  [ -n "$path" ] || continue
  PATHS=$((PATHS + 1))
  path_exists "$path" || problem "$where: path not found: $path"
done <<EOF
$(cited_paths commands/*.md agents/*.md ai-commands/src/*.md)
EOF
[ "$PATHS" -gt 0 ] || problem "check-refs: no cited path found in commands/, agents/ or ai-commands/src/ (extraction failed?)"

# ---- 2. one site page per skill ------------------------------------------------
# Entries of the "pages" array of the meta.json $1, one per line.
meta_pages() {
  LC_ALL=C awk '
    { sub(/\r$/, "") }
    !inp && /"pages"[ \t]*:[ \t]*\[/ { inp = 1; sub(/.*"pages"[ \t]*:[ \t]*\[/, "") }
    inp {
      s = $0
      k = index(s, "]")
      if (k > 0) s = substr(s, 1, k - 1)
      while (match(s, /"[^"]*"/)) {
        print substr(s, RSTART + 1, RLENGTH - 2)
        s = substr(s, RSTART + RLENGTH)
      }
      if (k > 0) exit
    }
  ' "$1"
}
PAGES="$(meta_pages "$SITE_META")"
SKILLS=0
for d in skills/*/; do
  n="$(basename "$d")"
  SKILLS=$((SKILLS + 1))
  [ -f "$SITE_DIR/$n.mdx" ] || problem "$SITE_DIR/$n.mdx: missing site page for skill $n"
  printf '%s\n' "$PAGES" | grep -qxF "$n" || problem "$SITE_META: skill $n not listed in pages"
done
for f in "$SITE_DIR"/*.mdx; do
  [ -e "$f" ] || continue
  n="$(basename "$f" .mdx)"
  [ -d "skills/$n" ] || problem "$f: site page without skills/$n/"
done
for n in $PAGES; do
  case "$n" in *[!A-Za-z0-9_-]*) continue ;; esac   # separators, "...", etc.
  [ -d "skills/$n" ] || problem "$SITE_META: pages entry \"$n\" without skills/$n/"
done

# ---- 3. agents' skills: frontmatter --------------------------------------------
# Value of "name:" in the frontmatter of FILE (quotes and blanks removed).
frontmatter_name() {
  LC_ALL=C awk '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^name:/ { v = $0; sub(/^name:[ \t]*/, "", v); gsub(/["\047]/, "", v); sub(/[ \t]+$/, "", v); print v; exit }
  ' "$1"
}
# Names in the "skills:" list of FILE, one per line (block or inline list).
agent_skills() {
  LC_ALL=C awk '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    inlist && /^[ \t]+-/ { v = $0; sub(/^[ \t]+-[ \t]*/, "", v); gsub(/["\047]/, "", v); sub(/[ \t]+$/, "", v); print v; next }
    inlist && /^[ \t]*$/ { next }
    { inlist = 0 }
    /^skills:/ {
      v = $0; sub(/^skills:[ \t]*/, "", v)
      if (v == "") { inlist = 1; next }
      gsub(/[][ \t"\047]/, "", v)
      n = split(v, a, ",")
      for (i = 1; i <= n; i++) if (a[i] != "") print a[i]
    }
  ' "$1"
}
AGENT_REFS=0
for f in agents/*.md; do
  for s in $(agent_skills "$f"); do
    AGENT_REFS=$((AGENT_REFS + 1))
    if [ ! -f "skills/$s/SKILL.md" ]; then
      problem "$f: skills: $s has no skills/$s/SKILL.md"
    elif [ "$(frontmatter_name "skills/$s/SKILL.md")" != "$s" ]; then
      problem "$f: skills: $s does not match name: of skills/$s/SKILL.md ('$(frontmatter_name "skills/$s/SKILL.md")')"
    fi
  done
done

# ---- 4. hooks/session-start command list ---------------------------------------
SS="hooks/session-start"
ss_list="$(LC_ALL=C sed -n 's/^[[:blank:]]*echo "[[:blank:]]*\/advpl-specialist:\([A-Za-z0-9_-]*\)[[:blank:]]*"[[:blank:]]*$/\1/p' "$SS" | LC_ALL=C sort)"
cmd_list="$(for f in commands/*.md; do basename "$f" .md; done | LC_ALL=C sort)"
for c in $cmd_list; do
  printf '%s\n' "$ss_list" | grep -qx "$c" || problem "$SS: /advpl-specialist:$c missing from the command list"
done
for c in $ss_list; do
  [ -f "commands/$c.md" ] || problem "$SS: /advpl-specialist:$c listed but commands/$c.md does not exist"
done
dups="$(printf '%s\n' "$ss_list" | uniq -d)"
for c in $dups; do problem "$SS: /advpl-specialist:$c listed more than once"; done

echo "check-refs: $PROBLEMS problem(s) ($PATHS cited paths, $SKILLS skills, $AGENT_REFS agent skill refs, $(printf '%s\n' "$cmd_list" | grep -c .) commands)"
[ "$PROBLEMS" -eq 0 ]
