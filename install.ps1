#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$SkillsDirectory = (Join-Path $env:USERPROFILE '.agents\skills'),
    [switch]$SkipEnvironmentCheck
)

$ErrorActionPreference = 'Stop'
$skillName = 'sketchup-from-cad-landscape'
$source = $PSScriptRoot
# These two documents are referenced by SKILL.md and are runtime resources.
$manifest = @('SKILL.md', 'docs\TESTED_ENVIRONMENT.md', 'docs\LIMITATIONS.md')

function Assert-NoLink([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Linked paths are not supported by this installer: $cursor"
            }
        }
        $parent = Split-Path -Path $cursor -Parent
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
}

try {
    if (-not $SkipEnvironmentCheck -and -not (Test-Path -LiteralPath (Join-Path $source 'check-environment.ps1') -PathType Leaf)) {
        throw 'Missing check-environment.ps1. Extract the complete ZIP first.'
    }
    foreach ($relative in $manifest) {
        if (-not (Test-Path -LiteralPath (Join-Path $source $relative) -PathType Leaf)) {
            throw "Missing package file: $relative. Extract the complete ZIP first."
        }
    }
    $root = [IO.Path]::GetFullPath($SkillsDirectory)
    $target = Join-Path $root $skillName
    Assert-NoLink $target
    $sourceFull = [IO.Path]::GetFullPath($source).TrimEnd('\')
    if ($sourceFull -eq $target.TrimEnd('\') -or $sourceFull.StartsWith($target.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Run the installer from the extracted package, not from the installed Skill.'
    }
    $same = $false
    if (Test-Path -LiteralPath $target) {
        if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw 'The target is not a directory.' }
        $existing = @(Get-ChildItem -LiteralPath $target -Recurse -Force -File)
        $same = ($existing.Count -eq $manifest.Count)
        foreach ($relative in $manifest) {
            $destination = Join-Path $target $relative
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { $same = $false; continue }
            if ((Get-FileHash -LiteralPath $destination).Hash -ne (Get-FileHash -LiteralPath (Join-Path $source $relative)).Hash) { $same = $false }
        }
        if (@(Get-ChildItem -LiteralPath $target -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
            throw 'The existing Skill contains linked files. Review it manually before updating.'
        }
    }
    if ($same) {
        Write-Host "SKILL INSTALLED: already installed (identical files): $target"
    } else {
        # Stage outside the discovery directory. Backups must not appear as duplicate Skills.
        $backupRoot = Join-Path (Split-Path $root -Parent) 'skill-install-backups'
        Assert-NoLink $backupRoot
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        $unique = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
        $stage = Join-Path $backupRoot ($skillName + '-staging-' + $unique)
        New-Item -ItemType Directory -Path (Join-Path $stage 'docs') -Force | Out-Null
        foreach ($relative in $manifest) {
            Copy-Item -LiteralPath (Join-Path $source $relative) -Destination (Join-Path $stage $relative)
            if ((Get-FileHash -LiteralPath (Join-Path $stage $relative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $source $relative)).Hash) { throw 'Staged copy verification failed.' }
        }
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $backup = $null
        if (Test-Path -LiteralPath $target) {
            $backup = Join-Path $backupRoot ($skillName + '-' + $unique)
            Move-Item -LiteralPath $target -Destination $backup
            Write-Host "Existing Skill preserved at: $backup"
        }
        try {
            Move-Item -LiteralPath $stage -Destination $target
            if (-not (Test-Path -LiteralPath (Join-Path $target 'SKILL.md') -PathType Leaf)) { throw 'Installed SKILL.md is missing.' }
        } catch {
            # Never delete user files, even after a partial failure.
            if (Test-Path -LiteralPath $target) {
                Move-Item -LiteralPath $target -Destination (Join-Path $backupRoot ($skillName + '-failed-' + $unique))
            }
            if ($backup -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $target }
            throw
        }
        Write-Host "SKILL INSTALLED: $target"
    }
    Write-Host 'This does not mean FULL AUTOMATION READY. No third-party applications were installed.'
    Write-Host 'Refresh/restart Codex if the Skill does not appear.'
    if (-not $SkipEnvironmentCheck) {
        & (Join-Path $source 'check-environment.ps1') -SkillsDirectory $root
    }
} catch {
    Write-Error "Skill installation failed: $($_.Exception.Message)"
    exit 1
}
