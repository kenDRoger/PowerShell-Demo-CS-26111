#One Liner Command(Doesn't need any Functions) - Only works for Files
Get-ChildItem -Path ./ -File -Recurse -ErrorAction SilentlyContinue| #Path
        Where-Object { 
            $_.LastWriteTime -lt (Get-Date).AddDays(-1) -and #MaxAgeDate
            $_.Length -gt 1MB * 1 #MinSizeMB
        } | 
        Sort-Object -Property Length -Descending | 
        Select-Object -First 10 | #First
        ForEach-Object {
            [pscustomobject]@{ 
                FileName       = $_.Name
                Directory      = $_.DirectoryName
                SizeMB         = [math]::Round($_.Length / 1MB, 2)
                LastModified   = $_.LastWriteTime
                AgeDays        = [math]::Round((New-TimeSpan -Start $_.LastWriteTime -End (Get-Date)).TotalDays, 0)
            }
        } |
        Format-table -Wrap -autosize -Force