param(
    [string]$ConfigPath = ".\\examples\\simple-tone.json"
)

# Generate a tone with CDP's synth.exe using JSON config.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Configuration ---
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig
$cdpBin = $cfg.cdpBin
$synthExe = Join-Path $cdpBin "synth.exe"

if ($null -eq $synthExe -or -not (Test-Path $synthExe)) {
    throw "Missing CDP synth executable at $synthExe. Check that CDPR8 is extracted beside this script."
}

if (-not (Test-Path $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}
Write-Host "Using config file: $ConfigPath"

$configJson = Get-Content -Raw -Path $ConfigPath
$config = ConvertFrom-Json -InputObject $configJson
if ($config -is [System.Array]) {
    if ($config.Count -eq 1) {
        $config = $config[0]
    }
    else {
        throw "Config JSON must contain a single object, not $($config.Count) items."
    }
}
if ($null -eq $config) {
    throw "Failed to parse JSON config at $ConfigPath"
}

$configKeys = $config.PSObject.Properties.Name
if ($configKeys) {
    Write-Host "Loaded config keys: $($configKeys -join ', ')"
}
else {
    Write-Host "Loaded config has no keys; falling back to defaults."
}

function Get-ConfigValue {
    param(
        [object]$Obj,
        [string]$Name
    )

    if ($null -eq $Obj) {
        return $null
    }

    $prop = $Obj.PSObject.Properties | Where-Object { $_.Name -ieq $Name } | Select-Object -First 1
    if ($prop) {
        return $prop.Value
    }

    if ($Obj -is [System.Collections.IDictionary]) {
        $key = $Obj.Keys | Where-Object { $_ -eq $Name -or ($_.ToString().ToLowerInvariant() -eq $Name.ToLowerInvariant()) } | Select-Object -First 1
        if ($key) {
            return $Obj[$key]
        }
    }

    return $null
}

$modeMap = @{
    sine   = 1
    square = 2
    saw    = 3
    ramp   = 4
}

$waveform = Get-ConfigValue -Obj $config -Name "waveform"
if ([string]::IsNullOrWhiteSpace($waveform)) {
    $waveform = "sine"
}
$waveform = $waveform.ToLowerInvariant()
if (-not $modeMap.ContainsKey($waveform)) {
    throw "Unsupported waveform '$waveform'. Use one of: $($modeMap.Keys -join ', ')"
}

$sampleRate = Get-ConfigValue -Obj $config -Name "sampleRate"
if (-not $sampleRate) { $sampleRate = 48000 } else { $sampleRate = [int]$sampleRate }
$channels = Get-ConfigValue -Obj $config -Name "channels"
if (-not $channels) { $channels = 2 } else { $channels = [int]$channels }
$duration = Get-ConfigValue -Obj $config -Name "durationSeconds"
if (-not $duration) { $duration = 3 } else { $duration = [double]$duration }
$frequency = Get-ConfigValue -Obj $config -Name "frequencyHz"
if (-not $frequency) { $frequency = 440 } else { $frequency = [double]$frequency }
$amplitude = Get-ConfigValue -Obj $config -Name "amplitude"
if ($amplitude -eq $null -or $amplitude -eq "") { $amplitude = 1 } else { $amplitude = [double]$amplitude }

$output = Get-ConfigValue -Obj $config -Name "output"
if ([string]::IsNullOrWhiteSpace($output)) {
    $output = Join-Path $cfg.outputDir "cdp-$waveform.wav"
}
elseif (-not [System.IO.Path]::IsPathRooted($output)) {
    # If explicitly relative (./...), resolve from root. 
    # If just filename, maybe put in output? The instructions say: "If user provides a relative output path, resolve it relative to repo root."
    # Wait, instructions: "If user provides an explicit absolute output path, respect it. If user provides a relative output path, resolve it relative to repo root. If script auto-generates a path, place it under cfg.outputDir."
    
    # So if $output is set in JSON ("output": "foo.wav"), is that explicit relative? Yes.
    $output = Join-Path $PSScriptRoot $output
}

$output = [System.IO.Path]::GetFullPath($output)
$outDir = Split-Path $output
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
if (Test-Path $output) {
    Remove-Item -Force -Path $output
}

$args = @(
    "wave",
    $modeMap[$waveform],
    $output,
    $sampleRate,
    $channels,
    $duration,
    $frequency,
    "-a$amplitude"
)

Write-Host "Running CDP synth:"
Write-Host ("Config -> waveform:{0} sr:{1} ch:{2} dur:{3} freq:{4} amp:{5}" -f $waveform, $sampleRate, $channels, $duration, $frequency, $amplitude)
Write-Host "`"$synthExe`" $($procArgs -join ' ')"

& $synthExe @procArgs
if ($LASTEXITCODE -ne 0) {
    throw "CDP synth failed with exit code $LASTEXITCODE"
}

Write-Host "Wrote tone to $output"
