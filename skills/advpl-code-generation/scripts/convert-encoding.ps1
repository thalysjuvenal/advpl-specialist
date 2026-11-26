# convert-encoding.ps1 - converts ADVPL/TLPP sources from UTF-8 to Windows-1252
# (and, with --to-utf8, from Windows-1252 to UTF-8)
#
# PowerShell twin of convert-encoding.sh: same CLI, same report lines on
# stdout (byte for byte), same stderr messages, same exit codes and the same
# resulting file bytes. See convert-encoding.sh for the options, the report
# lines (already-utf8 and "undefined byte" included), the exit codes, the
# translit mapping and the --to-utf8 rules; any change there must be
# mirrored here. examples/encoding-tests/run-tests.sh compares both scripts
# step by step whenever pwsh or powershell is installed.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File convert-encoding.ps1
#          [--dry-run] [--translit | --to-utf8] [-r] PATH...
# (pwsh works the same way.)
#
# Compatibility: Windows PowerShell 5.1 (.NET Framework) and PowerShell 7+
# (.NET). Keep this file ASCII only (5.1 reads a BOM-less script in the ANSI
# code page) and do not use 7-only syntax (??, ?., ternary, &&/|| chains,
# -Parallel) nor ::new() (objects are built with New-Object).
#
# How the decisions map to .NET:
# - UTF-8 validity: UTF8Encoding with throwOnInvalidBytes (RFC 3629: rejects
#   overlongs, surrogates, code points above U+10FFFF and truncated
#   sequences, exactly like the awk decoder of the bash script);
# - Windows-1252 repertoire: RxOutside below, the same table as the bash
#   script. The encoder alone cannot decide: .NET maps five C1 controls
#   (U+0081 U+008D U+008F U+0090 U+009D) that the table excludes, and its
#   replacement fallback writes one "?" per UTF-16 unit on .NET (an emoji
#   gives "??") but one per surrogate pair on .NET Framework;
# - conversion: code page 1252 with EncoderExceptionFallback, so any
#   disagreement with the table fails loudly instead of writing a "?". On
#   .NET (pwsh 7) the code page needs CodePagesEncodingProvider, registered
#   only where that type exists (Windows PowerShell 5.1 has 1252 built in);
# - --to-utf8: the same UTF8Encoding decides validity. A file that is not
#   valid UTF-8 is read as Latin-1 (28591: one char per byte, same value,
#   built into both runtimes), the bytes the table leaves undefined fail it,
#   the 27 other bytes 0x80-0x9F become their table chars (the code page
#   decoder is not used: it would take the five undefined bytes as C1
#   controls) and the text is written as UTF-8 without BOM;
# - output: UTF-8 bytes with LF line ends written straight to the standard
#   streams (no console encoding, no CRLF).

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:Argv = @($args)
$script:Usage = 'usage: convert-encoding [--dry-run] [--translit | --to-utf8] [-r] PATH...'
$script:StdOut = [Console]::OpenStandardOutput()
$script:StdErr = [Console]::OpenStandardError()
$script:Utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
$script:Utf8Strict = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
$script:Latin1 = [System.Text.Encoding]::GetEncoding(28591)
$script:Exts = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
foreach ($e in @('prw', 'tlpp', 'prx', 'ch', 'prg', 'apw', 'aph', 'tlh', 'th')) { [void]$script:Exts.Add($e) }
# Windows-1252 bytes 0x80-0x9F and their Unicode code points (decimal BYTE:CP):
# the same text as CP1252_EXTRA in convert-encoding.sh. Everything below is
# built from these numbers, so that this file stays ASCII.
$script:Cp1252Extra = '128:8364 130:8218 131:402 132:8222 133:8230 134:8224 135:8225 136:710 137:8240 138:352 139:8249 140:338 142:381 145:8216 146:8217 147:8220 148:8221 149:8226 150:8211 151:8212 152:732 153:8482 154:353 155:8250 156:339 158:382 159:376'
# RxOutside: one match per code point outside Windows-1252, a surrogate pair
# (one code point above U+FFFF) or a BMP char outside U+0000-U+007F,
# U+00A0-U+00FF and the 27 code points of the table. C1Byte/C1Char: the table
# as chars (Latin-1 char of the byte, Unicode char). Undefined: the bytes
# 0x80-0x9F the table lacks (0x81 0x8D 0x8F 0x90 0x9D).
$cls = New-Object System.Text.StringBuilder
[void]$cls.Append('[^\x00-\x7F\xA0-\xFF')
$script:C1Byte = New-Object 'System.Collections.Generic.List[char]'
$script:C1Char = New-Object 'System.Collections.Generic.List[char]'
foreach ($pr in ($script:Cp1252Extra -split ' ')) {
  $kv = $pr -split ':'
  $script:C1Byte.Add([char][int]($kv[0]))
  $script:C1Char.Add([char][int]($kv[1]))
  [void]$cls.Append([char][int]($kv[1]))
}
[void]$cls.Append(']')
$pair = '[' + [char]0xD800 + '-' + [char]0xDBFF + '][' + [char]0xDC00 + '-' + [char]0xDFFF + ']'
$script:RxOutside = New-Object System.Text.RegularExpressions.Regex -ArgumentList ($pair + '|' + $cls.ToString())
$undef = New-Object 'System.Collections.Generic.List[char]'
for ($b = 0x80; $b -le 0x9F; $b++) {
  if (-not $script:C1Byte.Contains([char]$b)) { $undef.Add([char]$b) }
}
$script:Undefined = $undef.ToArray()
$script:Seps = [char[]]@('/')
if ([System.IO.Path]::DirectorySeparatorChar -ne '/') { $script:Seps = [char[]]@('/', [System.IO.Path]::DirectorySeparatorChar) }
$script:DryRun = $false
$script:Translit = $false
$script:ToUtf8 = $false
$script:Failed = $false
$script:Cp1252 = $null

function Write-Bytes([System.IO.Stream]$stream, [string]$text) {
  $bytes = $script:Utf8.GetBytes($text)
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Flush()
}

function Write-Report([string]$line) {
  Write-Bytes $script:StdOut ($line + "`n")
}

function Exit-Usage([string]$msg) {
  Write-Bytes $script:StdErr ('convert-encoding: ' + $msg + "`n" + $script:Usage + "`n")
  exit 2
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

# Extension after the last dot of the last path component, any case.
function Test-Advpl([string]$p) {
  $i = $p.LastIndexOf([char]'.')
  if ($i -lt 0) { return $false }
  $ext = $p.Substring($i + 1)
  if ($ext.IndexOf([char]'/') -ge 0 -or $ext.IndexOf([char]'\') -ge 0) { return $false }
  return $script:Exts.Contains($ext.ToLowerInvariant())
}

function Test-Link([string]$p) {
  return (([System.IO.File]::GetAttributes($p) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

# Regular files below $dir like `find DIR -type f`: hidden entries included,
# symbolic links neither listed nor followed, unreadable directories skipped.
# Each path is $dir as given plus "/" and the names below it, as find prints
# it: GetFiles/GetDirectories join with "\" on Windows, so only the last
# component of what they return is used.
function Add-TreeFiles([string]$dir, [System.Collections.Generic.List[string]]$list) {
  try {
    $files = [System.IO.Directory]::GetFiles($dir)
    $dirs = [System.IO.Directory]::GetDirectories($dir)
  } catch {
    return
  }
  $pre = $dir
  if ($pre.IndexOfAny($script:Seps, $pre.Length - 1) -lt 0) { $pre = $pre + '/' }
  foreach ($f in $files) {
    if (-not (Test-Link $f)) { $list.Add($pre + [System.IO.Path]::GetFileName($f)) }
  }
  foreach ($d in $dirs) {
    if (-not (Test-Link $d)) { Add-TreeFiles ($pre + [System.IO.Path]::GetFileName($d)) $list }
  }
}

function Set-Failed([string]$line) {
  Write-Report $line
  $script:Failed = $true
}

# Deletes the temporary file of a failed Save-Bytes (read-only attribute
# cleared first: Windows refuses to delete a read-only file).
function Remove-Temp([string]$t) {
  try {
    if ([System.IO.File]::Exists($t)) {
      [System.IO.File]::SetAttributes($t, [System.IO.FileAttributes]::Normal)
      [System.IO.File]::Delete($t)
    }
  } catch {
    return
  }
}

# Recovery of a failed File.Replace that already removed the source: on
# Windows, ReplaceFile without a backup file can fail with error 1176
# (ERROR_UNABLE_TO_MOVE_REPLACEMENT) after deleting $full, and then the new
# bytes exist only in $tmp. Moves $tmp to $full: $true when $full holds the
# new bytes again; $false when $full is there (nothing to recover) or $tmp
# is missing, or when the move fails too, and then $tmp is kept, since it is
# the only copy of the source.
function Restore-Temp([string]$tmp, [string]$full) {
  try {
    if ([System.IO.File]::Exists($full) -or -not [System.IO.File]::Exists($tmp)) { return $false }
    [System.IO.File]::Move($tmp, $full)
    return $true
  } catch {
    return $false
  }
}

# $p opens for writing (nothing written, nothing truncated), the test that
# [ -w FILE ] makes in convert-encoding.sh: $false for a read-only file, a
# file of another owner this user may not write, a locked file.
function Test-Writable([string]$p) {
  try {
    $fs = [System.IO.File]::Open($p, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
    $fs.Dispose()
    return $true
  } catch {
    return $false
  }
}

# $out -> $p unless --dry-run; $false after a "write error" line.
# The same steps as write_out in convert-encoding.sh. A $p this user may not
# write (read-only, of another owner, locked) fails first and is never
# touched: File.Replace would replace it anyway. Atomic: the bytes go to a
# temporary file in the directory of $p (.convert-encoding.<random>), which
# first gets a copy of $p (File.Copy keeps the mode on Unix and the
# attributes on Windows), and File.Replace (a rename) then puts it in place
# of $p, so an interrupted write never leaves a truncated source. On a
# failure the temporary file is deleted, except when File.Replace removed $p
# after the new bytes were complete: then Restore-Temp moves it back to $p
# and, when that works, the write counts as done. Written in place as before
# (not atomic) when $p is a symbolic link or the directory does not take a
# new file.
function Save-Bytes([string]$p, [byte[]]$out) {
  if ($script:DryRun) { return $true }
  if (-not (Test-Writable $p)) {
    Set-Failed ('failed: ' + $p + ' (write error)')
    return $false
  }
  $full = [System.IO.Path]::GetFullPath($p)
  $tmp = $null
  if (-not (Test-Link $p)) {
    $name = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($full), '.convert-encoding.' + [System.IO.Path]::GetRandomFileName())
    try {
      $fs = New-Object System.IO.FileStream -ArgumentList $name, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write)
      $fs.Dispose()
      $tmp = $name
    } catch {
      $tmp = $null
    }
  }
  if ($null -eq $tmp) {
    try {
      [System.IO.File]::WriteAllBytes($p, $out)
    } catch {
      Set-Failed ('failed: ' + $p + ' (write error)')
      return $false
    }
    return $true
  }
  $written = $false
  try {
    [System.IO.File]::Copy($full, $tmp, $true)
    [System.IO.File]::WriteAllBytes($tmp, $out)
    $written = $true
    [System.IO.File]::Replace($tmp, $full, [NullString]::Value)
  } catch {
    if ($written -and -not [System.IO.File]::Exists($full)) {
      # $p is gone and the new bytes are only in $tmp: never delete $tmp
      if (Restore-Temp $tmp $full) { return $true }
    } else {
      Remove-Temp $tmp
    }
    Set-Failed ('failed: ' + $p + ' (write error)')
    return $false
  }
  return $true
}

# --to-utf8 for a file that is not valid UTF-8: every byte, from the first
# one, read as Windows-1252 and written as UTF-8 without BOM.
function Convert-ToUtf8([string]$p, [byte[]]$bytes) {
  $text = $script:Latin1.GetString($bytes)
  if ($text.IndexOfAny($script:Undefined) -ge 0) {
    Set-Failed ('failed: ' + $p + ' (undefined byte)')
    return
  }
  for ($i = 0; $i -lt $script:C1Byte.Count; $i++) {
    $text = $text.Replace($script:C1Byte[$i], $script:C1Char[$i])
  }
  $out = $script:Utf8.GetBytes($text)
  if (Save-Bytes $p $out) { Write-Report ('converted: ' + $p) }
}

function Convert-File([string]$p) {
  if (-not (Test-Advpl $p)) {
    Write-Report ('skipped: ' + $p + ' (not advpl)')
    return
  }
  try {
    $bytes = [System.IO.File]::ReadAllBytes($p)
  } catch {
    Set-Failed ('failed: ' + $p + ' (read error)')
    return
  }
  $n = $bytes.Length
  $start = 0
  if ($n -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $start = 3 }
  $valid = $true
  try {
    $text = $script:Utf8Strict.GetString($bytes, $start, $n - $start)
  } catch {
    $valid = $false
  }
  # the same decoder decides in both directions
  if ($script:ToUtf8) {
    if ($valid) {
      Write-Report ('already-utf8: ' + $p)
    } else {
      Convert-ToUtf8 $p $bytes
    }
    return
  }
  if (-not $valid) {
    Write-Report ('already-cp1252: ' + $p)
    return
  }
  # valid UTF-8 has one char per byte only when every byte is ASCII
  if ($start -eq 0 -and $text.Length -eq $n) {
    Write-Report ('already-cp1252: ' + $p)
    return
  }
  $q = $script:RxOutside.Matches($text).Count
  if ($q -gt 0) {
    if (-not $script:Translit) {
      Set-Failed ('failed: ' + $p + ' (incompatible char)')
      return
    }
    $text = $script:RxOutside.Replace($text, '?')
  }
  try {
    $out = $script:Cp1252.GetBytes($text)
  } catch {
    Set-Failed ('failed: ' + $p + ' (incompatible char)')
    return
  }
  if (-not (Save-Bytes $p $out)) { return }
  if ($q -gt 0) {
    Write-Report ('translit: ' + $p + ' (' + $q + ')')
  } else {
    Write-Report ('converted: ' + $p)
  }
}

function Invoke-Main {
  [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
  $recurse = $false
  $optsDone = $false
  $paths = New-Object 'System.Collections.Generic.List[string]'
  foreach ($x in $script:Argv) {
    $a = [string]$x
    if (-not $optsDone) {
      if ($a -ceq '--') { $optsDone = $true; continue }
      if ($a -ceq '--dry-run') { $script:DryRun = $true; continue }
      if ($a -ceq '--translit') { $script:Translit = $true; continue }
      if ($a -ceq '--to-utf8') { $script:ToUtf8 = $true; continue }
      if ($a -ceq '-r') { $recurse = $true; continue }
      if ($a -ceq '-h' -or $a -ceq '--help') {
        Write-Report $script:Usage
        exit 0
      }
      if ($a.Length -ge 2 -and $a.StartsWith('-', [System.StringComparison]::Ordinal)) { Exit-Usage ('unknown option: ' + $a) }
    }
    $paths.Add($a)
  }
  if ($script:Translit -and $script:ToUtf8) { Exit-Usage '--to-utf8 cannot be combined with --translit' }
  if ($paths.Count -eq 0) { Exit-Usage 'no PATH given' }
  foreach ($p in $paths) {
    if ($p.Length -gt 0 -and [System.IO.Directory]::Exists($p)) {
      if (-not $recurse) { Exit-Usage ($p + ' is a directory (use -r)') }
    } elseif (-not (Test-Readable $p)) {
      Exit-Usage ('cannot read PATH: ' + $p)
    }
  }

  $provider = 'System.Text.CodePagesEncodingProvider' -as [type]
  if ($null -ne $provider) { [System.Text.Encoding]::RegisterProvider($provider::Instance) }
  $script:Cp1252 = [System.Text.Encoding]::GetEncoding(1252, (New-Object System.Text.EncoderExceptionFallback), (New-Object System.Text.DecoderExceptionFallback))

  foreach ($p in $paths) {
    if ($p.Length -gt 0 -and [System.IO.Directory]::Exists($p)) {
      $d = $p.TrimEnd($script:Seps)
      if ($d.Length -eq 0) { $d = $p.Substring(0, 1) }
      $list = New-Object 'System.Collections.Generic.List[string]'
      Add-TreeFiles $d $list
      $sorted = $list.ToArray()
      [System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)
      foreach ($f in $sorted) {
        if (Test-Advpl $f) { Convert-File $f }
      }
    } else {
      Convert-File $p
    }
  }
  if ($script:Failed) { exit 1 }
  exit 0
}

try {
  Invoke-Main
} catch {
  Write-Bytes $script:StdErr ('convert-encoding: internal error: ' + $_.Exception.Message + "`n")
  exit 2
}
