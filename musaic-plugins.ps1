param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("scan", "list", "validate", "help")]
    [string]$Command,
    
    [string]$Format # Optional filter for 'list'
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig

function Show-Help {
    Write-Host "musaic-plugins.ps1 - Plugin Registry (Index Only)"
    Write-Host "Usage:"
    Write-Host "  ./musaic-plugins.ps1 -Command scan"
    Write-Host "  ./musaic-plugins.ps1 -Command list [-Format <VST3|VST|AU|SF2|SFZ>]"
    Write-Host "  ./musaic-plugins.ps1 -Command validate"
}

function Get-PluginFormat {
    param($Ext)
    switch ($Ext.ToLower()) {
        ".vst3" { return "VST3" }
        ".dll" { return "VST" }  # Windows VST2
        ".vst" { return "VST" }  # macOS VST2
        ".component" { return "AU" } # macOS Audio Unit
        ".sf2" { return "SF2" }
        ".sfz" { return "SFZ" }
        default { return "Unknown" }
    }
}

function Scan-Plugins {
    $plugins = @()
    $crawledPaths = @()

    # 1. Scan SoundFont Dir (SF2/SFZ)
    if ($cfg.soundfontDir -and (Test-Path $cfg.soundfontDir)) {
        Write-Host "Scanning SoundFonts in: $($cfg.soundfontDir)"
        $files = Get-ChildItem -Path $cfg.soundfontDir -Include "*.sf2", "*.sfz" -Recurse -File
        foreach ($f in $files) {
            $plugins += [ordered]@{
                id     = "sf_" + [System.IO.Path]::GetFileNameWithoutExtension($f.Name) -replace "\s+", "_"
                name   = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
                format = Get-PluginFormat $f.Extension
                path   = $f.FullName
                vendor = "Unknown"
                os     = "Any"
                arch   = "Any"
            }
        }
        $crawledPaths += $cfg.soundfontDir
    }

    # 2. Scan pluginPaths
    if ($cfg.pluginPaths) {
        foreach ($p in $cfg.pluginPaths) {
            if (Test-Path $p) {
                Write-Host "Scanning Plugins in: $p"
                $files = Get-ChildItem -Path $p -Include "*.vst3", "*.dll", "*.vst", "*.component" -Recurse
                # Note: .vst and .component and .vst3 can be folders on macOS.
                # On Windows, .vst3 can be a folder or file? Usually folder.
                # Get-ChildItem -File won't catch .vst bundles on Mac. 
                # For MVP, let's stick to File for dll/vst3-files, and check Directory for bundles?
                # Simpler: just get all items matching name.
                
                foreach ($f in $files) {
                    # Skip files inside already-identified bundles? Too complex for MVP.
                    # Just flat scan.
                    
                    # Filter: DLLs are VST2 on Windows.
                    # VST3 is usually a folder ending in .vst3? Or a file?
                    # On Windows: .vst3 file inside folder. On Mac: .vst3 bundle folder.
                    
                    $valid = $false
                    if ($f.Extension -eq ".dll") { $valid = $true } # Win VST
                    if ($f.Extension -eq ".vst3") { $valid = $true }
                    if ($f.Extension -eq ".vst") { $valid = $true }
                    if ($f.Extension -eq ".component") { $valid = $true }
                    
                    if ($valid) {
                        $plugins += [ordered]@{
                            id     = "pl_" + [System.IO.Path]::GetFileNameWithoutExtension($f.Name) -replace "\s+", "_"
                            name   = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
                            format = Get-PluginFormat $f.Extension
                            path   = $f.FullName
                            vendor = "Unknown"
                            os     = if ($f.Extension -match "dll") { "Windows" } elseif ($f.Extension -match "component") { "macOS" } else { "Any" }
                            arch   = "Unknown"
                        }
                    }
                }
                $crawledPaths += $p
            }
            else {
                Write-Warning "Plugin path not found: $p"
            }
        }
    }

    # Unique by path
    $unique = $plugins | Sort-Object path -Unique
    
    # Save Index
    $idxPath = if ($cfg.pluginIndexPath) { $cfg.pluginIndexPath } else { Join-Path $cfg.outputDir "plugin_index.json" }
    
    # Ensure dir exists
    $idxDir = Split-Path $idxPath -Parent
    if (-not (Test-Path $idxDir)) { New-Item -ItemType Directory -Force -Path $idxDir | Out-Null }
    
    $unique | ConvertTo-Json -Depth 3 | Out-File $idxPath -Encoding UTF8
    Write-Host "Scanned $( $unique.Count ) plugins. Index saved to: $idxPath"
}

if ($Command -eq "help") {
    Show-Help
    exit 0
}

if ($Command -eq "validate") {
    $idx = $cfg.pluginIndexPath
    if (-not $idx) { $idx = "(using default in output)" }
    Write-Host "Plugin Index: $idx"
    Write-Host "SoundFont Dir: $($cfg.soundfontDir)"
    if ($cfg.pluginPaths) {
        Write-Host "Plugin Paths: $($cfg.pluginPaths -join ", ")"
    }
    else {
        Write-Host "Plugin Paths: (None configured)"
    }
    
    # Check write access to index location
    if ($cfg.pluginIndexPath) {
        $d = Split-Path $cfg.pluginIndexPath -Parent
        if (-not (Test-Path $d)) {
            Write-Warning "Index directory does not exist: $d"
        }
    }
}

if ($Command -eq "scan") {
    Scan-Plugins
}

if ($Command -eq "list") {
    $idxPath = if ($cfg.pluginIndexPath) { $cfg.pluginIndexPath } else { Join-Path $cfg.outputDir "plugin_index.json" }
    
    if (-not (Test-Path $idxPath)) {
        Write-Warning "No index found at $idxPath. Run 'scan' first."
        exit 0
    }
    
    $data = Get-Content $idxPath -Raw | ConvertFrom-Json
    if ($Format) {
        $data = $data | Where-Object { $_.format -eq $Format }
    }
    
    if ($data) {
        $data | Format-Table id, name, format, os, path -AutoSize
    }
    else {
        Write-Host "No plugins found."
    }
}
