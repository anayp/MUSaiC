$cdpBin = "f:\CDP\CDPR8\_cdp\_cdprogs"
$synthExe = Join-Path $cdpBin "synth.exe"
$outFile = "f:\CDP\examples\kick.wav"

$procArgs = @(
    "wave", 1, $outWav, 44100, 1, 
    $dur, $freq,
    "-a$amp", "-v$vib"
)

$p = Start-Process -FilePath $synthExe -ArgumentList $procArgs -NoNewWindow -PassThru -Wait
if ($p.ExitCode -eq 0) { Write-Host "Success: $outFile" }
else { Write-Error "Failed" }
