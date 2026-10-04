param(
    [string]$Server = "localhost",
    [int]$Port = 5432,
    [string]$AdminUser = "postgres",
    [SecureString]$AdminPassword = $null,
    [string]$DbUser = "gstms",
    [SecureString]$DbPassword = $null,
    [string]$DbName = "gstms_db",
    [string]$SchemaPath = (Join-Path $PSScriptRoot "schema.sql"),
    [string]$PsqlPath = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SchemaPath)) {
    throw "Schema file not found: $SchemaPath"
}

function Get-PsqlPath {
    if ($PsqlPath -and (Test-Path $PsqlPath)) {
        return $PsqlPath
    }

    $cmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $commonPaths = @(
        "$env:ProgramFiles\PostgreSQL\18\bin\psql.exe",
        "$env:ProgramFiles(x86)\PostgreSQL\18\bin\psql.exe",
        "$env:ProgramFiles\PostgreSQL\17\bin\psql.exe",
        "$env:ProgramFiles(x86)\PostgreSQL\17\bin\psql.exe",
        "$env:ProgramFiles\PostgreSQL\16\bin\psql.exe",
        "$env:ProgramFiles(x86)\PostgreSQL\16\bin\psql.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    throw "psql executable not found. Install PostgreSQL client tools or provide the full path with -PsqlPath 'C:\\Program Files\\PostgreSQL\\18\\bin\\psql.exe'."
}

$PsqlExe = Get-PsqlPath

if (-not $AdminPassword) {
    $AdminPassword = Read-Host "Enter password for PostgreSQL user '$AdminUser'" -AsSecureString
}
if (-not $DbPassword) {
    $DbPassword = Read-Host "Enter password for database user '$DbUser'" -AsSecureString
}

$plainAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
$env:PGPASSWORD = $plainAdminPassword
$plainDbPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($DbPassword))

Write-Host "Creating role '$DbUser' if needed..."
$roleSql = @"
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$DbUser') THEN
        CREATE ROLE $DbUser LOGIN PASSWORD '$plainDbPassword';
    ELSE
        ALTER ROLE $DbUser WITH PASSWORD '$plainDbPassword';
    END IF;
END;
$$;
"@
& $PsqlExe -h $Server -p $Port -U $AdminUser -d postgres -c $roleSql

Write-Host "Creating database '$DbName' if needed..."
$createDbSql = @"
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$DbName') THEN
        EXECUTE 'CREATE DATABASE "$DbName" OWNER "$DbUser"';
    END IF;
END;
$$;
"@
& $PsqlExe -h $Server -p $Port -U $AdminUser -d postgres -c $createDbSql

Write-Host "Importing schema from $SchemaPath ..."
& $PsqlExe -h $Server -p $Port -U $DbUser -d $DbName -f $SchemaPath

Remove-Variable -Name plainAdminPassword -ErrorAction SilentlyContinue
Remove-Variable -Name plainDbPassword -ErrorAction SilentlyContinue
Write-Host "Database setup complete."
