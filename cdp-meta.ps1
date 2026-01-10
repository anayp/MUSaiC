param(
    [Parameter(Mandatory = $false)]
    [string]$Init,

    [Parameter(Mandatory = $false)]
    [string]$Show,

    [Parameter(Mandatory = $false)]
    [string]$Update,

    [Parameter(Mandatory = $false)]
    [string[]]$Set # Array of "key=value" strings
)

$ErrorActionPreference = "Stop"
$TemplatePath = Join-Path $PSScriptRoot "examples\musaic_meta.json"

# --- INIT ---
if ($Init) {
    if (Test-Path $Init) {
        Write-Warning "File already exists: $Init"
        exit
    }
    
    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found at $TemplatePath"
    }
    
    $meta = Get-Content -Raw $TemplatePath | ConvertFrom-Json
    $meta.created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $meta.updated_at = $meta.created_at
    
    $meta | ConvertTo-Json -Depth 5 | Set-Content $Init -Encoding Ascii
    Write-Host "Initialized metadata at: $Init" -ForegroundColor Green
    exit
}

# --- SHOW ---
if ($Show) {
    if (-not (Test-Path $Show)) { throw "File not found: $Show" }
    $meta = Get-Content -Raw $Show | ConvertFrom-Json
    
    Write-Host "`nPROJECT: $($meta.project_name)" -ForegroundColor Cyan
    Write-Host "Context: $($meta.tempo) BPM | $($meta.key) $($meta.scale)"
    Write-Host "Sections:"
    $meta.sections | Format-Table name, length, notes -AutoSize | Out-String | Write-Host
    exit
}

# --- UPDATE ---
if ($Update) {
    if (-not (Test-Path $Update)) { throw "File not found: $Update" }
    if (-not $Set) { Write-Warning "No values to set. Use -Set 'key=value'"; exit }
    
    $meta = Get-Content -Raw $Update | ConvertFrom-Json
    $modified = $false
    
    foreach ($pair in $Set) {
        if ($pair -match "^([^=]+)=(.*)$") {
            $rawKey = $Matches[1].Trim()
            $valStr = $Matches[2].Trim()
            
            # Type Inference
            $val = $valStr
            if ($valStr -ieq "true") { $val = $true }
            elseif ($valStr -ieq "false") { $val = $false }
            elseif ($valStr -match "^-?\d+$") { $val = [int]$valStr } # Handle negative
            elseif ($valStr -match "^-?\d+\.\d+$") { $val = [double]$valStr }
            
            # Traversal
            $parts = $rawKey -split '\.'
            $cursor = $meta
            $found = $true
            
            # Traverse to parent of leaf
            for ($i = 0; $i -lt $parts.Count - 1; $i++) {
                $p = $parts[$i]
                
                # Check for Array Index (numeric and cursor is list)
                if ($cursor -is [System.Collections.IList] -and $p -match "^\d+$") {
                    $idx = [int]$p
                    if ($idx -ge 0 -and $idx -lt $cursor.Count) {
                        $cursor = $cursor[$idx]
                    }
                    else { $found = $false; break }
                }
                # Check for Object Property
                elseif ($null -ne $cursor -and $cursor.PSObject.Properties[$p]) {
                    $cursor = $cursor.$p
                }
                else { $found = $false; break }
            }
            
            # Set Leaf Value
            if ($found) {
                $last = $parts[-1]
                
                # Array Leaf
                if ($cursor -is [System.Collections.IList] -and $last -match "^\d+$") {
                    $idx = [int]$last
                    if ($idx -ge 0 -and $idx -lt $cursor.Count) {
                        $cursor[$idx] = $val
                        Write-Host "Updated: $rawKey -> $val"
                        $modified = $true
                    }
                    else { Write-Warning "Index out of bounds: $rawKey" }
                }
                # Object Leaf
                elseif ($null -ne $cursor -and $cursor.PSObject.Properties[$last]) {
                    $cursor.$last = $val
                    Write-Host "Updated: $rawKey -> $val"
                    $modified = $true
                }
                else { Write-Warning "Key '$last' not found in path '$rawKey'. Skipping." }
            }
            else {
                Write-Warning "Path '$rawKey' not found. Skipping."
            }
        }
    }
    
    if ($modified) {
        $meta.updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $meta | ConvertTo-Json -Depth 5 | Set-Content $Update -Encoding Ascii
        Write-Host "Saved changes to $Update" -ForegroundColor Green
    }
    exit
}

Write-Host "Usage: cdp-meta.ps1 [-Init path] | [-Show path] | [-Update path -Set 'key=val']"
