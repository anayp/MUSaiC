
function Get-MusaicConfig {
    [CmdletBinding()]
    param()

    # Define paths
    $rootDir = $PSScriptRoot
    $configFile = Join-Path $rootDir "musaic.config.json"
    $templateFile = Join-Path $rootDir "musaic.config.template.json"

    # Default configuration
    $config = @{
        "cdpRoot"    = "./CDPR8"
        "outputDir"  = "./output"
        "ffmpegPath" = "ffmpeg"
    }

    # Load from template if available (as base)
    if (Test-Path $templateFile) {
        try {
            $tpl = Get-Content -Raw $templateFile | ConvertFrom-Json
            foreach ($key in $tpl.PSObject.Properties.Name) {
                $config[$key] = $tpl.$key
            }
        }
        catch {
            Write-Warning "Failed to load template config: $_"
        }
    }

    # Load from local config if available (overrides defaults/template)
    if (Test-Path $configFile) {
        try {
            $local = Get-Content -Raw $configFile | ConvertFrom-Json
            foreach ($key in $local.PSObject.Properties.Name) {
                $config[$key] = $local.$key
            }
        }
        catch {
            Write-Warning "Failed to load local config: $_"
        }
    }

    # Environment Variable Override: MUSAIC_CDP_ROOT
    if ($env:MUSAIC_CDP_ROOT) {
        $config["cdpRoot"] = $env:MUSAIC_CDP_ROOT
    }

    # Helper to resolve absolute path
    function Resolve-AbsPath {
        param($p, $root, $isBin = $false)
        if (-not $p) { return $p }
        if ($isBin -and (-not ($p -match "[\\/]"))) { return $p } # checking if it looks like a command name
        
        if (-not [System.IO.Path]::IsPathRooted($p)) {
            $p = Join-Path $root $p
        }
        return [System.IO.Path]::GetFullPath($p)
    }

    # Resolve Paths
    $cdpRoot = Resolve-AbsPath $config["cdpRoot"] $rootDir
    
    # Standard CDP layout: cdpRoot/_cdp/_cdprogs
    $cdpInternal = Join-Path $cdpRoot "_cdp"
    $cdpBin = Join-Path $cdpInternal "_cdprogs"

    $outputDir = Resolve-AbsPath $config["outputDir"] $rootDir
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }

    $ffmpegPath = Resolve-AbsPath $config["ffmpegPath"] $rootDir $true

    # New Tools

    $fluidsynthPath = Resolve-AbsPath ($config["fluidsynthPath"]) $rootDir $true
    $soundfontDir = Resolve-AbsPath ($config["soundfontDir"]) $rootDir

    $pluginIndexPath = Resolve-AbsPath ($config["pluginIndexPath"]) $rootDir    
    
    $pluginPaths = @()
    if ($config["pluginPaths"] -is [array]) {
        foreach ($pp in $config["pluginPaths"]) {
            $pluginPaths += (Resolve-AbsPath $pp $rootDir)
        }
    }

    # Return Object
    return [PSCustomObject]@{
        cdpRoot            = $cdpRoot
        cdpBin             = $cdpBin
        outputDir          = $outputDir
        ffmpegPath         = $ffmpegPath

        fluidsynthPath     = $fluidsynthPath
        soundfontDir       = $soundfontDir
        pluginIndexPath    = $pluginIndexPath
        pluginPaths        = $pluginPaths
        carlaPath          = Resolve-AbsPath ($config["carlaPath"]) $rootDir $true
        dbConnectionString = $config["dbConnectionString"]
        segmenterPath      = Resolve-AbsPath ($config["segmenterPath"]) $rootDir $true
        stemSeparatorPath  = Resolve-AbsPath ($config["stemSeparatorPath"]) $rootDir $true
    }
}

# Export function if dot-sourced
# Function is available when dot-sourced.
