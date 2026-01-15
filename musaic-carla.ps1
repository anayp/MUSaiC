param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("validate", "render", "help")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false)]
    [string]$InWav,

    [Parameter(Mandatory = $false)]
    [string]$OutWav,

    [Parameter(Mandatory = $false)]
    [string]$PluginPath,

    [Parameter(Mandatory = $false)]
    [string]$Preset
)

. "$PSScriptRoot\musaic-config.ps1"

function Resolve-CarlaPath {
    $config = Get-MusaicConfig
    if ($config -and $config.carlaPath) {
        return $config.carlaPath
    }
    $candidates = @("carla-single", "carla-rack", "Carla.exe")
    foreach ($cmd in $candidates) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($found) { return $cmd }
    }
    return $null
}

function Get-CarlaVersion {
    $carlaPath = Resolve-CarlaPath
    if (-not $carlaPath) {
        Write-Host "Carla binary not found in PATH or config." -ForegroundColor Red
        return $false
    }
    try {
        $version = & $carlaPath --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Carla found: $version" -ForegroundColor Green
            return $true
        }
        Write-Host "Carla found but returned error code." -ForegroundColor Yellow
        return $false
    }
    catch {
        Write-Host "Carla invocation failed." -ForegroundColor Red
        return $false
    }
}

switch ($Command) {
    "validate" {
        Write-Host "Validating Carla environment..."
        $exists = Get-CarlaVersion
        if (-not $exists) {
            Write-Error "Carla validation failed. Configure carlaPath or add Carla to PATH."
            exit 1
        }
    }
    "render" {
        $carlaPath = Resolve-CarlaPath
        if (-not $carlaPath) {
            Write-Error "Carla binary not found. Cannot render."
            exit 1
        }

        if (-not $OutWav) {
            Write-Error "-OutWav is required for render output."
            exit 1
        }

        $config = Get-MusaicConfig
        $outputDir = $config.outputDir

        if (-not $ProjectPath) {
            if (-not $PluginPath) {
                Write-Error "-PluginPath is required if -ProjectPath is missing."
                exit 1
            }

            Write-Host "Generating minimal .carla patch..." -ForegroundColor Cyan
            $patchName = [System.IO.Path]::GetFileNameWithoutExtension($PluginPath)
            $ProjectPath = Join-Path $outputDir "$patchName.carla"
            
            # Note: This is a placeholder for actual .carla XML generation.
            # In a real scenario, we'd use a template or [xml] logic.
            $xml = @"
<?xml version='1.0' encoding='UTF-8'?>
<carla-project version='2'>
 <EngineSettings>
  <SampleRate>44100</SampleRate>
 </EngineSettings>
 <Plugin>
  <Info>
   <Type>VST3</Type>
   <Name>$patchName</Name>
   <Binary>$PluginPath</Binary>
  </Info>
  <Data>
   <Preset>$Preset</Preset>
  </Data>
 </Plugin>
</carla-project>
"@
            $xml | Out-File $ProjectPath -Encoding utf8
            Write-Host "Created patch: $ProjectPath"
        }

        Write-Host "Invoking Carla render workflow..." -ForegroundColor Cyan
        # Carla CLI headless render usually involves --export-to-audio-file or --render.
        # We check help output to decide the best flag.
        $help = & $carlaPath --help 2>&1
        $renderFlag = $null
        if ($help -match "--export-to-audio-file") { $renderFlag = "--export-to-audio-file" }
        elseif ($help -match "--render") { $renderFlag = "--render" }

        if (-not $renderFlag) {
            Write-Error "Carla headless render flags not found in --help output."
            exit 1
        }

        # Command construction
        $args = @($ProjectPath, $renderFlag, $OutWav)
        if ($InWav) {
            # Some Carla versions take input via specific flags or as first arg
            # This is highly version dependent.
        }

        Write-Host "Executing: $carlaPath $($args -join ' ')"
        & $carlaPath $args

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Carla render failed with exit code $LASTEXITCODE."
            exit $LASTEXITCODE
        }

        Write-Host "Render completed: $OutWav" -ForegroundColor Green
    }
    "help" {
        Write-Host "Usage: ./musaic-carla.ps1 -Command <validate|render|help> [-ProjectPath <path>] [-InWav <path>] [-OutWav <path>] [-PluginPath <path>] [-Preset <name>]"
    }
}
