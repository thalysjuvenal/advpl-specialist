# advpl-lint.ps1 - static lint for ADVPL/TLPP sources (.prw .prx .tlpp .th)
#
# PowerShell twin of advpl-lint.sh: same CLI, same advpl-lint.rules, byte-
# identical stdout and the same exit codes; stderr carries the same messages
# (the usage line names this script).
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File advpl-lint.ps1
#          [--scope line|all] [--lines-file PATH] [--ignore-file PATH]
#          [--rules PATH] FILE...
# (pwsh works the same way.) See advpl-lint.sh for the meaning of every
# option, the output format and the exit codes. Any change to the semantics of
# advpl-lint.sh (stripping, matching, blocks, ignore, ordering) must be
# mirrored here; tests/lint/run-tests.sh compares both engines run by run.
#
# Compatibility: Windows PowerShell 5.1 and PowerShell 7+. Keep this file
# ASCII only (5.1 reads a BOM-less script in the ANSI code page) and do not use
# 7-only syntax (??, ?., ternary, &&/|| chains, -Parallel, Join-String).
#
# Byte fidelity with awk under LC_ALL=C:
# - files are read as bytes (Latin-1: one char per byte) and the output is
#   written as raw bytes with LF line ends; a FILE argument is printed as its
#   UTF-8 bytes, which is what bash receives in argv;
# - CASE=i lowercasing is ASCII only (awk tolower in the C locale);
# - rule regexes are POSIX ERE as awk reads them and are translated to .NET
#   syntax (escapes such as \t, \/ and octal \357, bracket expressions);
# - awk returns the leftmost-LONGEST match, .NET the leftmost-first one: every
#   accepted match is extended to the longest match at the same start;
# - every string comparison is ordinal and case-sensitive (PowerShell's -eq,
#   hashtables and switch ignore case by default).

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:Argv = @($args)
$script:Latin1 = [System.Text.Encoding]::GetEncoding(28591)
$script:Utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
$script:Ordinal = [System.StringComparison]::Ordinal
$script:OptNone = [System.Text.RegularExpressions.RegexOptions]::None
$script:OptMulti = [System.Text.RegularExpressions.RegexOptions]::Multiline
$script:OptRtl = [System.Text.RegularExpressions.RegexOptions]::RightToLeft
$script:Usage = 'usage: advpl-lint.ps1 [--scope line|all] [--lines-file PATH] [--ignore-file PATH] [--rules PATH] FILE...'
$script:StdErr = [Console]::OpenStandardError()
$script:FieldRule = 'ADV018'
$script:FuncRule = 'ADV017'

$script:Blanks = [char[]]@([char]32, [char]9)
$script:Special = [char[]]@([char]34, [char]39, [char]47, [char]38)
$script:ListChars = [char[]]@('(', ')', '{', '}', ',', '[', ']')
# Latin-1 uppercase letters that .NET would lowercase but awk (C locale) not
$script:Latin1Upper = New-Object 'char[]' 30
$k = 0
for ($c = 0xC0; $c -le 0xDE; $c++) {
  if ($c -ne 0xD7) { $script:Latin1Upper[$k] = [char]$c; $k++ }
}

function New-Rx([string]$pattern, [System.Text.RegularExpressions.RegexOptions]$options) {
  return [System.Text.RegularExpressions.Regex]::new($pattern, $options)
}

$script:RxCrLf = New-Rx '\r(?=\n)' $script:OptNone
$script:RxSkipRule = New-Rx '^[ \t]*(#|\z)' $script:OptNone
$script:RxId = New-Rx '^[A-Za-z0-9_]+\z' $script:OptNone
$script:RxDigits = New-Rx '^[0-9]+\z' $script:OptNone
$script:RxTrim = New-Rx '^[^A-Za-z0-9_#]+' $script:OptNone
$script:RxTok = New-Rx '^[A-Za-z0-9_]+' $script:OptNone
$script:RxInterval = New-Rx '\G\{[0-9]+(,[0-9]*)?\}' $script:OptNone
$script:RxWordRun = New-Rx '\G[A-Za-z0-9_]+' $script:OptNone
$script:RxStarLine = New-Rx '^[ \t]*\*' $script:OptNone
$script:RxSemiEnd = New-Rx ';[ \t]*\z' $script:OptNone
$script:RxEndClass = New-Rx '^[ \t]*end[ \t]*class([^a-z0-9_]|\z)' $script:OptNone
$script:RxClass = New-Rx '^[ \t]*class[ \t]+[a-z_]' $script:OptNone
$script:RxFunc = New-Rx '^[ \t]*((user|static|main)[ \t]+)?function[ \t]+[a-z_]' $script:OptNone
$script:RxMethod = New-Rx '^[ \t]*method[ \t]+[a-z_][a-z0-9_]*[ \t]*\(' $script:OptNone
$script:RxFuncHdr = New-Rx '^[ \t]*((user|static|main)[ \t]+)?function[ \t]+[a-z_][a-z0-9_]*' $script:OptNone
$script:RxParen = New-Rx '^[ \t]*\(' $script:OptNone
$script:RxDecl = New-Rx '^[ \t]*(local|private|public|static)[ \t]+' $script:OptNone
$script:RxLocal = New-Rx '^[ \t]*local' $script:OptNone
$script:RxAssign = New-Rx '[a-z_][a-z0-9_]*[ \t]*:=' $script:OptNone
$script:RxDeclItem = New-Rx '^[ \t]*[a-z_][a-z0-9_]*' $script:OptNone

# ---- output and helpers ------------------------------------------------------
# Strings that carry bytes hold one char per byte (Latin-1) and are written
# back with Latin-1, so every byte goes out unchanged.
function Write-Raw([System.IO.Stream]$stream, [string]$text) {
  $bytes = $script:Latin1.GetBytes($text)
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Flush()
}

function Write-Warn([string]$msg) {
  Write-Raw $script:StdErr ('advpl-lint: ' + $msg + "`n")
}

function Exit-Fatal([string]$msg) {
  Write-Warn $msg
  exit 2
}

function Exit-Usage([string]$msg) {
  Write-Raw $script:StdErr ('advpl-lint: ' + $msg + "`n" + $script:Usage + "`n")
  exit 2
}

# A command-line argument as the bytes bash would print: its UTF-8 encoding.
function ConvertTo-ByteString([string]$s) {
  return $script:Latin1.GetString($script:Utf8.GetBytes($s))
}

# ASCII-only case mapping (awk toupper/tolower under LC_ALL=C).
function ConvertTo-AsciiLower([string]$s) {
  $low = $s.ToLowerInvariant()
  $k = $s.IndexOfAny($script:Latin1Upper)
  if ($k -lt 0) { return $low }
  $a = $low.ToCharArray()
  while ($k -ge 0) {
    $a[$k] = $s[$k]
    $k = $s.IndexOfAny($script:Latin1Upper, $k + 1)
  }
  return [string]::new([char[]]$a)
}

function ConvertTo-AsciiUpper([string]$s) {
  $a = $s.ToCharArray()
  for ($k = 0; $k -lt $a.Length; $k++) {
    $c = [int]$a[$k]
    if ($c -ge 97 -and $c -le 122) { $a[$k] = [char]($c - 32) }
  }
  return [string]::new([char[]]$a)
}

function Test-Readable([string]$p) {
  if ($p.Length -eq 0) { return $false }
  try {
    if (-not [System.IO.File]::Exists($p)) { return $false }
    $fs = [System.IO.File]::OpenRead($p)
    $fs.Dispose()
    return $true
  } catch {
    return $false
  }
}

# Lines of a file as awk's getline sees them: split on LF, a final LF does not
# start an empty line, one CR before each line end is removed.
function Read-Lines([string]$path) {
  $text = $script:Latin1.GetString([System.IO.File]::ReadAllBytes($path))
  $text = $script:RxCrLf.Replace($text, '')
  $parts = $text.Split([char]10)
  $n = $parts.Length
  if ($parts[$n - 1].Length -eq 0) { $n-- }
  $lines = New-Object 'string[]' $n
  [Array]::Copy($parts, $lines, $n)
  if ($n -gt 0) {
    $last = $lines[$n - 1]
    if ($last.Length -gt 0 -and [int]$last[$last.Length - 1] -eq 13) {
      $lines[$n - 1] = $last.Substring(0, $last.Length - 1)
    }
  }
  return , $lines
}

# ---- POSIX ERE (as awk reads it) -> .NET regex -------------------------------
# Literal characters other than [A-Za-z0-9_] are written as \uXXXX, which is a
# literal in and out of a character class.
function Add-Literal([System.Text.StringBuilder]$sb, [int]$code) {
  if (($code -ge 48 -and $code -le 57) -or ($code -ge 65 -and $code -le 90) -or ($code -ge 97 -and $code -le 122) -or $code -eq 95) {
    [void]$sb.Append([char]$code)
  } else {
    [void]$sb.Append('\u').Append($code.ToString('X4'))
  }
}

function Test-HexDigit([int]$c) {
  return (($c -ge 48 -and $c -le 57) -or ($c -ge 65 -and $c -le 70) -or ($c -ge 97 -and $c -le 102))
}

# awk escape at $re[$i] (a backslash): \t \n \r \f \v \a \b, octal \d \dd \ddd,
# hex \xh \xhh; any other \c is the literal c. Sets EscCode and EscNext.
function Read-Escape([string]$re, [int]$i) {
  $n = $re.Length
  if ($i + 1 -ge $n) {
    $script:EscCode = 92
    $script:EscNext = $i + 1
    return
  }
  $d = [int]$re[$i + 1]
  $j = $i + 2
  $code = $d
  if ($d -eq 116) { $code = 9 }
  elseif ($d -eq 110) { $code = 10 }
  elseif ($d -eq 114) { $code = 13 }
  elseif ($d -eq 102) { $code = 12 }
  elseif ($d -eq 118) { $code = 11 }
  elseif ($d -eq 97) { $code = 7 }
  elseif ($d -eq 98) { $code = 8 }
  elseif ($d -ge 48 -and $d -le 55) {
    $code = $d - 48
    $cnt = 1
    while ($cnt -lt 3 -and $j -lt $n -and [int]$re[$j] -ge 48 -and [int]$re[$j] -le 55) {
      $code = $code * 8 + ([int]$re[$j] - 48)
      $j++
      $cnt++
    }
    $code = $code -band 255
  } elseif ($d -eq 120 -and $j -lt $n -and (Test-HexDigit ([int]$re[$j]))) {
    $code = 0
    $cnt = 0
    while ($cnt -lt 2 -and $j -lt $n -and (Test-HexDigit ([int]$re[$j]))) {
      $code = $code * 16 + [System.Convert]::ToInt32([string]$re[$j], 16)
      $j++
      $cnt++
    }
  }
  $script:EscCode = $code
  $script:EscNext = $j
}

# Bracket expression at $re[$i] ("["): "^" negates, a "]" right after "[" or
# "[^" is literal, "\" escapes, "-" between two members is a range. Appends a
# .NET class and returns the index after the closing "]".
function Add-Bracket([string]$re, [int]$i, [System.Text.StringBuilder]$sb) {
  $n = $re.Length
  $j = $i + 1
  $neg = $false
  if ($j -lt $n -and [int]$re[$j] -eq 94) { $neg = $true; $j++ }
  $codes = New-Object 'System.Collections.Generic.List[int]'
  $dash = New-Object 'System.Collections.Generic.List[bool]'
  if ($j -lt $n -and [int]$re[$j] -eq 93) { $codes.Add(93); $dash.Add($false); $j++ }
  while ($j -lt $n -and [int]$re[$j] -ne 93) {
    if ([int]$re[$j] -eq 92) {
      Read-Escape $re $j
      $codes.Add($script:EscCode)
      $dash.Add($false)
      $j = $script:EscNext
    } else {
      $c = [int]$re[$j]
      $codes.Add($c)
      $dash.Add($c -eq 45)
      $j++
    }
  }
  if ($j -ge $n) { throw 'unterminated bracket expression' }
  [void]$sb.Append('[')
  if ($neg) { [void]$sb.Append('^') }
  $k = 0
  $m = $codes.Count
  while ($k -lt $m) {
    if ($k + 2 -lt $m -and $dash[$k + 1]) {
      Add-Literal $sb $codes[$k]
      [void]$sb.Append('-')
      Add-Literal $sb $codes[$k + 2]
      $k += 3
    } else {
      Add-Literal $sb $codes[$k]
      $k++
    }
  }
  [void]$sb.Append(']')
  return $j + 1
}

# ERE operators ( ) | * + ? {m,n} . ^ $ keep their meaning; everything else is
# a literal. A quantifier right after another one applies to the quantified
# atom in ERE, so the atom is wrapped in (?:...) (.NET would read "*?" as lazy).
# A "^" anchor is written "(?:^)" so that Get-Longest can disable it.
function Convert-Ere([string]$re) {
  $sb = New-Object System.Text.StringBuilder
  $groups = New-Object 'System.Collections.Generic.Stack[int]'
  $n = $re.Length
  $i = 0
  $atom = -1
  $quant = $false
  while ($i -lt $n) {
    $c = [int]$re[$i]
    if ($c -eq 92) {
      Read-Escape $re $i
      $atom = $sb.Length
      $quant = $false
      Add-Literal $sb $script:EscCode
      $i = $script:EscNext
    } elseif ($c -eq 91) {
      $atom = $sb.Length
      $quant = $false
      $i = Add-Bracket $re $i $sb
    } elseif ($c -eq 40) {
      $groups.Push($sb.Length)
      [void]$sb.Append('(')
      $atom = -1
      $quant = $false
      $i++
    } elseif ($c -eq 41) {
      if ($groups.Count -eq 0) { throw 'unmatched )' }
      [void]$sb.Append(')')
      $atom = $groups.Pop()
      $quant = $false
      $i++
    } elseif ($c -eq 42 -or $c -eq 43 -or $c -eq 63 -or $c -eq 123) {
      $len = 1
      if ($c -eq 123) {
        $m = $script:RxInterval.Match($re, $i)
        if ($m.Success) { $len = $m.Length } else { $len = 0 }
      }
      if ($atom -lt 0 -or $len -eq 0) {
        $atom = $sb.Length
        $quant = $false
        Add-Literal $sb $c
        $i++
      } else {
        if ($quant) {
          [void]$sb.Insert($atom, '(?:')
          [void]$sb.Append(')')
        }
        [void]$sb.Append($re.Substring($i, $len))
        $quant = $true
        $i += $len
      }
    } elseif ($c -eq 94) {
      [void]$sb.Append('(?:^)')
      $atom = -1
      $quant = $false
      $i++
    } elseif ($c -eq 124 -or $c -eq 36) {
      [void]$sb.Append([char]$c)
      $atom = -1
      $quant = $false
      $i++
    } elseif ($c -eq 46) {
      $atom = $sb.Length
      $quant = $false
      [void]$sb.Append('.')
      $i++
    } else {
      # a run of [A-Za-z0-9_] is copied at once; a quantifier after it
      # applies to its last character only
      $quant = $false
      $m = $script:RxWordRun.Match($re, $i)
      if ($m.Success) {
        [void]$sb.Append($m.Value)
        $atom = $sb.Length - 1
        $i += $m.Length
      } else {
        $atom = $sb.Length
        Add-Literal $sb $c
        $i++
      }
    }
  }
  if ($groups.Count -gt 0) { throw 'unmatched (' }
  return $sb.ToString()
}

# Compiled forms of a translated regex P: Rx searches a line; RxM (multiline)
# finds candidate lines in a whole view; Rtl0/Rtl (right-to-left, built on
# first use by Get-Longest) find the longest match at a given start.
# Without $scan (the REGEX2 exception of forbid) only Rx is needed.
function New-RuleRx([string]$re, [bool]$scan) {
  $p = Convert-Ere $re
  $multi = $null
  if ($scan) { $multi = New-Rx $p $script:OptMulti }
  return @{
    P = $p
    Rx = New-Rx $p $script:OptNone
    RxM = $multi
    Rtl0 = $null
    Rtl = $null
  }
}

# Path glob -> regex matched against FILE with "\" turned into "/" (same rules
# as glob_to_ere in advpl-lint.sh: "**/" zero or more directories, "**"
# anything, "*" and "?" inside one segment, anchored at a segment boundary and
# at the end; a leading "./" is dropped; case-sensitive).
function Convert-Glob([string]$g) {
  $g = $g.Replace('\', '/')
  while ($g.Length -ge 2 -and $g.Substring(0, 2) -ceq './') { $g = $g.Substring(2) }
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('(?:^|/)')
  $n = $g.Length
  $i = 0
  while ($i -lt $n) {
    if ($i + 3 -le $n -and $g.Substring($i, 3) -ceq '**/') {
      [void]$sb.Append('(?:[\s\S]*/)?')
      $i += 3
      continue
    }
    if ($i + 2 -le $n -and $g.Substring($i, 2) -ceq '**') {
      [void]$sb.Append('[\s\S]*')
      $i += 2
      continue
    }
    $c = [int]$g[$i]
    if ($c -eq 42) { [void]$sb.Append('[^/]*') }
    elseif ($c -eq 63) { [void]$sb.Append('[^/]') }
    else { Add-Literal $sb $c }
    $i++
  }
  [void]$sb.Append('\z')
  return New-Rx $sb.ToString() $script:OptNone
}

# ---- .advpl-specialist-ignore ------------------------------------------------
function Read-Ignore([string]$path) {
  if ($path.Length -eq 0) { return }
  $lines = Read-Lines $path
  for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i].Trim($script:Blanks)
    if ($line.Length -eq 0 -or [int]$line[0] -eq 35) { continue }
    $kw = $line
    $arg = ''
    $k = $line.IndexOfAny($script:Blanks)
    if ($k -ge 0) {
      $kw = $line.Substring(0, $k)
      $arg = $line.Substring($k).TrimStart($script:Blanks)
    }
    $single = ($arg.Length -gt 0 -and $arg.IndexOfAny($script:Blanks) -lt 0)
    if ($kw -ceq 'path' -and $arg.Length -gt 0) {
      $script:PathRx.Add((Convert-Glob $arg))
    } elseif ($single -and $kw -ceq 'rule') {
      [void]$script:IgnRule.Add((ConvertTo-AsciiUpper $arg))
    } elseif ($single -and $kw -ceq 'field') {
      [void]$script:IgnField.Add((ConvertTo-AsciiLower $arg))
    } elseif ($single -and $kw -ceq 'function') {
      [void]$script:IgnFunc.Add((ConvertTo-AsciiLower $arg))
    } else {
      Write-Warn ('warning: ' + (ConvertTo-ByteString $path) + ':' + ($i + 1) + ': unknown or malformed directive ignored: ' + $line)
    }
  }
}

# ---- advpl-lint.rules ----------------------------------------------------------
# TAB-separated: ID SEVERITY SCOPE KIND TARGET CASE EXTS REGEX REGEX2 MESSAGE REF
function Read-Rules([string]$path) {
  $where = ConvertTo-ByteString $path
  $lines = Read-Lines $path
  for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($script:RxSkipRule.IsMatch($line)) { continue }
    $bad = 'invalid rule at ' + $where + ':' + ($i + 1)
    $f = $line.Split([char]9)
    $ok = ($f.Length -eq 11)
    if ($ok) {
      $ok = $script:RxId.IsMatch($f[0])
      $ok = $ok -and ($f[1] -ceq 'error' -or $f[1] -ceq 'warn')
      $ok = $ok -and ($f[2] -ceq 'line' -or $f[2] -ceq 'file')
      $ok = $ok -and ($f[3] -ceq 'forbid' -or $f[3] -ceq 'require' -or $f[3] -ceq 'balance' -or $f[3] -ceq 'undeclared')
      $ok = $ok -and ($f[4] -ceq 'code' -or $f[4] -ceq 'raw') -and ($f[5] -ceq 'i' -or $f[5] -ceq 'c')
      $ok = $ok -and $f[6].Length -gt 0 -and $f[7].Length -gt 0 -and $f[7] -cne '-' -and $f[8].Length -gt 0
      $ok = $ok -and $f[9].Length -gt 0 -and $f[10].Length -gt 0
      $ok = $ok -and ($f[3] -ceq 'forbid' -or $f[2] -ceq 'file')
      $ok = $ok -and ($f[3] -cne 'balance' -or $f[8] -cne '-')
      $ok = $ok -and ($f[3] -cne 'undeclared' -or ($f[4] -ceq 'code' -and $f[5] -ceq 'i'))
    }
    if (-not $ok) { Exit-Fatal $bad }
    $casei = ($f[5] -ceq 'i')
    $kind = $f[3]
    # "\t" in a regex becomes a real TAB (as in advpl-lint.sh)
    $re = $f[7].Replace('\t', "`t")
    $re2 = $f[8].Replace('\t', "`t")
    $core = Get-Core $re $casei
    $bound = $script:CoreBound
    if ($core.Length -eq 0) { Exit-Fatal $bad }
    $bound2 = $false
    if ($re2 -ceq '-') { $re2 = '' }
    if ($kind -ceq 'balance') {
      $re2 = Get-Core $re2 $casei
      $bound2 = $script:CoreBound
      if ($re2.Length -eq 0) { Exit-Fatal $bad }
    }
    $rule = @{
      Id = $f[0]
      IsError = ($f[1] -ceq 'error')
      Kind = $kind
      Code = ($f[4] -ceq 'code')
      CaseI = $casei
      Exts = ',' + (ConvertTo-AsciiLower $f[6]) + ','
      Bound = $bound
      Bound2 = $bound2
      Main = $null
      Second = $null
    }
    # compile now: a broken regex aborts before any output. Main is the core
    # of REGEX; Second is REGEX2 (balance: counterpart core, scanned like
    # Main; forbid: exception; require/undeclared: compiled, unused).
    try {
      $rule.Main = New-RuleRx $core $true
      if ($re2.Length -gt 0) { $rule.Second = New-RuleRx $re2 ($kind -ceq 'balance') }
    } catch {
      Exit-Fatal ('invalid regex in rule at ' + $where + ':' + ($i + 1) + ': ' + $_.Exception.Message)
    }
    # SCOPE=file rules only run with --scope all and without --lines-file
    $rule.Enabled = ($f[2] -ceq 'line' -or ($script:Scope -ceq 'all' -and -not $script:UseLines))
    $uref = ConvertTo-AsciiUpper $f[10]
    $rule.RuleIgnored = ($script:IgnRule.Contains((ConvertTo-AsciiUpper $f[0])) -or ($uref -cne '-' -and $script:IgnRule.Contains($uref)))
    $sev = 'warning'
    if ($rule.IsError) { $sev = 'error' }
    $tail = $sev + ' ' + $f[0] + ' ' + $f[9]
    if ($f[10] -cne '-') { $tail = $tail + ' [' + $f[10] + ']' }
    $rule.Tail = $tail
    $script:Rules.Add($rule)
  }
}

# C24: a leading "(^|[^a-z0-9_])" (CASE=i) or "(^|[^A-Za-z0-9_])" (CASE=c) is
# a left word boundary checked by Find-Next; returns the rest (the core) and
# sets CoreBound.
function Get-Core([string]$re, [bool]$casei) {
  $script:CoreBound = $false
  if ($casei -and $re.StartsWith('(^|[^a-z0-9_])', $script:Ordinal)) {
    $script:CoreBound = $true
    return $re.Substring(14)
  }
  if (-not $casei -and $re.StartsWith('(^|[^A-Za-z0-9_])', $script:Ordinal)) {
    $script:CoreBound = $true
    return $re.Substring(17)
  }
  return $re
}

function Read-WantedLines([string]$path) {
  $lines = Read-Lines $path
  foreach ($line in $lines) {
    $t = $line.Trim($script:Blanks)
    if (-not $script:RxDigits.IsMatch($t)) { continue }
    $v = [long]0
    if ([long]::TryParse($t, [ref]$v) -and $v -le [int]::MaxValue) { [void]$script:Want.Add([int]$v) }
  }
}

# ---- TARGET=code view of a line (C7-C9) ----------------------------------------
# Same state machine as code_of() in advpl-lint.sh: comment text and literal
# contents become spaces (columns preserved); literals keep their delimiters,
# never span lines and run to the end of the line when unterminated; "//" and
# "&&" comment to the end of the line; "/* ... */" spans lines (InBlock); "*"
# as the first non-blank character comments the line (not on a line that
# closes a block).
function Get-CodeView([string]$line) {
  $n = $line.Length
  $i = 0
  $sb = $script:CodeSb
  [void]$sb.Clear()
  if ($script:InBlock) {
    $j = $line.IndexOf('*/', $script:Ordinal)
    if ($j -lt 0) { return [string]::new([char]32, $n) }
    [void]$sb.Append([char]32, $j + 2)
    $i = $j + 2
    $script:InBlock = $false
  } elseif ($script:RxStarLine.IsMatch($line)) {
    return [string]::new([char]32, $n)
  }
  while ($i -lt $n) {
    $k = $line.IndexOfAny($script:Special, $i)
    if ($k -lt 0) {
      [void]$sb.Append($line, $i, $n - $i)
      break
    }
    [void]$sb.Append($line, $i, $k - $i)
    $i = $k
    $c = [int]$line[$i]
    $c2 = -1
    if ($i + 1 -lt $n) { $c2 = [int]$line[$i + 1] }
    if ($c -eq 34 -or $c -eq 39) {
      $j = $line.IndexOf([char]$c, $i + 1)
      if ($j -lt 0) {
        [void]$sb.Append([char]$c).Append([char]32, $n - $i - 1)
        $i = $n
      } else {
        [void]$sb.Append([char]$c).Append([char]32, $j - $i - 1).Append([char]$c)
        $i = $j + 1
      }
    } elseif (($c -eq 47 -and $c2 -eq 47) -or ($c -eq 38 -and $c2 -eq 38)) {
      [void]$sb.Append([char]32, $n - $i)
      $i = $n
    } elseif ($c -eq 47 -and $c2 -eq 42) {
      $j = $line.IndexOf('*/', $i + 2, $script:Ordinal)
      if ($j -lt 0) {
        [void]$sb.Append([char]32, $n - $i)
        $i = $n
        $script:InBlock = $true
      } else {
        [void]$sb.Append([char]32, $j + 2 - $i)
        $i = $j + 2
      }
    } else {
      [void]$sb.Append([char]$c)
      $i++
    }
  }
  return $sb.ToString()
}

# ---- matching -------------------------------------------------------------------
# C24 matcher: start of the first accepted match of rx in s at or after q, or
# -1; sets MLen (.NET length). "^" never matches after position 0 when the
# search starts at q > 0 (Regex.Match(s, q)), like the no-"^" copy in awk.
# With bound, a candidate preceded by [A-Za-z0-9_] is rejected and the search
# restarts one character after its start.
function Find-Next([System.Text.RegularExpressions.Regex]$rx, [bool]$bound, [string]$s, [int]$q) {
  $n = $s.Length
  while ($q -le $n) {
    $m = $rx.Match($s, $q)
    if (-not $m.Success) { return -1 }
    $st = $m.Index
    if ($bound -and $st -gt 0) {
      $c = [int]$s[$st - 1]
      if (($c -ge 97 -and $c -le 122) -or ($c -ge 65 -and $c -le 90) -or ($c -ge 48 -and $c -le 57) -or $c -eq 95) {
        $q = $st + 1
        continue
      }
    }
    $script:MLen = $m.Length
    return $st
  }
  return -1
}

# Length of the longest match at st of the regex set $set, given the .NET
# (leftmost-first) match length $len: awk returns the leftmost-LONGEST match.
# A right-to-left search of "^(?:P)" over s[st, end) tries the ends from the
# right, so its first match is the longest one starting at st; in that
# substring "$" is the real line end and "^" is st, so the anchors of P are
# disabled when st > 0 (as "^" never matches there in a line search).
function Get-Longest($set, [string]$s, [int]$st, [int]$len) {
  $n = $s.Length
  if ($st + $len -ge $n) { return $len }
  if ($st -eq 0) {
    if ($null -eq $set.Rtl0) { $set.Rtl0 = New-Rx ('^(?:' + $set.P + ')') $script:OptRtl }
    $m = $set.Rtl0.Match($s, 0, $n)
  } else {
    if ($null -eq $set.Rtl) { $set.Rtl = New-Rx ('^(?:' + $set.P.Replace('(?:^)', '(?!)') + ')') $script:OptRtl }
    $m = $set.Rtl.Match($s, $st, $n - $st)
  }
  if ($m.Success -and $m.Length -gt $len) { return $m.Length }
  return $len
}

# Lines (0-based, ascending) of the view that may hold a match: a superset of
# the lines where the per-line search can match (multiline search over the
# joined view, resuming at the start of the next line after each hit).
function Get-Candidates([System.Text.RegularExpressions.Regex]$rxm, [string]$joined) {
  $res = New-Object 'System.Collections.Generic.List[int]'
  $starts = $script:Cur.Starts
  $n = $script:Cur.N
  if ($n -eq 0) { return , $res }
  $pos = 0
  while ($true) {
    $m = $rxm.Match($joined, $pos)
    if (-not $m.Success) { break }
    $ln = [Array]::BinarySearch($starts, $m.Index)
    if ($ln -lt 0) { $ln = (-bnot $ln) - 1 }
    $res.Add($ln)
    if ($ln + 1 -ge $n) { break }
    $pos = $starts[$ln + 1]
  }
  return , $res
}

# Joined text (lines separated by LF) of a view: code or raw, lowercased
# (ASCII only) when CASE=i. Every view has the same line starts.
function Get-View([bool]$code, [bool]$casei) {
  $c = $script:Cur
  if ($code) {
    if ($null -eq $c.CodeJ) { $c.CodeJ = [string]::Join("`n", $c.Code) }
    if (-not $casei) { return $c.CodeJ }
    if ($null -eq $c.LowCodeJ) { $c.LowCodeJ = ConvertTo-AsciiLower $c.CodeJ }
    return $c.LowCodeJ
  }
  if ($null -eq $c.RawJ) { $c.RawJ = [string]::Join("`n", $c.Raw) }
  if (-not $casei) { return $c.RawJ }
  if ($null -eq $c.LowRawJ) { $c.LowRawJ = ConvertTo-AsciiLower $c.RawJ }
  return $c.LowRawJ
}

function Get-LineOf([string]$joined, [int]$l) {
  return $joined.Substring($script:Cur.Starts[$l], $script:Cur.Raw[$l].Length)
}

function Get-Token([string]$m) {
  $m = $script:RxTrim.Replace($m, '')
  $t = $script:RxTok.Match($m)
  if ($t.Success) { $m = $t.Value }
  return ConvertTo-AsciiLower $m
}

function Test-Ignored($r, [string]$m) {
  if ($script:PathIgnored -or $r.RuleIgnored) { return $true }
  if ($r.Id -cne $script:FieldRule -and $r.Id -cne $script:FuncRule) { return $false }
  $tok = Get-Token $m
  if ($r.Id -ceq $script:FieldRule) { return $script:IgnField.Contains($tok) }
  return $script:IgnFunc.Contains($tok)
}

function Add-Finding($r, [int]$ln, [string]$m) {
  if (Test-Ignored $r $m) {
    $script:Suppressed++
    return
  }
  if ($r.IsError) { $script:Errors++ } else { $script:Warnings++ }
  $script:FL.Add($ln)
  $script:FR.Add($r)
}

# forbid: one finding per C24 match of the core not covered by the REGEX2
# exception (searched in the match without its leading characters outside
# [A-Za-z0-9_#]).
function Invoke-Scan($r, [string]$s, [int]$ln) {
  $set = $r.Main
  $exc = $null
  if ($null -ne $r.Second) { $exc = $r.Second.Rx }
  $q = 0
  while ($true) {
    $st = Find-Next $set.Rx $r.Bound $s $q
    if ($st -lt 0) { return }
    $len = Get-Longest $set $s $st $script:MLen
    $m = $s.Substring($st, $len)
    if ($null -eq $exc -or -not $exc.IsMatch($script:RxTrim.Replace($m, ''))) { Add-Finding $r $ln $m }
    if ($len -gt 0) { $q = $st + $len } else { $q = $st + 1 }
  }
}

# Number of C24 matches of the regex set $set in s.
function Get-MatchCount($set, [bool]$bound, [string]$s) {
  $cnt = 0
  $q = 0
  while ($true) {
    $st = Find-Next $set.Rx $bound $s $q
    if ($st -lt 0) { return $cnt }
    $cnt++
    $len = Get-Longest $set $s $st $script:MLen
    if ($len -gt 0) { $q = $st + $len } else { $q = $st + 1 }
  }
}

# ---- SCOPE=file kinds (require, balance, undeclared) ---------------------------
# require: one finding at line 1 when no line of the view matches.
function Invoke-Require($r) {
  $j = Get-View $r.Code $r.CaseI
  foreach ($l in (Get-Candidates $r.Main.RxM $j)) {
    if ((Find-Next $r.Main.Rx $r.Bound (Get-LineOf $j $l) 0) -ge 0) { return }
  }
  Add-Finding $r 1 ''
}

# Blocks (C25) on the lowercased code view, as build_blocks() in
# advpl-lint.sh: logical lines join a line whose code ends with ";" to the
# next one (that ";" becomes a space); LOff[ln] is where physical line ln
# starts in its logical line; regions: 0 file level, -1 class region, b > 0
# block b.
function Build-Blocks {
  $c = $script:Cur
  $n = $c.N
  $lines = New-Object 'string[]' 0
  if ($n -gt 0) { $lines = (Get-View $true $true).Split([char]10) }
  $b = @{
    LOff = (New-Object 'int[]' $n)
    LogOf = (New-Object 'int[]' $n)
    Reg = (New-Object 'int[]' $n)
    LFirst = (New-Object 'System.Collections.Generic.List[int]')
    LLast = (New-Object 'System.Collections.Generic.List[int]')
    LTxt = (New-Object 'System.Collections.Generic.List[string]')
    LHdr = (New-Object 'System.Collections.Generic.List[bool]')
    LReg = (New-Object 'System.Collections.Generic.List[int]')
    NBlk = 0
  }
  $state = 0
  $nblk = 0
  $ln = 0
  while ($ln -lt $n) {
    $k = $b.LTxt.Count
    $b.LFirst.Add($ln)
    $s = ''
    while ($ln -lt $n) {
      $t = $lines[$ln]
      $b.LOff[$ln] = $s.Length
      $b.LogOf[$ln] = $k
      $ln++
      $m = $null
      if ($t.IndexOf([char]59) -ge 0) { $m = $script:RxSemiEnd.Match($t) }
      if ($null -eq $m -or -not $m.Success) {
        $s = $s + $t
        break
      }
      $s = $s + $t.Substring(0, $m.Index) + ' ' + $t.Substring($m.Index + 1)
    }
    $b.LLast.Add($ln - 1)
    $b.LTxt.Add($s)
    if ($state -eq -1) {
      $b.LReg.Add(-1)
      $b.LHdr.Add($false)
      if ($script:RxEndClass.IsMatch($s)) { $state = 0 }
      continue
    }
    if ($script:RxClass.IsMatch($s)) {
      $b.LReg.Add(-1)
      $b.LHdr.Add($false)
      $state = -1
      continue
    }
    $hdr = $false
    if ($script:RxFunc.IsMatch($s) -or $script:RxMethod.IsMatch($s)) {
      $nblk++
      $state = $nblk
      $hdr = $true
    }
    $b.LHdr.Add($hdr)
    $b.LReg.Add($state)
  }
  for ($i = 0; $i -lt $n; $i++) { $b.Reg[$i] = $b.LReg[$b.LogOf[$i]] }
  $b.NBlk = $nblk
  $script:Blk = $b
}

# balance (C26): per block, when the C24 matches of REGEX outnumber those of
# REGEX2, one finding at the block's first line with a REGEX match.
function Invoke-Balance($r) {
  $b = $script:Blk
  $nb = $b.NBlk
  $bal1 = New-Object 'int[]' ($nb + 1)
  $bal2 = New-Object 'int[]' ($nb + 1)
  $first = New-Object 'int[]' ($nb + 1)
  for ($i = 0; $i -le $nb; $i++) { $first[$i] = -1 }
  $j = Get-View $r.Code $r.CaseI
  foreach ($l in (Get-Candidates $r.Main.RxM $j)) {
    $blk = $b.Reg[$l]
    if ($blk -le 0) { continue }
    $cnt = Get-MatchCount $r.Main $r.Bound (Get-LineOf $j $l)
    if ($cnt -gt 0 -and $first[$blk] -lt 0) { $first[$blk] = $l }
    $bal1[$blk] += $cnt
  }
  foreach ($l in (Get-Candidates $r.Second.RxM $j)) {
    $blk = $b.Reg[$l]
    if ($blk -le 0) { continue }
    $bal2[$blk] += Get-MatchCount $r.Second $r.Bound2 (Get-LineOf $j $l)
  }
  for ($blk = 1; $blk -le $nb; $blk++) {
    if ($bal1[$blk] -gt $bal2[$blk]) { Add-Finding $r ($first[$blk] + 1) '' }
  }
}

# Declared names of a comma list (C27): split on "," outside (), [] and {};
# the list ends at the end of s or at a ")", "]" or "}" that closes nothing.
function Add-NamesFromList([string]$s, [int]$blk) {
  $n = $s.Length
  $last = $n - 1
  $depth = 0
  $start = 0
  $i = 0
  while ($i -lt $n) {
    $k = $s.IndexOfAny($script:ListChars, $i)
    if ($k -lt 0) { break }
    $i = $k
    $c = [int]$s[$i]
    if ($c -eq 40 -or $c -eq 91 -or $c -eq 123) {
      $depth++
    } elseif ($c -eq 44) {
      if ($depth -eq 0) {
        Add-Decl $s.Substring($start, $i - $start) $blk
        $start = $i + 1
      }
    } elseif ($depth -eq 0) {
      $last = $i - 1
      break
    } else {
      $depth--
    }
    $i++
  }
  $len = $last - $start + 1
  if ($len -lt 0) { $len = 0 }
  Add-Decl $s.Substring($start, $len) $blk
}

function Add-Decl([string]$item, [int]$blk) {
  $m = $script:RxDeclItem.Match($item)
  if (-not $m.Success) { return }
  [void]$script:Decl.Add([string]$blk + '|' + $m.Value.TrimStart($script:Blanks))
}

# Parameters of block blk from its header t: the list after the "(" that
# follows the name (no "(" after a function name: no parameters).
function Add-HeaderParams([string]$t, [int]$blk) {
  $m = $script:RxMethod.Match($t)
  if ($m.Success) {
    $rest = $t.Substring($m.Length)
  } else {
    $rest = $t
    $m = $script:RxFuncHdr.Match($t)
    if ($m.Success) { $rest = $t.Substring($m.Length) }
    $m = $script:RxParen.Match($rest)
    if (-not $m.Success) { return }
    $rest = $rest.Substring($m.Length)
  }
  Add-NamesFromList $rest $blk
}

# Assignments of statement [p, e) of logical line k (text t) in block blk:
# every match of [a-z_][a-z0-9_]*[ \t]*:= (the next search starts after its
# ":=") whose start is not preceded by [a-z0-9_] and whose last non-blank
# character before it is not ":", "[" or the ">" of "->".
function Find-Assign([int]$k, [string]$t, [int]$p, [int]$e, [int]$blk) {
  $b = $script:Blk
  $q = $p
  while ($q -lt $e) {
    $m = $script:RxAssign.Match($t.Substring($q, $e - $q))
    if (-not $m.Success) { return }
    $st = $q + $m.Index
    $q = $st + $m.Length
    if ($st -gt 0) {
      $c = [int]$t[$st - 1]
      if (($c -ge 97 -and $c -le 122) -or ($c -ge 48 -and $c -le 57) -or $c -eq 95) { continue }
    }
    $j = $st - 1
    while ($j -ge 0 -and ([int]$t[$j] -eq 32 -or [int]$t[$j] -eq 9)) { $j-- }
    if ($j -ge 0) {
      $c = [int]$t[$j]
      if ($c -eq 58 -or $c -eq 91 -or ($c -eq 62 -and $j -gt 0 -and [int]$t[$j - 1] -eq 45)) { continue }
    }
    $ln = $b.LLast[$k]
    while ($ln -gt $b.LFirst[$k] -and $b.LOff[$ln] -gt $st) { $ln-- }
    $script:AsnB.Add($blk)
    $script:AsnN.Add($m.Value.Substring(0, $m.Length - 2).TrimEnd($script:Blanks))
    $script:AsnL.Add($ln)
  }
}

# undeclared (H4, C27), as run_undeclared() in advpl-lint.sh.
function Invoke-Undeclared($r) {
  $b = $script:Blk
  $script:Decl = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
  $seen = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
  $script:AsnB = New-Object 'System.Collections.Generic.List[int]'
  $script:AsnN = New-Object 'System.Collections.Generic.List[string]'
  $script:AsnL = New-Object 'System.Collections.Generic.List[int]'
  $nlog = $b.LTxt.Count
  for ($k = 0; $k -lt $nlog; $k++) {
    $blk = $b.LReg[$k]
    if ($blk -lt 0) { continue }
    $t = $b.LTxt[$k]
    if ($b.LHdr[$k]) {
      Add-HeaderParams $t $blk
      continue
    }
    $n = $t.Length
    $p = 0
    while ($p -lt $n) {
      $e = $t.IndexOf([char]59, $p)
      if ($e -lt 0) { $e = $n }
      $stmt = $t.Substring($p, $e - $p)
      $m = $script:RxDecl.Match($stmt)
      if ($m.Success) {
        if ($blk -gt 0 -or -not $script:RxLocal.IsMatch($stmt)) { Add-NamesFromList $stmt.Substring($m.Length) $blk }
      } elseif ($blk -gt 0) {
        Find-Assign $k $t $p $e $blk
      }
      $p = $e + 1
    }
  }
  for ($i = 0; $i -lt $script:AsnN.Count; $i++) {
    $nm = $script:AsnN[$i]
    $key = [string]$script:AsnB[$i] + '|' + $nm
    if ($script:Decl.Contains($key) -or $script:Decl.Contains('0|' + $nm) -or $seen.Contains($key)) { continue }
    if ((Find-Next $r.Main.Rx $r.Bound $nm 0) -ge 0) { continue }
    [void]$seen.Add($key)
    Add-Finding $r ($script:AsnL[$i] + 1) ''
  }
}

# ---- one FILE ------------------------------------------------------------------
function Get-Ext([string]$path) {
  $b = $path.Replace('\', '/')
  $k = $b.LastIndexOf([char]47)
  if ($k -ge 0) { $b = $b.Substring($k + 1) }
  $k = $b.LastIndexOf([char]46)
  if ($k -lt 0) { return '' }
  return ConvertTo-AsciiLower $b.Substring($k + 1)
}

# Findings sorted by (line, ID in byte order), ties in the order they were
# added (forbid rules first, each line by line, then the file rules).
function Write-Findings([string]$path) {
  $cnt = $script:FL.Count
  if ($cnt -eq 0) { return }
  $keys = New-Object 'string[]' $cnt
  $idx = New-Object 'int[]' $cnt
  for ($i = 0; $i -lt $cnt; $i++) {
    $keys[$i] = $script:FL[$i].ToString('D10') + "`t" + $script:FR[$i].Id + "`t" + $i.ToString('D10')
    $idx[$i] = $i
  }
  [Array]::Sort($keys, $idx, [System.StringComparer]::Ordinal)
  foreach ($i in $idx) {
    [void]$script:Out.Append($path).Append(':').Append($script:FL[$i].ToString('D')).Append(': ').Append($script:FR[$i].Tail).Append("`n")
  }
}

# $file opens the file, $path (its UTF-8 bytes) is printed and matched.
function Invoke-LintFile([string]$file, [string]$path) {
  $ext = Get-Ext $path
  if ($ext.Length -eq 0 -or ',prw,prx,tlpp,th,'.IndexOf(',' + $ext + ',', $script:Ordinal) -lt 0) { return }
  $forbid = New-Object 'System.Collections.Generic.List[object]'
  $fileRules = New-Object 'System.Collections.Generic.List[object]'
  foreach ($r in $script:Rules) {
    if (-not $r.Enabled) { continue }
    if ($r.Exts -cne ',*,' -and $r.Exts.IndexOf(',' + $ext + ',', $script:Ordinal) -lt 0) { continue }
    if ($r.Kind -ceq 'forbid') { $forbid.Add($r) } else { $fileRules.Add($r) }
  }
  $norm = $path.Replace('\', '/')
  $script:PathIgnored = $false
  foreach ($g in $script:PathRx) {
    if ($g.IsMatch($norm)) { $script:PathIgnored = $true }
  }
  $script:FL = New-Object 'System.Collections.Generic.List[int]'
  $script:FR = New-Object 'System.Collections.Generic.List[object]'
  $raw = Read-Lines $file
  $n = $raw.Length
  $code = New-Object 'string[]' $n
  $script:InBlock = $false
  for ($l = 0; $l -lt $n; $l++) { $code[$l] = Get-CodeView $raw[$l] }
  $starts = New-Object 'int[]' $n
  $pos = 0
  for ($l = 0; $l -lt $n; $l++) {
    $starts[$l] = $pos
    $pos += $raw[$l].Length + 1
  }
  $script:Cur = @{ Raw = $raw; Code = $code; Starts = $starts; N = $n; RawJ = $null; CodeJ = $null; LowRawJ = $null; LowCodeJ = $null }
  foreach ($r in $forbid) {
    $j = Get-View $r.Code $r.CaseI
    foreach ($l in (Get-Candidates $r.Main.RxM $j)) {
      if ($script:UseLines -and -not $script:Want.Contains($l + 1)) { continue }
      Invoke-Scan $r (Get-LineOf $j $l) ($l + 1)
    }
  }
  if ($fileRules.Count -gt 0) {
    Build-Blocks
    foreach ($r in $fileRules) {
      if ($r.Kind -ceq 'require') { Invoke-Require $r }
      elseif ($r.Kind -ceq 'balance') { Invoke-Balance $r }
      else { Invoke-Undeclared $r }
    }
  }
  Write-Findings $path
}

# ---- main ----------------------------------------------------------------------
function Invoke-Main {
  [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
  $argv = $script:Argv
  $n = $argv.Count
  $scope = 'all'
  $linesFile = ''
  $ignoreFile = ''
  $ignoreGiven = $false
  $rulesFile = [System.IO.Path]::Combine($PSScriptRoot, 'advpl-lint.rules')
  $i = 0
  while ($i -lt $n) {
    $a = [string]$argv[$i]
    if ($a -ceq '--scope' -or $a -ceq '--lines-file' -or $a -ceq '--ignore-file' -or $a -ceq '--rules') {
      if ($i + 1 -ge $n) { Exit-Usage ('option ' + $a + ' requires a value') }
      $v = [string]$argv[$i + 1]
      if ($a -ceq '--scope') {
        if ($v -ceq 'line' -or $v -ceq 'all') { $scope = $v }
        else { Exit-Usage ('invalid --scope value: ' + (ConvertTo-ByteString $v)) }
      } elseif ($a -ceq '--lines-file') {
        $linesFile = $v
      } elseif ($a -ceq '--ignore-file') {
        $ignoreFile = $v
        $ignoreGiven = $true
      } else {
        $rulesFile = $v
      }
      $i += 2
      continue
    }
    if ($a -ceq '--') {
      $i++
      break
    }
    if ($a.Length -ge 2 -and $a.StartsWith('-', $script:Ordinal)) { Exit-Usage ('unknown option: ' + (ConvertTo-ByteString $a)) }
    break
  }
  $files = New-Object 'System.Collections.Generic.List[string]'
  for (; $i -lt $n; $i++) { $files.Add([string]$argv[$i]) }

  if ($files.Count -eq 0) { Exit-Usage 'no FILE given' }
  if (-not (Test-Readable $rulesFile)) { Exit-Usage ('cannot read rules file: ' + (ConvertTo-ByteString $rulesFile)) }
  if ($linesFile.Length -gt 0 -and -not (Test-Readable $linesFile)) { Exit-Usage ('cannot read lines file: ' + (ConvertTo-ByteString $linesFile)) }
  if ($ignoreGiven) {
    if (-not (Test-Readable $ignoreFile)) { Exit-Usage ('cannot read ignore file: ' + (ConvertTo-ByteString $ignoreFile)) }
  } elseif (Test-Readable './.advpl-specialist-ignore') {
    $ignoreFile = './.advpl-specialist-ignore'
  }
  foreach ($f in $files) {
    if (-not (Test-Readable $f)) { Exit-Usage ('cannot read FILE: ' + (ConvertTo-ByteString $f)) }
  }

  $script:Scope = $scope
  $script:UseLines = ($linesFile.Length -gt 0)
  $script:Errors = 0
  $script:Warnings = 0
  $script:Suppressed = 0
  $script:Rules = New-Object 'System.Collections.Generic.List[object]'
  $script:PathRx = New-Object 'System.Collections.Generic.List[System.Text.RegularExpressions.Regex]'
  $script:IgnRule = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
  $script:IgnField = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
  $script:IgnFunc = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
  $script:Want = New-Object 'System.Collections.Generic.HashSet[int]'
  $script:CodeSb = New-Object System.Text.StringBuilder
  $script:Out = New-Object System.Text.StringBuilder

  Read-Ignore $ignoreFile
  Read-Rules $rulesFile
  if ($script:UseLines) { Read-WantedLines $linesFile }
  foreach ($f in $files) { Invoke-LintFile $f (ConvertTo-ByteString $f) }
  [void]$script:Out.Append('advpl-lint: ' + $script:Errors + ' error(s), ' + $script:Warnings + ' warning(s), ' + $script:Suppressed + " suppressed`n")
  Write-Raw ([Console]::OpenStandardOutput()) $script:Out.ToString()
  if ($script:Errors -gt 0) { exit 1 }
  exit 0
}

try {
  Invoke-Main
} catch {
  Write-Warn ('internal error: ' + $_.Exception.Message)
  exit 2
}
