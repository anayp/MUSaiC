param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("info", "beats", "pitch")]
    [string]$Mode,
    
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

$ErrorActionPreference = "Stop"
$cdpBin = "f:\CDP\CDPR8\_cdp\_cdprogs"
$sndInfo = Join-Path $cdpBin "sndinfo.exe"
$pitchExe = Join-Path $cdpBin "pitch.exe"
$viewExe = Join-Path $cdpBin "view.exe"

if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }
$InputFile = (Resolve-Path $InputFile).Path

function Get-Info {
    if (Test-Path $sndInfo) {
        $out = & $sndInfo $InputFile 2>&1
        # sndinfo output entries are usually "Label: Value"
        # Select-String returns MatchInfo. We want the Line.
        
        $dur = ($out | Select-String "Duration").Line -replace ".*Duration\s*:\s*", ""
        $sr = ($out | Select-String "Sample Rate").Line -replace ".*Sample Rate\s*:\s*", ""
        $ch = ($out | Select-String "Channels").Line -replace ".*Channels\s*:\s*", ""
        $peak = ($out | Select-String "Peak Level").Line -replace ".*Peak Level\s*:\s*", ""

        return @{
            Tool       = "sndinfo"
            Duration   = $dur
            SampleRate = $sr
            Channels   = $ch
            Peak       = $peak
            Raw        = $out[0..4] # Debug context
        }
    }
    else {
        # Fallback to ffmpeg
        $p = Start-Process ffmpeg -ArgumentList "-i", $InputFile -NoNewWindow -Wait -PassThru 2>&1
        return @{ Tool = "ffmpeg"; Note = "Install CDP for better info" }
    }
}

function Get-Beats {
    # Use ffmpeg bpm filter
    # ffmpeg -i input -af "bpm" -f null /dev/null
    Write-Host "Analyzing BPM with ffmpeg..."
    $p = Start-Process ffmpeg -ArgumentList "-i", $InputFile, "-af", "bpm", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "bpm_err.txt"
    $err = Get-Content "bpm_err.txt"
    $bpmLines = $err | Select-String "BPM"
    if ($bpmLines) {
        return @{ BPM_Output = $bpmLines[-10..-1] } # Last few lines
    }
    return @{ Error = "Could not detect BPM" }
}

function Get-Pitch {
    # Use CDP pitch + view
    if ((Test-Path $pitchExe) -and (Test-Path $viewExe)) {
        $anaFile = $InputFile + ".frq"
        $txtFile = $InputFile + "_pitch.txt"
        
        Write-Host "Running CDP Pitch..."
        # pitch mode 1 (pitch+amp) input output
        $args = @("pitch", 1, $InputFile, $anaFile)
        $p = Start-Process $pitchExe -ArgumentList $args -NoNewWindow -Wait -PassThru
        
        if ($p.ExitCode -eq 0) {
            Write-Host "Refining with View..."
            # view anafile 
            $out = & $viewExe $anaFile
            $out | Out-File $txtFile
            Remove-Item $anaFile
            
            # Parse average pitch? view output is huge list of frames.
            # Let's just return path to detailed text
            return @{
                Method       = "CDP Pitch"
                AnalysisFile = $txtFile
                Snippet      = $out[0..10]
            }
        }
    }
    return @{ Error = "CDP pitch/view tools missing" }
}

$result = $null
switch ($Mode) {
    "info" { $result = Get-Info }
    "beats" { $result = Get-Beats }
    "pitch" { $result = Get-Pitch }
}

$result | ConvertTo-Json -Depth 2
