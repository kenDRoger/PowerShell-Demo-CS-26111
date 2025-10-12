#Problem: Trouble finding large stale files, search them by age and size
#Command Function
function Find-StaleLargeFilesBySize {
    [CmdletBinding()] #Advanced Cmdlet - allows for -Verbose param
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,                   # Directory to scan
        [int]$MaxAgeDays = 30,           # Files older than this are considered stale
        [int]$MinSizeMB = 5,             # Files larger than this are considered large
        [int]$First = 10,                # Show only first X large files
        [switch]$ExcludeDirectories      # Exclude directories
    )
    if(-not (Test-Path -Path $Path)){
        Write-Error "Path does not exist:$Path"
        return 0
    }
    [DateTime]$CutoffDate = (Get-Date).AddDays(-$MaxAgeDays)
    [Int32]$MinSizeBytes = $MinSizeMB * 1MB
    Write-Verbose "Scanning files older than $CutoffDate and larger than $MinSizeMB MB."

    class Item {#Class to Generalize Directory/File
        [string]$Name
        [string]$Type
        [string]$Directory
        [decimal]$Length
        [DateTime]$LastWriteTime
        [int]$AgeDays

        Item($Item) { #Constructor
            $this.Name = $Item.Name
            $this.Directory = if ($Item -is [System.IO.DirectoryInfo])  {$Item.FullName} else {$Item.Directory}
            $this.LastWriteTime = $Item.LastWriteTime
            $this.Type = if ($Item -is [System.IO.DirectoryInfo]) {'Directory'} else {'File'}
            $this.AgeDays = [math]::Round((New-TimeSpan -Start $Item.LastWriteTime -End (Get-Date)).TotalDays, 0)
            if ($Item -is [System.IO.FileInfo]) {
                $this.Length = [math]::Round($Item.Length / 1MB, 2)
            } else {
                $this.Length = Get-DirectorySizeInBytes -DirectoryPath $Item.FullName
            }
        }
    }
    $Params = @{
        Path = $Path
        ErrorAction = 'SilentlyContinue'
        Recurse = $true
    }
    if ($VerbosePreference -eq 'Continue') {
        $Params.Add('Verbose', $true)
    }
    if ($ExcludeDirectories) {
        $Params.Add('File', $true)
    }

    $StaleLargeFiles = Get-ChildItem @Params|
        ForEach-Object{[Item]::new($_)}|
        Where-Object { 
            $_.LastWriteTime -lt $CutoffDate -and 
            $_.Length -GT $MinSizeMB
            Write-Verbose "LastWriteTime:$($_.LastWriteTime) `t`t Length:$($_.Length) `t`t`t Name:$($_.Name)"
          } | 
        Sort-Object -Property Length -Descending
        Write-Verbose "CutoffDate: $CutOffDate"
        Write-Verbose "Minimum Size MB: $MinSizeMB"
        Write-Verbose "Sorted by Descending Length..."

    foreach ($File in $StaleLargeFiles) {
        [pscustomobject]@{
            FileName       = $File.Name
            Type = $File.Type
            Directory      = $File.Directory
            SizeMB         = $File.Length
            LastModified   = $File.LastWriteTime
            AgeDays        = $File.LastWriteTime
        }
    }
}
#Helper Function
function Get-DirectorySizeInBytes {
        param([string]$DirectoryPath)
        
        try {
            (Get-ChildItem -Path $DirectoryPath -File -Recurse -ErrorAction Stop | 
             Measure-Object -Property Length -Sum).Sum
        }
        catch {
            Write-Error "Could not calculate size for $DirectoryPath due to: $($_.Exception.Message)"
            return 0
        }
    }
#Use of Function as Command
# Syntax Find-StaleLargeFilesBySize -Path <String path> [-MaxAgeDays <int days>] [-MinSizeMB <int mb>] [-Verbose] [-First <int>]| Format-Table -AutoSize

# Find-StaleLargeFilesBySize -Path ./ -MaxAgeDays 15 -MinSizeMB 5 -Verbose | Select-Object -First 15 | Format-Table -AutoSize | Out-File ./StaleLargeFilesBySize.txt

Find-StaleLargeFilesBySize -Path ./ -MaxAgeDays 15 -MinSizeMB 5 -Verbose | Select-Object -First 15 | Format-Table -AutoSize