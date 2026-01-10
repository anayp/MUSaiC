
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

    # Resolve Paths
    # 1. cdpRoot
    $rawCdpRoot = $config["cdpRoot"]
    if (-not [System.IO.Path]::IsPathRooted($rawCdpRoot)) {
        $cdpRoot = Join-Path $rootDir $rawCdpRoot
    }
    else {
        $cdpRoot = $rawCdpRoot
    }
    $cdpRoot = [System.IO.Path]::GetFullPath($cdpRoot)

    # 2. cdpBin identification
    # Standard CDP layout: cdpRoot/_cdp/_cdprogs
    $cdpInternal = Join-Path $cdpRoot "_cdp"
    $cdpBin = Join-Path $cdpInternal "_cdprogs"
    # Fallback/Check: If user pointed directly to bin?
    # Usually better to stick to standard structure unless explicit override needed.
    # For now, assume standard structure inside cdpRoot.

    # 3. outputDir
    $rawOut = $config["outputDir"]
    if (-not [System.IO.Path]::IsPathRooted($rawOut)) {
        $outputDir = Join-Path $rootDir $rawOut
    }
    else {
        $outputDir = $rawOut
    }
    $outputDir = [System.IO.Path]::GetFullPath($outputDir)

    # Ensure output directory exists (lazy creation safe here? or just return path?)
    # Helper usually just resolves. But script implies "Resolve outputDir and create if missing when needed."
    # We'll just return the path, let consumer create if they write. 
    # BUT the instructions say: "Resolve outputDir and create if missing when needed." inside helper? 
    # "Resolve outputDir and create if missing when needed." -> implies we might want to do it here or provide a function.
    # Let's just create it to be safe and easy.
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }

    # 4. ffmpegPath
    $ffmpegPath = $config["ffmpegPath"]
    # If it's just "ffmpeg", leave it for PATH lookup. 
    # If it's a relative path, resolve it.
    if ($ffmpegPath -ne "ffmpeg" -and -not [System.IO.Path]::IsPathRooted($ffmpegPath)) {
        $ffmpegPath = Join-Path $rootDir $ffmpegPath
        $ffmpegPath = [System.IO.Path]::GetFullPath($ffmpegPath)
    }

    # Return Object
    return [PSCustomObject]@{
        cdpRoot    = $cdpRoot
        cdpBin     = $cdpBin
        outputDir  = $outputDir
        ffmpegPath = $ffmpegPath
    }
}

# Export function if dot-sourced
# Function is available when dot-sourced.
