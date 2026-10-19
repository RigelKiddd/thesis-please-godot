# Compatibility wrapper; all checks and engine resolution live in project.py.
param([switch]$SkipShots, [string]$Godot = "")
& (Join-Path $PSScriptRoot "project.ps1") -Command pack -SkipShots:$SkipShots -Godot $Godot
exit $LASTEXITCODE
