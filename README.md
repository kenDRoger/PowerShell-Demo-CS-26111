# PowerShell Demo — Find Stale, Large Files

Coursework for **CS26111 — Programming Languages** (University of Santo Tomas), Project #1 (2025–2026). A small PowerShell exercise demonstrating advanced functions, `[CmdletBinding]`, and pipeline one-liners.

## The problem
Find files that are **both stale and large** — i.e. not modified in N days *and* bigger than M MB — so you can clean up old bulk.

## Contents

| File | What it is |
|------|------------|
| `main.ps1` | `Find-StaleLargeFilesBySize` — an advanced function (`[CmdletBinding]`, so it supports `-Verbose`). Parameters: `-Path` (required), `-MaxAgeDays` (default 30), `-MinSizeMB` (default 5), `-ExcludeDirectories`. |
| `one-liner-version.ps1` | The same idea as a single `Get-ChildItem \| Where-Object \| Sort-Object \| Select-Object \| Format-Table` pipeline (files only, no helper functions). |
| `find-stalelargefiles.exe` | Compiled executable of the utility. |

## Usage

```powershell
# Load the function, then scan a folder for files older than 60 days and larger than 10 MB
. .\main.ps1
Find-StaleLargeFilesBySize -Path "C:\Users\you\Downloads" -MaxAgeDays 60 -MinSizeMB 10 -Verbose

# Or run the one-liner version against the current directory
.\one-liner-version.ps1
```

## Notes
- "Stale" is measured by `LastWriteTime` versus `(Get-Date).AddDays(-MaxAgeDays)`.
- "Large" is measured against `MinSizeMB` converted to bytes.
- Results are returned as `PSCustomObject`s (name, directory, size in MB, last write time, age in days).
