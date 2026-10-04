$Env:USE_SQLITE = '1'
Set-Location -LiteralPath $PSScriptRoot
Write-Output "USE_SQLITE=$Env:USE_SQLITE"

$pythonCandidates = @(
    (Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'),
    (Join-Path $PSScriptRoot '..\venv\Scripts\python.exe'),
    (Join-Path $PSScriptRoot '..\..\..\.venv\Scripts\python.exe')
)

$python = $pythonCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $python) {
    $python = 'python'
}

& $python manage.py migrate --noinput
& $python manage.py runserver 0.0.0.0:8000
