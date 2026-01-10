function Show-Menu {
    param($Items)
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host "[$i] $($Items[$i].Name)"
    }
    return Read-Host "Select a score (0-$($Items.Count-1))"
}

param([switch]$NoPlay)

$examplesDir = Join-Path $PSScriptRoot "examples"
if (-not (Test-Path $examplesDir)) {
    throw "Examples directory not found at $examplesDir"
}

$scores = Get-ChildItem -Path $examplesDir -Filter "*.json"

Write-Host "=== CDP DAW Wrapper ==="
Write-Host "Found $($scores.Count) scores."

$selection = Show-Menu -Items $scores

if ($selection -match "^\d+$" -and [int]$selection -lt $scores.Count) {
    $target = $scores[[int]$selection].FullName
    
    # Peek at project name
    $json = Get-Content -Raw $target | ConvertFrom-Json
    $proj = if ($json.project) { $json.project } else { "Project" }
    
    Write-Host "Target Score: $target"
    Write-Host "Project Name: $proj"
    
    $args = @("-ScorePath", $target)
    if (-not $NoPlay) { $args += "-Play" }
    
    & "$PSScriptRoot\cdp-sequencer.ps1" @args
}
else {
    Write-Warning "Invalid selection."
}
