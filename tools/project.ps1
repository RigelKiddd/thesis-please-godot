param(
    [ValidateSet("setup", "doctor", "test", "build", "pack", "export", "release")]
    [string]$Command = "test",
    [switch]$SkipShots,
    [string]$Godot = ""
)
$ErrorActionPreference = "Stop"
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (!$pythonCommand) { $pythonCommand = Get-Command python3 -ErrorAction Stop }
$projectArgs = @("-X", "utf8", (Join-Path $PSScriptRoot "project.py"), $Command)
if ($SkipShots) { $projectArgs += "--skip-shots" }
if ($Godot) { $projectArgs += @("--godot", $Godot) }
& $pythonCommand.Source @projectArgs
exit $LASTEXITCODE
