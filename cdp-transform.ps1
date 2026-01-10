param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("tempo", "pitch")]
    [string]$Mode,
    
    [Parameter(Mandatory = $false)]
    [string]$In,
    
    [Parameter(Mandatory = $false)]
    [string]$Out,
    
    [Parameter(Mandatory = $false)]
    [double]$Amount, # Tempo: Percent (e.g. 110 = +10%). Pitch: Semitones (e.g. 2, -12)

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [string]$Method = "fast", # "fast" (modify speed - changes both), "pvoc" (preserves one)
    
    [System.Collections.IDictionary]$Params = @{}
)

$ErrorActionPreference = "Stop"

# Load Config if present
if ($ConfigPath) {
    if (-not (Test-Path $ConfigPath)) { throw "Config file not found: $ConfigPath" }
    $cfg = Get-Content -Raw $ConfigPath | ConvertFrom-Json
    
    # Helper for safe config property
    function Get-Cfg { param($P, $Def) if ($cfg.PSObject.Properties[$P]) { return $cfg.$P } return $Def }
    
    if (-not $Mode) { $Mode = Get-Cfg "mode" $Mode }
    if (-not $In) { $In = Get-Cfg "input" $In } # "input" or "In"? Support both?
    if (-not $Out) { $Out = Get-Cfg "output" $Out }
    if ($Amount -eq 0) { $Amount = Get-Cfg "amount" 0 }
    if ($Method -eq "fast") { $Method = Get-Cfg "method" "fast" }
    
    if ($cfg.params) {
        foreach ($k in $cfg.params.PSObject.Properties.Name) {
            $Params[$k] = $cfg.params.$k
        }
    }
}
                    
$cdpBin = "f:\CDP\CDPR8\_cdp\_cdprogs"
$modifyExe = Join-Path $cdpBin "modify.exe"
$pvocExe = Join-Path $cdpBin "pvoc.exe"

if (-not (Test-Path $In)) { throw "Input file not found: $In" }
$In = (Resolve-Path $In).Path
$Out = [System.IO.Path]::GetFullPath($Out)

function Run-ModifySpeed {
    # modify speed 1 infile outfile ratio
    # ratio: 1.0 = normal. 2.0 = double speed (half duration, +1 octave).
    
    $ratio = 1.0
    if ($Mode -eq "tempo") {
        # Amount is Percent. 100 = 1.0. 200 = 2.0.
        $ratio = $Amount / 100.0
    }
    elseif ($Mode -eq "pitch") {
        # Amount is Semitones.
        $ratio = [Math]::Pow(2, $Amount / 12.0)
    }
    
    Write-Host "Running modify speed (Ratio: $ratio)..."
    $toolArgs = @("speed", 1, $In, $Out, $ratio)
    $p = Start-Process $modifyExe -ArgumentList $toolArgs -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "modify speed failed" }
}

function Run-Pvoc {
    # Phase Vocoder for independent time/pitch
    # Strategy: Bypass pvoc.exe if specific tools (stretch, strans) exist.
    # pvoc.exe in this install is "light" and crashes on 'anal'.
    
    if ($Mode -eq "tempo") {
        # Try stretch.exe
        $stretchExe = Join-Path $cdpBin "stretch.exe"
        if ($false -and (Test-Path $stretchExe)) {
            try {
                Write-Host "DEBUG: Executing $stretchExe"
                $fac = 100.0 / $Amount 
                $toolArgs = @("time", 1, $In, $Out, $fac)
                $p = Start-Process $stretchExe -ArgumentList $toolArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $null -RedirectStandardError $null
                if ($p.ExitCode -eq 0) { return }
                Write-Warning "Stretch failed. Exit code: $($p.ExitCode)"
                Write-Warning "DEBUG: Stretch exit code: $($p.ExitCode)"
            }
            catch {
                Write-Warning "Failed to launch stretch.exe: $_"
            }
        }
        
        # Fallback to modify speed (reliable)
        Write-Warning "Falling back to 'modify speed' for tempo change (affects pitch)."
        Write-Host "DEBUG: Executing $modifyExe"
        $ratio = $Amount / 100.0
        $toolArgs = @("speed", 1, $In, $Out, $ratio)
        $p = Start-Process $modifyExe -ArgumentList $toolArgs -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw "Fallback modify speed failed" }
        return
    }
    elseif ($Mode -eq "pitch") {
        # Try strans.exe
        $stransExe = Join-Path $cdpBin "strans.exe"
        if (Test-Path $stransExe) {
            try {
                $toolArgs = @("multi", 2, $In, $Out, $Amount)
                $p = Start-Process $stransExe -ArgumentList $toolArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $null -RedirectStandardError $null
                if ($p.ExitCode -eq 0) { return }
                Write-Warning "Strans failed. Exit code: $($p.ExitCode)"
            }
            catch {
                Write-Warning "Failed to launch strans.exe: $_"
            }
        }
         
        # Fallback to modify speed
        Write-Warning "Falling back to 'modify speed' for pitch change (affects tempo)."
        $ratio = [Math]::Pow(2, $Amount / 12.0)
        $toolArgs = @("speed", 1, $In, $Out, $ratio)
        $p = Start-Process $modifyExe -ArgumentList $toolArgs -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw "Fallback modify speed failed" }
        return
    }
    
    throw "Mode $Mode not supported in reliable configuration."
}

if ($Method -eq "fast") {
    Run-ModifySpeed
}
elseif ($Method -eq "pvoc") {
    Run-Pvoc
}
else {
    throw "Unknown method: $Method"
}

Write-Host "Done: $Out"
