param (
    [Parameter(Mandatory = $false)]
    [switch]$Init,

    [Parameter(Mandatory = $false)]
    [switch]$Reset
)

# Load configuration
. "$PSScriptRoot\..\musaic-config.ps1"
$configObject = Get-MusaicConfig
if (-not $configObject) {
    Write-Error "Failed to load configuration."
    exit 1
}

# Access properties
$connString = $configObject.dbConnectionString

if ([string]::IsNullOrWhiteSpace($connString)) {
    Write-Warning "No 'dbConnectionString' found in musaic.config.json."
    Write-Warning "Please set it to a valid PostgreSQL connection string (e.g., 'postgresql://user:pass@localhost:5432/musaic')."
    Write-Warning "Skipping DB operations."
    exit 0
}

# Check for psql
try {
    $null = & psql --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw "psql check failed" }
}
catch {
    Write-Error "PostgreSQL client 'psql' is not found in PATH."
    Write-Error "Please install PostgreSQL tools or add them to your PATH."
    exit 1
}

if ($Reset) {
    Write-Host "Resetting database schema..." -ForegroundColor Yellow
    # This is destructive!
    $resetCmd = "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
    $env:PGCONNECT_TIMEOUT = 5
    echo $resetCmd | psql $connString
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to reset schema."
        exit 1
    }
    Write-Host "Schema reset." -ForegroundColor Green
    # Init implies running schema after reset
    $Init = $true
}

if ($Init) {
    Write-Host "Initializing database schema..." -ForegroundColor Cyan
    $schemaDir = Join-Path $PSScriptRoot "..\sql\schema"
    if (-not (Test-Path $schemaDir)) {
        Write-Error "Schema directory not found: $schemaDir"
        exit 1
    }

    $schemaFiles = Get-ChildItem -Path $schemaDir -Filter "*.sql" | Sort-Object Name

    # Ensure schema_migrations table exists
    Write-Host "Checking for migration tracking table..."
    $checkTableCmd = "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW());"
    echo $checkTableCmd | psql $connString
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to ensure schema_migrations table exists."
        exit 1
    }

    foreach ($file in $schemaFiles) {
        $version = $file.Name
        # Check if already applied
        $checkCmd = "SELECT 1 FROM schema_migrations WHERE version = '$version';"
        $result = echo $checkCmd | psql $connString -t -A
        
        if ($result -eq "1") {
            Write-Host "Skipping $version (already applied)." -ForegroundColor Gray
            continue
        }

        Write-Host "Applying $version..."
        psql $connString -f $file.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply $version."
            exit 1
        }

        # Record migration
        $recordCmd = "INSERT INTO schema_migrations (version) VALUES ('$version');"
        echo $recordCmd | psql $connString
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to record migration $version."
            exit 1
        }
    }
    Write-Host "Database migration/initialization successfully completed." -ForegroundColor Green
}


if (-not $Init -and -not $Reset) {
    Write-Host "Usage: ./tools/db.ps1 -Init | -Reset"
}
