# Wrapper for tools/check_text.py.
# Usage: powershell -ExecutionPolicy Bypass -File tools\check_text.ps1 [-Strict]
$ErrorActionPreference = "Stop"
$python = Get-Command python -ErrorAction SilentlyContinue
if (!$python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}
if (!$python) {
    Write-Host "Python not found; install Python 3 or run check_text.py with the bundled interpreter." -ForegroundColor Yellow
    exit 2
}
& $python.Source (Join-Path $PSScriptRoot "check_text.py") @args
exit $LASTEXITCODE
