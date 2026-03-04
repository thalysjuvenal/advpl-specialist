---
description: Diagnose errors and problems in ADVPL/TLPP code - compilation errors, runtime errors, performance issues, and log analysis
allowed-tools: Read, Glob, Grep, Agent, WebSearch, WebFetch
argument-hint: "<file|error-message> [--log logfile]"
---

# /advpl-specialist:diagnose

Diagnose and resolve ADVPL/TLPP errors and problems.

## Usage

```bash
/advpl-specialist:diagnose <target> [options]
```

## Modes

| Mode | Input | What It Does |
|------|-------|-------------|
| File analysis | Path to .prw/.tlpp file | Scans code for potential issues |
| Error diagnosis | Error message in quotes | Identifies cause and suggests fix |
| Log analysis | --log flag with log file path | Parses log for errors and patterns |

## Options

| Flag | Description |
|------|------------|
| `--log` | Path to Protheus log file for analysis |
| `--verbose` | Show detailed diagnosis with explanations |

## Process

1. **Identify mode** - File path, error message, or log file
2. **Load debugging skill** - Invoke `advpl-debugging` skill
3. **Analyze input:**
   - **File:** Read code and scan for anti-patterns, missing error handling, lock issues
   - **Error:** Match against common-errors.md, then search TDN if not found
   - **Log:** Parse for ERROR/WARNING patterns, extract stack traces
4. **Report findings** - Clear explanation with severity levels
5. **Suggest fixes** - Specific code changes with examples
6. **Preventive advice** - How to avoid similar issues

## Examples

```bash
# Analyze a source file for issues
/advpl-specialist:diagnose src/FATA001.prw

# Diagnose a specific error message
/advpl-specialist:diagnose "THREAD ERROR ([55889]) Variable does not exist: cCodCli"

# Analyze a Protheus log file
/advpl-specialist:diagnose --log /var/protheus/console.log

# Verbose diagnosis with full explanations
/advpl-specialist:diagnose src/FATA001.prw --verbose
```

## Output

- List of issues found with severity (ERROR, WARNING, INFO)
- Root cause explanation for each issue
- Specific code fix with before/after comparison
- Preventive recommendations
