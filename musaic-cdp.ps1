param(
    [Parameter(Position = 0)]
    [ValidateSet("check", "install", "help")]
    [string]$Command = "check",

    [string]$CdpRoot,
    [string]$ZipPath,
    [string]$ZipUrl,
    [switch]$UpdateConfig,
    [switch]$KeepZip
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$rootDir = $PSScriptRoot
$configHelper = Join-Path $rootDir "musaic-config.ps1"
$cfg = $null
if (Test-Path $configHelper) {
    . $configHelper
    $cfg = Get-MusaicConfig
}

function Write-Usage {
    Write-Host "MUSaiC CDP helper"
    Write-Host "Usage:"
    Write-Host "  ./musaic-cdp.ps1 check [-CdpRoot <path>]"
    Write-Host "  ./musaic-cdp.ps1 install -ZipPath <path> [-CdpRoot <path>] [-UpdateConfig]"
    Write-Host "  ./musaic-cdp.ps1 install -ZipUrl <url> [-CdpRoot <path>] [-UpdateConfig]"
    Write-Host ""
}

function Resolve-CdpRootPath {
    param([string]$PathOverride)
    if ($PathOverride) {
        if ([System.IO.Path]::IsPathRooted($PathOverride)) {
            return [System.IO.Path]::GetFullPath($PathOverride)
        }
        return [System.IO.Path]::GetFullPath((Join-Path $rootDir $PathOverride))
    }
    if ($cfg) { return $cfg.cdpRoot }
    return [System.IO.Path]::GetFullPath((Join-Path $rootDir "CDPR8"))
}

function Get-CdpBinPath {
    param([string]$RootPath)
    $cdpInternal = Join-Path $RootPath "_cdp"
    return (Join-Path $cdpInternal "_cdprogs")
}

function Check-Cdp {
    param([string]$RootPath)
    $ok = $true
    $binPath = Get-CdpBinPath -RootPath $RootPath

    if (-not (Test-Path $RootPath)) {
        Write-Host "[FAIL] CDP root not found: $RootPath" -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path $binPath)) {
        Write-Host "[FAIL] CDP bin not found: $binPath" -ForegroundColor Red
        return $false
    }

    $exeList = @("synth.exe", "reverb.exe", "modify.exe", "sndinfo.exe", "pitch.exe")
    foreach ($exe in $exeList) {
        $path = Join-Path $binPath $exe
        if (-not (Test-Path $path)) {
            Write-Host "[FAIL] Missing: $path" -ForegroundColor Red
            $ok = $false
        }
    }

    if ($ok) {
        Write-Host "[PASS] CDP install looks OK at $RootPath" -ForegroundColor Green
    }
    return $ok
}

function Update-MusaicConfig {
    param([string]$RootPath)
    $configFile = Join-Path $rootDir "musaic.config.json"
    $templateFile = Join-Path $rootDir "musaic.config.template.json"
    $conf = @{}

    if (Test-Path $templateFile) {
        try {
            $tpl = Get-Content -Raw $templateFile | ConvertFrom-Json
            foreach ($p in $tpl.PSObject.Properties) {
                $conf[$p.Name] = $p.Value
            }
        }
        catch {
            Write-Warning "Failed to load template config: $_"
        }
    }

    if (Test-Path $configFile) {
        try {
            $local = Get-Content -Raw $configFile | ConvertFrom-Json
            foreach ($p in $local.PSObject.Properties) {
                $conf[$p.Name] = $p.Value
            }
        }
        catch {
            Write-Warning "Failed to load existing config: $_"
        }
    }

    $rootFull = [System.IO.Path]::GetFullPath($rootDir)
    $cdpFull = [System.IO.Path]::GetFullPath($RootPath)
    if ($cdpFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $cdpFull.Substring($rootFull.Length).TrimStart('\', '/')
        $conf["cdpRoot"] = if ($rel) { ".\$rel" } else { "." }
    }
    else {
        $conf["cdpRoot"] = $RootPath
    }

    $json = $conf | ConvertTo-Json -Depth 2
    Set-Content -Path $configFile -Value $json -Encoding ASCII
    Write-Host "Updated config: $configFile" -ForegroundColor Green
}

function Install-Cdp {
    param([string]$RootPath, [string]$ZipPathParam, [string]$ZipUrlParam)

    if (-not $ZipPathParam -and -not $ZipUrlParam) {
        throw "Provide -ZipPath or -ZipUrl."
    }

    if (Test-Path $RootPath) {
        $items = Get-ChildItem -Path $RootPath -Force -ErrorAction SilentlyContinue
        if ($items.Count -gt 0) {
            throw "Target path not empty: $RootPath. Choose an empty folder."
        }
    }
    else {
        New-Item -ItemType Directory -Force -Path $RootPath | Out-Null
    }

    $zipPath = $ZipPathParam
    if ($ZipUrlParam) {
        if (-not $zipPath) {
            $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) "musaic_cdp.zip"
        }
        Write-Host "Downloading CDP zip..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ZipUrlParam -OutFile $zipPath
    }

    if (-not (Test-Path $zipPath)) {
        throw "Zip not found: $zipPath"
    }

    $extractDir = Join-Path ([System.IO.Path]::GetTempPath()) ("musaic_cdp_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $extractDir | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    $sourceRoot = $null
    $cdpr8Candidate = Join-Path $extractDir "CDPR8"
    if (Test-Path $cdpr8Candidate) {
        $sourceRoot = $cdpr8Candidate
    }
    else {
        $dirs = Get-ChildItem -Path $extractDir -Directory -Force
        if ($dirs.Count -eq 1) {
            $sourceRoot = $dirs[0].FullName
        }
        else {
            $sourceRoot = $extractDir
        }
    }

    Write-Host "Installing CDP to $RootPath..." -ForegroundColor Cyan
    Get-ChildItem -Path $sourceRoot -Force | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $RootPath -Recurse -Force
    }

    Remove-Item -Recurse -Force $extractDir
    if ($ZipUrlParam -and -not $KeepZip) {
        Remove-Item -Force $zipPath -ErrorAction SilentlyContinue
    }
}

if ($Command -eq "help") {
    Write-Usage
    exit 0
}

$targetRoot = Resolve-CdpRootPath -PathOverride $CdpRoot

if ($Command -eq "check") {
    Check-Cdp -RootPath $targetRoot | Out-Null
    exit 0
}

if ($Command -eq "install") {
    Install-Cdp -RootPath $targetRoot -ZipPathParam $ZipPath -ZipUrlParam $ZipUrl
    if ($UpdateConfig) {
        Update-MusaicConfig -RootPath $targetRoot
    }
    Check-Cdp -RootPath $targetRoot | Out-Null
    exit 0
}

Write-Usage
