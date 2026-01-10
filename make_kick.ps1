$cdpBin = "f:\CDP\CDPR8\_cdp\_cdprogs"
$synthExe = Join-Path $cdpBin "synth.exe"
$outFile = "f:\CDP\examples\kick.wav"

$args = @(
    "wave", 1, $outFile, 48000, 1, 
    0.5, 100, "-a0.8"
)

Write-Host "Running synth..."
$p = Start-Process -FilePath $synthExe -ArgumentList $args -NoNewWindow -PassThru -Wait
if ($p.ExitCode -eq 0) { Write-Host "Success: $outFile" }
else { Write-Error "Failed" }
