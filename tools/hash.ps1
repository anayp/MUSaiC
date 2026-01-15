param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("SHA256", "SHA1", "MD5")]
    [string]$Algo = "SHA256"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$hash = Get-FileHash -Path $Path -Algorithm $Algo
# Output only the hash string
Write-Output $hash.Hash
