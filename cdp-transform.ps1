param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("tempo", "pitch")]
    [string]$Mode,
    
    [Parameter(Mandatory = $true)]
    [string]$In,
    
    [Parameter(Mandatory = $true)]
    [string]$Out,
    
    [Parameter(Mandatory = $true)]
    [double]$Amount, # Tempo: Percent (e.g. 110 = +10%). Pitch: Semitones (e.g. 2, -12)

    [string]$Method = "fast" # "fast" (modify speed - changes both), "pvoc" (preserves one)
)

$ErrorActionPreference = "Stop"
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
    $args = @("speed", 1, $In, $Out, $ratio)
    $p = Start-Process $modifyExe -ArgumentList $args -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "modify speed failed" }
}

function Run-Pvoc {
    # Phase Vocoder for independent time/pitch
    # 1. Analyze: pvoc anal 1 input ana
    # 2. Transform: pvoc stretch (time) OR pvoc trans (pitch)
    # 3. Synth: pvoc synth ana output
    
    $anaFile = $In + ".ana"
    $anaMod = $In + ".mod.ana"
    
    Write-Host "Analyzing..."
    $p = Start-Process $pvocExe -ArgumentList "anal", 1, $In, $anaFile -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "pvoc anal failed" }
    
    try {
        if ($Mode -eq "tempo") {
            # pvoc stretch mode infile outfile times
            # times: e.g. 0 0 10 5 -> output 5s long from input 10s? 
            # stretch usage: mode 1 (time_stretch). 
            # Usage: pvoc stretch 1 infile outfile dparam
            # dparam: ratio? "Time stretch ratio > 1 extends, < 1 shortens"
            
            # Amount 120 (120%) -> 1.2?
            # User wants "Tempo" (BPM). Higher BPM = shorter duration.
            # If Amount = 200% tempo, Duration = 0.5.
            # Convert Amount/100 to Duration Ratio.
            # CDP Stretch Ratio: 2.0 = Double Duration (Half Speed)? Or Half Duration?
            # Manual says: "Multiplier for duration." 
            # So if we want Faster Tempo (Amount > 100), we want Shorter Duration (Ratio < 1).
            
            $ratio = 100.0 / $Amount
            Write-Host "Time Stretching (Duration Ratio: $ratio)..."
            
            $p = Start-Process $pvocExe -ArgumentList "stretch", 1, $anaFile, $anaMod, $ratio -NoNewWindow -Wait -PassThru
            if ($p.ExitCode -ne 0) { throw "pvoc stretch failed" }
        }
        elseif ($Mode -eq "pitch") {
            # pvoc trans mode infile outfile shift
            # shift in semitones.
            Write-Host "Pitch Shifting ($Amount semitones)..."
            $p = Start-Process $pvocExe -ArgumentList "trans", 1, $anaFile, $anaMod, $Amount -NoNewWindow -Wait -PassThru
            if ($p.ExitCode -ne 0) { throw "pvoc trans failed" }
        }
        
        Write-Host "Synthesizing..."
        $p = Start-Process $pvocExe -ArgumentList "synth", $anaMod, $Out -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw "pvoc synth failed" }
        
    }
    finally {
        if (Test-Path $anaFile) { Remove-Item $anaFile }
        if (Test-Path $anaMod) { Remove-Item $anaMod }
    }
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
