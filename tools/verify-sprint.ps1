param(
    [Parameter(Mandatory = $true)]
    [string]$SprintId,

    [ValidateSet("fast", "full", "perf", "release")]
    [string]$Mode = "fast"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root ("output/verification/{0}" -f $SprintId)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$report = [ordered]@{
    sprintId = $SprintId
    mode = $Mode
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    checks = @()
    summary = @{
        passed = 0
        failed = 0
        warnings = 0
    }
}

function Add-CheckResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details
    )

    $entry = [ordered]@{
        name = $Name
        status = $Status
        details = $Details
    }
    $report.checks += $entry

    switch ($Status) {
        "pass" { $report.summary.passed++ }
        "fail" { $report.summary.failed++ }
        default { $report.summary.warnings++ }
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Name)
    if (Test-Path $Path) {
        Add-CheckResult -Name $Name -Status "pass" -Details "Found: $Path"
    }
    else {
        Add-CheckResult -Name $Name -Status "fail" -Details "Missing: $Path"
    }
}

# Baseline checks common to all modes.
Test-FileExists -Path (Join-Path $root "README.md") -Name "Repo has README"
Test-FileExists -Path (Join-Path $root "musaic-config.ps1") -Name "Core config script exists"
Test-FileExists -Path (Join-Path $root "examples") -Name "Examples directory exists"

switch ($Mode) {
    "fast" {
        Test-FileExists -Path (Join-Path $root "musaic-cli.ps1") -Name "QoL CLI script exists"
    }
    "full" {
        Test-FileExists -Path (Join-Path $root "cdp-sequencer.ps1") -Name "Sequencer exists"
        Test-FileExists -Path (Join-Path $root "cdp-analyze.ps1") -Name "Analyzer exists"
    }
    "perf" {
        Test-FileExists -Path (Join-Path $root "cdp-sequencer.ps1") -Name "Sequencer exists for perf"
        Add-CheckResult -Name "Perf fixture execution" -Status "warn" -Details "Manual perf fixture execution recommended per docs/OPTIMIZATION_SPRINT_PLAN.md"
    }
    "release" {
        Test-FileExists -Path (Join-Path $root "CHANGELOG.md") -Name "Changelog exists"
        Test-FileExists -Path (Join-Path $root "docs/OPTIMIZATION_SPRINT_PLAN.md") -Name "Sprint plan doc exists"
    }
}

$jsonPath = Join-Path $outDir "report.json"
$txtPath = Join-Path $outDir "report.txt"

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding ASCII

$lines = @()
$lines += "Sprint: $SprintId"
$lines += "Mode: $Mode"
$lines += "Generated (UTC): $($report.generatedAtUtc)"
$lines += ""
$lines += "Summary:"
$lines += "  Passed:   $($report.summary.passed)"
$lines += "  Failed:   $($report.summary.failed)"
$lines += "  Warnings: $($report.summary.warnings)"
$lines += ""
$lines += "Checks:"
foreach ($check in $report.checks) {
    $lines += ("- [{0}] {1}: {2}" -f $check.status.ToUpperInvariant(), $check.name, $check.details)
}
$lines | Set-Content -Path $txtPath -Encoding ASCII

Write-Host "Verification report written:"
Write-Host " - $jsonPath"
Write-Host " - $txtPath"

if ($report.summary.failed -gt 0) {
    exit 1
}
exit 0

