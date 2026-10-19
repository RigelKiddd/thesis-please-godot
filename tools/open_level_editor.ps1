# Launch the local content workbench on a free localhost port.
# Usage: powershell -ExecutionPolicy Bypass -File tools\open_level_editor.ps1 [-Port 8899]

param([int]$Port = 8899)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$editor = Join-Path $root "tools\level-editor\index.html"
if (!(Test-Path $editor)) {
    Write-Host "Editor not found: $editor" -ForegroundColor Red
    exit 1
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (!$python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (!$python) {
    Write-Host "Python not found. Open tools\level-editor\index.html directly and choose the project folder." -ForegroundColor Yellow
    exit 1
}

for ($i = 0; $i -lt 20; $i++) {
    $candidate = $Port + $i
    $busy = Get-NetTCPConnection -State Listen -LocalPort $candidate -ErrorAction SilentlyContinue
    if (!$busy) { $Port = $candidate; break }
}

$log = Join-Path $env:TEMP "thesis_level_editor_$Port.log"
$process = Start-Process -FilePath $python.Source `
    -ArgumentList @("-m", "http.server", "$Port", "--bind", "127.0.0.1", "--directory", $root) `
    -RedirectStandardOutput $log -RedirectStandardError "$log.err" `
    -WorkingDirectory $root -PassThru -WindowStyle Hidden
Start-Sleep -Milliseconds 900
$url = "http://127.0.0.1:$Port/tools/level-editor/"
Start-Process $url
Write-Host "Editor: $url" -ForegroundColor Green
Write-Host "Server PID: $($process.Id). Close that process to stop the editor." -ForegroundColor DarkGray
