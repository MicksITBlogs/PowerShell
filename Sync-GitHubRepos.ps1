<#
.SYNOPSIS
    Clones any GitHub repositories that do not exist in the local clone directory.

.DESCRIPTION
    Queries the GitHub API for all public repositories under a given username,
    compares repo names against local folder names, and clones any that are missing.
    Optionally includes private repositories when a Personal Access Token is supplied.

.PARAMETER GitHubUsername
    The GitHub username to query. Defaults to 'mickpletcher'.

.PARAMETER LocalPath
    The local directory where repos are cloned. Defaults to the standard code root.

.PARAMETER Token
    Optional GitHub Personal Access Token. Required to include private repositories
    or to avoid API rate limiting.

.PARAMETER WhatIf
    Lists repos that would be cloned without actually cloning them.

.EXAMPLE
    .\Sync-GitHubRepos.ps1

.EXAMPLE
    .\Sync-GitHubRepos.ps1 -Token 'ghp_xxxxxxxxxxxx'

.EXAMPLE
    .\Sync-GitHubRepos.ps1 -WhatIf

========================================================
Author  : Mick Pletcher
Date    : 2025-04-29
========================================================
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [string]$GitHubUsername = 'mickpletcher',
    [string]$LocalPath      = 'C:\Users\mick0\OneDrive\Documents\Code & Dev\GitHub',
    [string]$Token
)

#region Functions

function Write-Log {
    [CmdletBinding()]
    param (
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Severity = 'Info'
    )

    $CMTraceTime = Get-Date -Format 'HH:mm:ss.fff'
    $CMTraceDate = Get-Date -Format 'MM-dd-yyyy'
    $Timestamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $Component   = 'Sync-GitHubRepos'
    $SeverityMap = @{ Info = 1; Warning = 2; Error = 3 }

    $CMEntry = "<![LOG[$Message]LOG]!><time=`"$CMTraceTime+000`" date=`"$CMTraceDate`" component=`"$Component`" context=`"`" type=`"$($SeverityMap[$Severity])`" thread=`"$PID`" file=`"`">"
    Add-Content -Path "$env:TEMP\Sync-GitHubRepos.log" -Value $CMEntry -Encoding UTF8

    switch ($Severity) {
        'Warning' { Write-Warning "$Timestamp  $Message" }
        'Error'   { Write-Error   "$Timestamp  $Message" }
        default   { Write-Host    "$Timestamp  $Message" }
    }
}

function Get-GitHubRepos {
    [CmdletBinding()]
    param (
        [string]$Username,
        [string]$Token
    )

    $Headers = @{ 'User-Agent' = 'PowerShell-RepoSync' }

    if ($Token) {
        $Headers['Authorization'] = "token $Token"
    }

    $AllRepos = [System.Collections.Generic.List[object]]::new()
    $Page     = 1

    do {
        $Uri = "https://api.github.com/users/$Username/repos?per_page=100&page=$Page"

        try {
            $Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -ErrorAction Stop
            $AllRepos.AddRange($Response)
            $Page++
        } catch {
            Write-Log -Message "GitHub API error on page $Page : $_" -Severity Error
            return $null
        }

    } while ($Response.Count -eq 100)

    return $AllRepos
}

function Get-LocalRepoNames {
    [CmdletBinding()]
    param ([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message "Local path not found: $Path" -Severity Error
        return $null
    }

    try {
        return (Get-ChildItem -Path $Path -Directory -ErrorAction Stop).Name
    } catch {
        Write-Log -Message "Failed to enumerate local path: $_" -Severity Error
        return $null
    }
}

function Invoke-GitClone {
    [CmdletBinding()]
    param (
        [string]$CloneUrl,
        [string]$RepoName,
        [string]$DestinationPath
    )

    $TargetDir = Join-Path -Path $DestinationPath -ChildPath $RepoName

    Write-Log -Message "Cloning $RepoName ..."

    try {
        $Output = git clone $CloneUrl $TargetDir 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "git clone failed for $RepoName : $Output" -Severity Error
            return $false
        }

        Write-Log -Message "Cloned $RepoName successfully."
        return $true
    } catch {
        Write-Log -Message "Exception cloning $RepoName : $_" -Severity Error
        return $false
    }
}

#endregion Functions

#region Main

Write-Log -Message "===== Sync-GitHubRepos started ====="
Write-Log -Message "Username   : $GitHubUsername"
Write-Log -Message "Local path : $LocalPath"

# Verify git is available
try {
    $null = git --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Log -Message "git.exe not found in PATH. Install Git for Windows and retry." -Severity Error
    exit 1
}

# Fetch GitHub repos
Write-Log -Message "Querying GitHub API..."

$GitHubRepos = Get-GitHubRepos -Username $GitHubUsername -Token $Token

if (-not $GitHubRepos) {
    Write-Log -Message "No repos returned from GitHub. Exiting." -Severity Error
    exit 1
}

Write-Log -Message "GitHub repos found: $($GitHubRepos.Count)"

# Get local folder names
$LocalRepos = Get-LocalRepoNames -Path $LocalPath

if ($null -eq $LocalRepos) {
    Write-Log -Message "Could not read local path. Exiting." -Severity Error
    exit 1
}

Write-Log -Message "Local folders found: $($LocalRepos.Count)"

# Find missing repos (case-insensitive comparison)
$MissingRepos = $GitHubRepos | Where-Object {
    $_.name -notin $LocalRepos
}

if ($MissingRepos.Count -eq 0) {
    Write-Log -Message "All GitHub repos are already cloned locally. Nothing to do."
    exit 0
}

Write-Log -Message "Repos to clone: $($MissingRepos.Count)" -Severity Warning

# Clone each missing repo
$Cloned  = 0
$Failed  = 0

foreach ($Repo in $MissingRepos) {
    if ($PSCmdlet.ShouldProcess($Repo.name, 'git clone')) {
        $Success = Invoke-GitClone -CloneUrl $Repo.clone_url -RepoName $Repo.name -DestinationPath $LocalPath

        if ($Success) {
            $Cloned++
        } else {
            $Failed++
        }
    } else {
        Write-Host "  [WhatIf] Would clone: $($Repo.name)  ($($Repo.clone_url))" -ForegroundColor Cyan
    }
}

# Summary
Write-Host "`n===== SUMMARY =====" -ForegroundColor Yellow
Write-Host "GitHub repos    : $($GitHubRepos.Count)"
Write-Host "Local folders   : $($LocalRepos.Count)"
Write-Host "Cloned          : $Cloned" -ForegroundColor Green

if ($Failed -gt 0) {
    Write-Host "Failed          : $Failed" -ForegroundColor Red
}

Write-Log -Message "===== Sync-GitHubRepos complete — Cloned: $Cloned  Failed: $Failed ====="
exit 0

#endregion Main