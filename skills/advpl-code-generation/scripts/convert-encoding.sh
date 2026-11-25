#!/usr/bin/env bash
# convert-encoding.sh - converts ADVPL/TLPP sources from UTF-8 to Windows-1252
# (and, with --to-utf8, from Windows-1252 to UTF-8)
#
# TOTVS Protheus compiles ADVPL/TLPP sources as Windows-1252 while AI tools
# write UTF-8. This script and its PowerShell twin convert-encoding.ps1 (same
# CLI, byte-identical stdout, stderr, exit codes and resulting files) convert
# them back. The advpl-specialist PostToolUse hook calls this script with
# --translit; any other agent can run it by hand after editing a source.
# --to-utf8 serves an editor that refuses files that are not UTF-8: convert,
# edit, then run the normal mode to get Windows-1252 back.
#
# Usage: convert-encoding.sh [--dry-run] [--translit | --to-utf8] [-r] PATH...
#   --dry-run   report what would happen, write nothing
#   --translit  replace every character without a Windows-1252 representation
#               by "?" instead of failing (see "Translit mapping")
#   --to-utf8   the opposite direction: rewrite Windows-1252 sources as UTF-8
#               without BOM (see "To UTF-8"); not allowed with --translit
#   -r          a PATH may be a directory: every ADVPL file below it, sorted by
#               byte order; files with other extensions there are ignored
#   --          end of options (options may also follow the paths)
#
# Report, one line per file on stdout:
#   converted: P            UTF-8 (with or without BOM) rewritten as Windows-1252
#                           (with --to-utf8: Windows-1252 rewritten as UTF-8)
#   already-cp1252: P       nothing to do: not valid UTF-8 (so taken as
#                           Windows-1252) or pure ASCII without BOM
#   already-utf8: P         --to-utf8, nothing to do: valid UTF-8 (pure ASCII
#                           included) with or without BOM, which stays
#   translit: P (N)         converted with --translit, N characters became "?"
#   failed: P (incompatible char)  a character has no Windows-1252
#                           representation (no --translit): file left untouched
#   failed: P (undefined byte)  --to-utf8: a byte 0x81, 0x8D, 0x8F, 0x90 or
#                           0x9D, undefined in Windows-1252: file left untouched
#   failed: P (write error) the converted bytes could not be written
#   failed: P (read error)  a file found by -r cannot be read (the run goes on)
#   skipped: P (not advpl)  extension other than .prw .tlpp .prx .ch .prg .apw
#                           .aph .tlh .th (any case)
# Exit: 0 ok; 1 some file failed; 2 usage error (unknown option, --translit
# with --to-utf8, no PATH, unreadable PATH, directory without -r: all checked
# before any file is touched). Messages on stderr start with "convert-encoding:".
#
# Engine: one awk pass over the bytes (od -tu1) decodes UTF-8 strictly
# (RFC 3629: no overlongs, no surrogates, nothing above U+10FFFF, no truncated
# sequence) and writes Windows-1252 from the table below. iconv is not used:
# the macOS iconv transliterates silently even without //TRANSLIT (U+2192
# becomes "->") and, on macOS 27, fails ("Inappropriate ioctl for device")
# whenever a multibyte sequence straddles byte offset 1024 of the input.
#
# Translit mapping (identical in both scripts, never platform dependent): the
# Windows-1252 repertoire is U+0000-U+007F, U+00A0-U+00FF and the 27 code
# points the code page maps at 0x80-0x9F (CP1252_EXTRA below). Every other
# code point becomes exactly one "?" (0x3F): C1 controls U+0080-U+009F,
# arrows, CJK, U+FFFD and characters outside the BMP (an emoji is one "?").
# A Windows-1252 file whose bytes happen to be valid UTF-8 (e.g. only the
# pair C3 A9, "A tilde + copyright sign") cannot be told apart and is
# converted like UTF-8 (with --to-utf8: reported already-utf8).
#
# To UTF-8 (--to-utf8): the same strict decoder decides, so "valid UTF-8"
# means the same in both directions. A file that is not valid UTF-8 is read
# as Windows-1252 from its first byte (BOM bytes in front of Windows-1252
# text included) and a second awk pass writes each byte as UTF-8 through the
# same table: 0x00-0x7F unchanged, 0xA0-0xFF as U+00A0-U+00FF, 0x80-0x9F as
# CP1252_EXTRA. CR, LF and a missing final newline are kept, so the normal
# mode (without --translit) gives back the original bytes.
#
# Requirements: bash 3.2+, od, awk (POSIX), grep, find, sort, mktemp (no
# `file`, iconv, jq, Node or Python).

set -u
export LC_ALL=C

USAGE='usage: convert-encoding [--dry-run] [--translit | --to-utf8] [-r] PATH...'
# Windows-1252 bytes 0x80-0x9F and their Unicode code points (decimal BYTE:CP)
CP1252_EXTRA='128:8364 130:8218 131:402 132:8222 133:8230 134:8224 135:8225 136:710 137:8240 138:352 139:8249 140:338 142:381 145:8216 146:8217 147:8220 148:8221 149:8226 150:8211 151:8212 152:732 153:8482 154:353 155:8250 156:339 158:382 159:376'
HIGH_BYTE=$(printf '[\200-\377]')

usage_error() {
  printf 'convert-encoding: %s\n%s\n' "$1" "$USAGE" >&2
  exit 2
}

report() { printf '%s\n' "$1"; }

is_advpl() {
  case $1 in
    *.[Pp][Rr][Ww] | *.[Tt][Ll][Pp][Pp] | *.[Pp][Rr][Xx] | *.[Cc][Hh] | *.[Pp][Rr][Gg] | \
      *.[Aa][Pp][Ww] | *.[Aa][Pp][Hh] | *.[Tt][Ll][Hh] | *.[Tt][Hh]) return 0 ;;
  esac
  return 1
}

# to_cp1252 FILE SKIP: FILE from byte SKIP on, decoded as UTF-8 -> $TMPD/out
# in Windows-1252 ("?" for each code point outside it); $TMPD/status gets
# "invalid" (not UTF-8) or the number of "?" written. Bytes go through as
# decimal numbers, so NUL and CR come out unchanged. Fails when FILE cannot
# be read.
to_cp1252() {
  rm -f "$TMPD/status"
  od -An -v -tu1 -j "$2" -- "$1" >"$TMPD/bytes" 2>/dev/null || return 1
  STATUS_FILE="$TMPD/status" awk -v extra="$CP1252_EXTRA" '
    function emit(c) {
      if (c >= 160 && c <= 255) printf "%c", c
      else if (c in byte_of) printf "%c", byte_of[c]
      else { printf "?"; q++ }
    }
    BEGIN {
      n = split(extra, t, " ")
      for (i = 1; i <= n; i++) { split(t[i], p, ":"); byte_of[p[2] + 0] = p[1] + 0 }
    }
    {
      for (i = 1; i <= NF; i++) {
        b = $i + 0
        if (need) {
          if (b < 128 || b > 191) { bad = 1; exit }
          cp = cp * 64 + b - 128
          if (--need) continue
          if (cp < lo || (cp >= 55296 && cp <= 57343) || cp > 1114111) { bad = 1; exit }
          emit(cp)
        }
        else if (b < 128) printf "%c", b
        else if (b >= 194 && b <= 223) { need = 1; cp = b - 192; lo = 128 }
        else if (b >= 224 && b <= 239) { need = 2; cp = b - 224; lo = 2048 }
        else if (b >= 240 && b <= 244) { need = 3; cp = b - 240; lo = 65536 }
        else { bad = 1; exit }
      }
    }
    END {
      if (bad || need) print "invalid" > ENVIRON["STATUS_FILE"]
      else print q + 0 > ENVIRON["STATUS_FILE"]
    }' <"$TMPD/bytes" >"$TMPD/out"
}

# from_cp1252 FILE SKIP: FILE read as Windows-1252 -> $TMPD/out in UTF-8 (no
# BOM); $TMPD/status gets "ok", or "undefined" at the first byte of 0x80-0x9F
# that CP1252_EXTRA lacks. SKIP is the one to_cp1252 just used: with 0, its
# $TMPD/bytes already holds every byte of FILE; otherwise FILE is read again
# from byte 0. Bytes go through as decimal numbers, so NUL and CR come out
# unchanged. Fails when FILE cannot be read.
from_cp1252() {
  rm -f "$TMPD/status"
  if [ "$2" != 0 ]; then
    od -An -v -tu1 -- "$1" >"$TMPD/bytes" 2>/dev/null || return 1
  fi
  STATUS_FILE="$TMPD/status" awk -v extra="$CP1252_EXTRA" '
    function emit(c) {
      if (c < 2048) printf "%c%c", 192 + int(c / 64), 128 + c % 64
      else printf "%c%c%c", 224 + int(c / 4096), 128 + int(c / 64) % 64, 128 + c % 64
    }
    BEGIN {
      n = split(extra, t, " ")
      for (i = 1; i <= n; i++) { split(t[i], p, ":"); cp_of[p[1] + 0] = p[2] + 0 }
    }
    {
      for (i = 1; i <= NF; i++) {
        b = $i + 0
        if (b < 128) printf "%c", b
        else if (b >= 160) emit(b)
        else if (b in cp_of) emit(cp_of[b])
        else { bad = 1; exit }
      }
    }
    END {
      if (bad) print "undefined" > ENVIRON["STATUS_FILE"]
      else print "ok" > ENVIRON["STATUS_FILE"]
    }' <"$TMPD/bytes" >"$TMPD/out"
}

fail() { report "failed: $1 ($2)"; failed=1; }

# write_out FILE: $TMPD/out -> FILE unless --dry-run; reports a write error.
# In place, not via temp file + rename: keeps inode, owner, permissions and
# links, at the cost of atomicity (an interrupted write truncates the file).
write_out() {
  if [ "$dry_run" = 0 ] && ! { cat "$TMPD/out" >"$1"; } 2>/dev/null; then
    fail "$1" "write error"
    return 1
  fi
  return 0
}

# Every external command gets FILE after "--": a path may start with "-".
process() {
  local f="$1" skip=0 bom q
  if ! is_advpl "$f"; then report "skipped: $f (not advpl)"; return 0; fi
  if ! bom=$(od -An -tx1 -N3 -- "$f" 2>/dev/null); then fail "$f" "read error"; return 0; fi
  if [ "${bom//[[:space:]]/}" = efbbbf ]; then
    skip=3
  else
    grep -q -e "$HIGH_BYTE" -- "$f" 2>/dev/null
    case $? in
      0) ;;
      1)   # pure ASCII is valid UTF-8 and valid Windows-1252
        if [ "$to_utf8" = 1 ]; then report "already-utf8: $f"; else report "already-cp1252: $f"; fi
        return 0 ;;
      *) fail "$f" "read error"; return 0 ;;
    esac
  fi
  if ! to_cp1252 "$f" "$skip"; then fail "$f" "read error"; return 0; fi
  q=$(cat "$TMPD/status" 2>/dev/null)
  if [ "$to_utf8" = 1 ]; then process_to_utf8 "$f" "$q" "$skip"; return 0; fi
  case $q in
    invalid) report "already-cp1252: $f"; return 0 ;;
    0) ;;
    [1-9]*) if [ "$translit" = 0 ]; then fail "$f" "incompatible char"; return 0; fi ;;
    *) fail "$f" "incompatible char"; return 0 ;;   # awk died
  esac
  write_out "$f" || return 0
  if [ "$q" = 0 ]; then report "converted: $f"; else report "translit: $f ($q)"; fi
}

# process_to_utf8 FILE STATUS SKIP: the --to-utf8 end of process; STATUS is
# the verdict of the UTF-8 decoder (to_cp1252 FILE SKIP), the same in both
# directions.
process_to_utf8() {
  local f="$1"
  case $2 in
    invalid) ;;
    [0-9]*) report "already-utf8: $f"; return 0 ;;
    *) fail "$f" "read error"; return 0 ;;   # awk died
  esac
  if ! from_cp1252 "$f" "$3"; then fail "$f" "read error"; return 0; fi
  case $(cat "$TMPD/status" 2>/dev/null) in
    ok) ;;
    undefined) fail "$f" "undefined byte"; return 0 ;;
    *) fail "$f" "read error"; return 0 ;;   # awk died
  esac
  write_out "$f" || return 0
  report "converted: $f"
}

dry_run=0; translit=0; to_utf8=0; recurse=0; failed=0
paths=()
opts_done=0
for a in "$@"; do
  if [ "$opts_done" = 0 ]; then
    case $a in
      --) opts_done=1; continue ;;
      --dry-run) dry_run=1; continue ;;
      --translit) translit=1; continue ;;
      --to-utf8) to_utf8=1; continue ;;
      -r) recurse=1; continue ;;
      -h | --help) report "$USAGE"; exit 0 ;;
      -?*) usage_error "unknown option: $a" ;;
    esac
  fi
  paths[${#paths[@]}]=$a
done
if [ "$translit" = 1 ] && [ "$to_utf8" = 1 ]; then
  usage_error "--to-utf8 cannot be combined with --translit"
fi
[ "${#paths[@]}" -gt 0 ] || usage_error "no PATH given"
for p in "${paths[@]}"; do
  if [ -d "$p" ]; then
    [ "$recurse" = 1 ] || usage_error "$p is a directory (use -r)"
  elif [ ! -f "$p" ] || [ ! -r "$p" ]; then
    usage_error "cannot read PATH: $p"
  fi
done
TMPD=$(mktemp -d -- "${TMPDIR:-/tmp}/convert-encoding.XXXXXX") || {
  printf 'convert-encoding: cannot create a temporary directory\n' >&2
  exit 2
}
trap 'rm -rf "$TMPD"' EXIT

for p in "${paths[@]}"; do
  if [ -d "$p" ]; then
    d=${p%"${p##*[!/]}"}   # without trailing slashes: "dir/" lists "dir/x.prw"
    [ -n "$d" ] || d=/
    # find reads a leading "-" as an expression: list "./-dir", print "-dir/..."
    case $d in -*) fd=./$d ;; *) fd=$d ;; esac
    find "$fd" -type f -print 2>/dev/null | sort >"$TMPD/list"
    while IFS= read -r f; do
      [ "$fd" = "$d" ] || f=${f#./}
      if is_advpl "$f"; then process "$f"; fi
    done <"$TMPD/list"
  else
    process "$p"
  fi
done
exit "$failed"
