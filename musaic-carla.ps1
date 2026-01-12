param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("validate", "render", "help")]
    [string]$Command
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
        Write-Host "TODO: Implement Carla offline render workflow." -ForegroundColor Cyan
        Write-Host "This will involve generating a .carla patch and invoking headless mode."
        exit 1
    }
    "help" {
        Write-Host "Usage: ./musaic-carla.ps1 -Command <validate|render|help>"
    }
}
