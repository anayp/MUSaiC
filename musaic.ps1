param(
    [Parameter(Position = 0)]
    [ValidateSet("setup", "doctor")]
    [string]$Command = "doctor",

    [string]$CdpRoot,
    [string]$OutputDir,
    [string]$FfmpegPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Source Helper
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) {
    throw "Critical validation failed: musaic-config.ps1 not found."
}
. $configHelper

function Invoke-Setup {
    Write-Host "Running MUSaiC Setup..." -ForegroundColor Cyan

    $templateFile = Join-Path $PSScriptRoot "musaic.config.template.json"
    $targetFile = Join-Path $PSScriptRoot "musaic.config.json"

    # Load defaults
    $conf = @{
        "cdpRoot"    = "./CDPR8"
        "outputDir"  = "./output"
        "ffmpegPath" = "ffmpeg"
    }

    if (Test-Path $templateFile) {
        $tpl = Get-Content -Raw $templateFile | ConvertFrom-Json
        foreach ($p in $tpl.PSObject.Properties) {
            $conf[$p.Name] = $p.Value
        }
    }

    # Override with CLI args
    if ($CdpRoot) { $conf["cdpRoot"] = $CdpRoot }
    if ($OutputDir) { $conf["outputDir"] = $OutputDir }
    if ($FfmpegPath) { $conf["ffmpegPath"] = $FfmpegPath }

    # Write Config
    $json = $conf | ConvertTo-Json -Depth 2
    Set-Content -Path $targetFile -Value $json
    Write-Host "Configuration saved to: $targetFile" -ForegroundColor Green
    Write-Host "Content:"
    Write-Host $json -ForegroundColor Gray
    
    # Create Output Dir if missing
    Invoke-Doctor
}

function Invoke-Doctor {
    Write-Host "`nRunning MUSaiC Doctor..." -ForegroundColor Cyan
    
    # Load Config
    try {
        $cfg = Get-MusaicConfig
    }
    catch {
        Write-Error "Failed to load configuration: $_"
        return
    }

    $allPass = $true

    function Test-Item {
        param($Name, $Condition, $Msg, $Fatal = $true)
        if ($Condition) {
            Write-Host " [PASS] $Name" -ForegroundColor Green
        }
        else {
            Write-Host " [FAIL] $Name - $Msg" -ForegroundColor Red
            if ($Fatal) { $script:allPass = $false }
        }
    }

    # 1. Check CDP Root
    Test-Item "CDP Root" (Test-Path $cfg.cdpRoot) "Directory not found at $($cfg.cdpRoot)"

    # 2. Check CDP Bin
    Test-Item "CDP Binaries Dir" (Test-Path $cfg.cdpBin) "Directory not found at $($cfg.cdpBin)"

    # 3. Check Executables
    $exeList = @("synth.exe", "reverb.exe", "modify.exe", "sndinfo.exe", "pitch.exe")
    foreach ($exe in $exeList) {
        $path = Join-Path $cfg.cdpBin $exe
        Test-Item "Bin: $exe" (Test-Path $path) "Executable not found at $path"
    }

    # 4. Check FFmpeg
    if ($cfg.ffmpegPath -eq "ffmpeg") {
        # Check PATH
        $ff = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
        Test-Item "FFmpeg (PATH)" ($ff) "ffmpeg not found in PATH."
    }
    else {
        Test-Item "FFmpeg (Explicit)" (Test-Path $cfg.ffmpegPath) "ffmpeg not found at $($cfg.ffmpegPath)"
    }

    # 5. Check Output Dir
    if (-not (Test-Path $cfg.outputDir)) {
        # Try to create it
        try {
            New-Item -ItemType Directory -Force -Path $cfg.outputDir | Out-Null
        }
        catch { }
    }
    # Check writable by trying to write a tmp file
    $testFile = Join-Path $cfg.outputDir "write_test.tmp"
    $writable = $false
    try {
        Set-Content -Path $testFile -Value "ok" -ErrorAction SilentlyContinue
        if (Test-Path $testFile) {
            $writable = $true
            Remove-Item $testFile -Force
        }
    }
    catch {}
    
    Test-Item "Output Directory" ((Test-Path $cfg.outputDir) -and $writable) "Output dir not writable or missing at $($cfg.outputDir)"

    Write-Host "---------------------------------------------------"
    if ($allPass) {
        Write-Host "SYSTEM READY. All checks passed." -ForegroundColor Green
    }
    else {
        Write-Host "SYSTEM ISSUES DETECTED. Please fix failures above." -ForegroundColor Red
        Write-Host "Try running: ./musaic.ps1 setup -CdpRoot <path_to_CDPR8>"
    }
}

if ($Command -eq "setup") {
    Invoke-Setup
}
elseif ($Command -eq "doctor") {
    Invoke-Doctor
}
