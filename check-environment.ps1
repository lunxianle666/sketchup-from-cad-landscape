#Requires -Version 5.1
[CmdletBinding()]
param([string]$SkillsDirectory = (Join-Path $env:USERPROFILE '.agents\skills'))

# Read-only discovery: no COM creation, application launches, downloads or configuration writes.
$ErrorActionPreference = 'Continue'
$rows = New-Object 'System.Collections.Generic.List[object]'
function Result([string]$Status, [string]$Name, [string]$Detail, [string]$Action = '') {
    $rows.Add([pscustomobject]@{ Status=$Status; Name=$Name; Detail=$Detail; Action=$Action })
    Write-Host "[$Status] ${Name}: $Detail"
}
function Registry-Value([string]$Path) {
    try { (Get-Item -LiteralPath $Path -ErrorAction Stop).GetValue('') } catch { $null }
}
function Exe-FromText([string]$Text, [string]$Name) {
    if (-not $Text) { return $null }
    $expanded = [Environment]::ExpandEnvironmentVariables($Text)
    if ($expanded -match ('(?i)"?([^";]*?' + [regex]::Escape($Name) + ')"?(?:\s|,|$)')) {
        $candidate = $matches[1].Trim('"',' ')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
function Find-Desktop([string]$Pattern, [string]$Exe, [string]$Process, [string[]]$Common) {
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    foreach ($p in @(Get-Process -Name $Process -ErrorAction SilentlyContinue)) {
        try { if ($p.Path) { $candidates.Add($p.Path) } } catch { }
    }
    foreach ($app in $script:apps | Where-Object { $_.DisplayName -match $Pattern }) {
        if ($app.InstallLocation) { $candidates.Add((Join-Path $app.InstallLocation $Exe)) }
        $icon = Exe-FromText $app.DisplayIcon $Exe
        if ($icon) { $candidates.Add($icon) }
    }
    foreach ($hive in @('HKCU:', 'HKLM:')) {
        foreach ($base in @('SOFTWARE', 'SOFTWARE\WOW6432Node')) {
            $appPath = Registry-Value "$hive\$base\Microsoft\Windows\CurrentVersion\App Paths\$Exe"
            if ($appPath) { $candidates.Add($appPath.Trim('"')) }
        }
    }
    foreach ($glob in $Common) {
        foreach ($item in @(Get-Item -Path $glob -ErrorAction SilentlyContinue)) { $candidates.Add($item.FullName) }
    }
    $paths = @($candidates | Select-Object -Unique | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    if ($paths.Count) {
        $info = (Get-Item -LiteralPath $paths[0]).VersionInfo
        return [pscustomobject]@{ Path=$paths[0]; Version=$info.ProductVersion }
    }
    return $null
}

Write-Host '=================================================='
Write-Host 'sketchup-from-cad-landscape Environment Check (v1.1)'
Write-Host '=================================================='
$apps = @()
foreach ($hive in @('HKCU:', 'HKLM:')) {
    foreach ($base in @('SOFTWARE', 'SOFTWARE\WOW6432Node')) {
        $apps += @(Get-ItemProperty -Path "$hive\$base\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue)
    }
}
$codexCommand = Get-Command codex -ErrorAction SilentlyContinue
$codexApps = @($apps | Where-Object { $_.DisplayName -match '(?i)Codex' })
$storeApps = @(Get-AppxPackage -Name '*Codex*' -ErrorAction SilentlyContinue)
$codexProcess = @(Get-Process -Name '*codex*' -ErrorAction SilentlyContinue)
if ($codexCommand -or $codexApps.Count -or $storeApps.Count -or $codexProcess.Count -or (Test-Path (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex'))) {
    Result PASS 'Codex detection' 'Possible installation found; Skills support/discovery must be confirmed in Codex.'
} else { Result UNKNOWN 'Codex detection' 'Not found by common discovery methods.' 'Install/open Codex with Skills support, then confirm discovery.' }
$root = [IO.Path]::GetFullPath($SkillsDirectory)
if (Test-Path -LiteralPath $root -PathType Container) { Result PASS 'Codex Skills directory' $root }
else { Result WARN 'Codex Skills directory' 'Selected directory does not exist.' 'If no working legacy copy exists, run install.ps1; otherwise confirm existing discovery first.' }
$installed = Test-Path -LiteralPath (Join-Path $root 'sketchup-from-cad-landscape\SKILL.md') -PathType Leaf
$legacyRoot = Join-Path $env:USERPROFILE '.codex\skills'
$legacyInstalled = Test-Path -LiteralPath (Join-Path $legacyRoot 'sketchup-from-cad-landscape\SKILL.md') -PathType Leaf
if ($installed) { Result PASS 'Skill installed' 'SKILL.md exists in the selected directory.' }
elseif ($legacyInstalled -and -not $PSBoundParameters.ContainsKey('SkillsDirectory')) {
    $installed = $true
    Result WARN 'Skill installed' 'Found in legacy .codex/skills; selected .agents/skills has no copy.' 'Confirm the active Skill in Codex. Avoid duplicate installs; legacy discovery varies by client.'
} else { Result FAIL 'Skill installed' 'No SKILL.md in the selected directory.' 'Run install.ps1 or select the correct -SkillsDirectory.' }
$acad = Find-Desktop '(?i)^AutoCAD\s|^Autodesk AutoCAD' 'acad.exe' 'acad' @("$env:ProgramFiles\Autodesk\AutoCAD*\acad.exe")
if ($acad) { Result PASS 'AutoCAD desktop' ("Detected version {0}; {1}" -f $acad.Version,$acad.Path) }
else { Result UNKNOWN 'AutoCAD desktop' 'No executable found; custom installations may be outside discovery paths.' 'Install licensed AutoCAD desktop or check its registration/install path.' }
$progIds = @()
try {
    $progIds = @([Microsoft.Win32.Registry]::ClassesRoot.GetSubKeyNames() | Where-Object { $_ -match '^AutoCAD\.Application(?:\.\d+)?$' })
} catch {
    Result UNKNOWN 'COM registry enumeration' 'Registry access was not available.' 'Check registry permissions manually; no repair is attempted.'
}
$comAvailable = @($progIds | Select-Object -Unique | Where-Object {
    try { $null -ne [Type]::GetTypeFromProgID($_, $false) } catch { $false }
})
if ($comAvailable.Count) { Result PASS 'AutoCAD COM registration' ($comAvailable -join ', ') }
else { Result FAIL 'AutoCAD COM registration' 'No resolvable AutoCAD.Application ProgID found.' 'Check desktop COM registration and matching process permissions; this check never starts AutoCAD.' }

$pythonCandidates = New-Object 'System.Collections.Generic.List[object]'
foreach ($name in @('python','python3','py')) {
    foreach ($cmd in @(Get-Command $name -CommandType Application -All -ErrorAction SilentlyContinue)) {
        if ($cmd.Source -notmatch '\\WindowsApps\\') {
            $prefix = @(); if ($name -eq 'py') { $prefix = @('-3') }
            $pythonCandidates.Add([pscustomobject]@{ Path=$cmd.Source; Prefix=$prefix })
        }
    }
}
foreach ($hive in @('HKCU:', 'HKLM:')) {
    foreach ($base in @('SOFTWARE\Python\PythonCore', 'SOFTWARE\WOW6432Node\Python\PythonCore')) {
        foreach ($version in @(Get-ChildItem -LiteralPath "$hive\$base" -ErrorAction SilentlyContinue)) {
            $install = Registry-Value ($version.PSPath + '\InstallPath')
            if ($install) { $pythonCandidates.Add([pscustomobject]@{ Path=(Join-Path $install 'python.exe'); Prefix=@() }) }
        }
    }
}
foreach ($p in @(Get-Item -Path "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe" -ErrorAction SilentlyContinue)) {
    $pythonCandidates.Add([pscustomobject]@{ Path=$p.FullName; Prefix=@() })
}
$runtime = $null
$probe = "import sys,importlib.util,json; print(json.dumps({'version':sys.version.split()[0],'exe':sys.executable,'win32':importlib.util.find_spec('win32com') is not None}))"
foreach ($candidate in $pythonCandidates) {
    if (-not (Test-Path -LiteralPath $candidate.Path -PathType Leaf)) { continue }
    try {
        $arguments = @($candidate.Prefix) + @('-B','-c',$probe)
        $output = & $candidate.Path @arguments 2>$null
        if ($LASTEXITCODE -ne 0) { continue }
        $data = ($output -join '') | ConvertFrom-Json -ErrorAction Stop
        $win32 = $false
        if ($data.win32) {
            & $data.exe -B -c 'import win32com.client' 2>$null
            $win32 = ($LASTEXITCODE -eq 0)
        }
        $found = [pscustomobject]@{ Version=$data.version; Exe=$data.exe; Win32=$win32 }
        if (-not $runtime -or $win32) { $runtime=$found }
        if ($win32) { break }
    } catch { }
}
if ($runtime) {
    Result PASS 'Python' ("{0}; {1}" -f $runtime.Version,$runtime.Exe)
    if ($runtime.Win32) { Result PASS 'pywin32' 'import win32com.client succeeded in the selected Python.' }
    else { Result FAIL 'pywin32' 'win32com.client import failed in the selected Python.' 'Install pywin32 using that interpreter: python -m pip install pywin32.' }
} else {
    Result FAIL 'Python' 'No working Python 3 found via python/py, registry or common per-user installs.' 'Install Python from python.org, or expose an existing interpreter on PATH.'
    Result UNKNOWN 'pywin32' 'Cannot test without a working Python.'
}
$su = Find-Desktop '(?i)^SketchUp\s|^SketchUp$' 'SketchUp.exe' 'SketchUp' @("$env:ProgramFiles\SketchUp\SketchUp*\SketchUp.exe", "${env:ProgramFiles(x86)}\SketchUp\SketchUp*\SketchUp.exe")
if ($su) { Result PASS 'SketchUp desktop' ("Detected version {0}; {1}" -f $su.Version,$su.Path) }
else { Result UNKNOWN 'SketchUp desktop' 'No executable found; custom installations may be outside discovery paths.' 'Install SketchUp desktop with native DWG import, or check its registration/install path.' }
$bridgeConfig = Join-Path $env:APPDATA 'RingoSketchUpMCP\config.json'
$extension = @(Get-Item -Path "$env:APPDATA\SketchUp\SketchUp*\SketchUp\Plugins\*ringo*" -ErrorAction SilentlyContinue)
if ((Test-Path -LiteralPath $bridgeConfig) -or $extension.Count) {
    $listening = $false
    try {
        if (Test-Path -LiteralPath $bridgeConfig) {
            # Read only port fields; never emit tokens, credentials or complete configuration.
            $configuration = Get-Content -LiteralPath $bridgeConfig -Raw | ConvertFrom-Json
            $ports = @($configuration.port) + @($configuration.profiles | ForEach-Object { $_.port })
            foreach ($port in $ports) {
                if ($port -match '^\d+$' -and [int]$port -ge 1 -and [int]$port -le 65535) {
                    if (@(Get-NetTCPConnection -LocalPort ([int]$port) -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalAddress -in @('127.0.0.1','::1') }).Count) { $listening=$true }
                }
            }
        }
    } catch { }
    if ($listening) { Result WARN 'SketchUp MCP' 'Ringo files and a loopback listener detected; authenticated bridge/instance/Ruby state not verified.' 'In Codex run bridge_status and model_get_info, then PRE-FLIGHT.' }
    else { Result WARN 'SketchUp MCP' 'Ringo files detected; no verified running bridge.' 'Open SketchUp, start the configured bridge, and check bridge_status in Codex.' }
} else { Result UNKNOWN 'SketchUp MCP' 'No Ringo evidence found; compatible bridges may use other locations.' 'Configure a compatible bridge; see Ringo official setup. Verify connection in Codex.' }
Result UNKNOWN 'DWG importer / Ruby / active instance' 'Not tested by this read-only checker.' 'Run Skill PRE-FLIGHT in Codex on the intended drawing/instance; software presence is not runtime proof.'
Write-Host '--------------------------------------------------'
Write-Host 'Skill Installation:'
if ($installed) { Write-Host 'READY' } else { Write-Host 'NOT_INSTALLED' }
Write-Host 'Full CAD -> SketchUp Automation:'
if (@($rows | Where-Object Status -eq 'FAIL').Count) { Write-Host 'NOT_READY' }
else { Write-Host 'UNKNOWN' }
Write-Host 'Missing / Action Required:'
foreach ($row in $rows | Where-Object { $_.Action }) { Write-Host ('- ' + $row.Action) }
Write-Host 'Full READY requires live PRE-FLIGHT, including importer, Ruby authorization and correct instance.'
Write-Host 'This script installs nothing and changes no third-party settings.'
Write-Host 'Before sharing output, remove local paths/account names. Do not send credentials or private drawings.'
Write-Host '--------------------------------------------------'
