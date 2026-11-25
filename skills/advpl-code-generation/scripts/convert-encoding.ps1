# convert-encoding.ps1 - converts ADVPL/TLPP sources from UTF-8 to Windows-1252
#
# PowerShell twin of convert-encoding.sh: same CLI, same report lines on
# stdout (byte for byte), same stderr messages, same exit codes and the same
# resulting file bytes. See convert-encoding.sh for the options, the report
# lines, the exit codes and the translit mapping; any change there must be
# mirrored here. examples/encoding-tests/run-tests.sh compares both scripts
# step by step whenever pwsh or powershell is installed.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File convert-encoding.ps1
#          [--dry-run] [--translit] [-r] PATH...
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
# - output: UTF-8 bytes with LF line ends written straight to the standard
#   streams (no console encoding, no CRLF).

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:Argv = @($args)
$script:Usage = 'usage: convert-encoding [--dry-run] [--translit] [-r] PATH...'
$script:StdOut = [Console]::OpenStandardOutput()
$script:StdErr = [Console]::OpenStandardError()
$script:Utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
$script:Utf8Strict = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
$script:Exts = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
foreach ($e in @('prw', 'tlpp', 'prx', 'ch', 'prg', 'apw', 'aph', 'tlh', 'th')) { [void]$script:Exts.Add($e) }
# One match per code point outside Windows-1252: a surrogate pair (one code
# point above U+FFFF) or a BMP char outside U+0000-U+007F, U+00A0-U+00FF and
# the 27 code points of the bytes 0x80-0x9F (same list as CP1252_EXTRA in
# convert-encoding.sh). Built from numbers so that this file stays ASCII.
$cls = New-Object System.Text.StringBuilder
[void]$cls.Append('[^\x00-\x7F\xA0-\xFF')
foreach ($cp in @(0x0152, 0x0153, 0x0160, 0x0161, 0x0178, 0x017D, 0x017E, 0x0192, 0x02C6, 0x02DC,
    0x2013, 0x2014, 0x2018, 0x2019, 0x201A, 0x201C, 0x201D, 0x201E, 0x2020, 0x2021, 0x2022,
    0x2026, 0x2030, 0x2039, 0x203A, 0x20AC, 0x2122)) {
  [void]$cls.Append([char]$cp)
}
[void]$cls.Append(']')
$pair = '[' + [char]0xD800 + '-' + [char]0xDBFF + '][' + [char]0xDC00 + '-' + [char]0xDFFF + ']'
$script:RxOutside = New-Object System.Text.RegularExpressions.Regex -ArgumentList ($pair + '|' + $cls.ToString())
$script:Seps = [char[]]@('/')
if ([System.IO.Path]::DirectorySeparatorChar -ne '/') { $script:Seps = [char[]]@('/', [System.IO.Path]::DirectorySeparatorChar) }
$script:DryRun = $false
$script:Translit = $false
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
function Add-TreeFiles([string]$dir, [System.Collections.Generic.List[string]]$list) {
  try {
    $files = [System.IO.Directory]::GetFiles($dir)
    $dirs = [System.IO.Directory]::GetDirectories($dir)
  } catch {
    return
  }
  foreach ($f in $files) {
    if (-not (Test-Link $f)) { $list.Add($f) }
  }
  foreach ($d in $dirs) {
    if (-not (Test-Link $d)) { Add-TreeFiles $d $list }
  }
}

function Set-Failed([string]$line) {
  Write-Report $line
  $script:Failed = $true
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
  try {
    $text = $script:Utf8Strict.GetString($bytes, $start, $n - $start)
  } catch {
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
  # In place, not via temp file + rename: keeps inode, owner, permissions and
  # links, at the cost of atomicity (an interrupted write truncates the file).
  if (-not $script:DryRun) {
    try {
      [System.IO.File]::WriteAllBytes($p, $out)
    } catch {
      Set-Failed ('failed: ' + $p + ' (write error)')
      return
    }
  }
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
      if ($a -ceq '-r') { $recurse = $true; continue }
      if ($a -ceq '-h' -or $a -ceq '--help') {
        Write-Report $script:Usage
        exit 0
      }
      if ($a.Length -ge 2 -and $a.StartsWith('-', [System.StringComparison]::Ordinal)) { Exit-Usage ('unknown option: ' + $a) }
    }
    $paths.Add($a)
  }
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
