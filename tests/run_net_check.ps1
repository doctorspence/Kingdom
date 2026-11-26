# Runs the 3-player network check: one host and two joining players, all on
# this PC, headless, then the stealth check (a host and one joiner). Prints every RESULT line. Usage (PowerShell, project folder):
#   powershell -ExecutionPolicy Bypass -File tests\run_net_check.ps1
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$project = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $env:TEMP "kingdom_net_check"
New-Item -ItemType Directory -Force $outDir | Out-Null
$procs = @()
foreach ($role in 'host', 'a', 'b') {
    $args = @('--headless', '--path', "`"$project`"", '--script', 'res://tests/run.gd', '--', 'net_check', $role)
    $procs += Start-Process -FilePath $godot -ArgumentList $args -RedirectStandardOutput "$outDir\$role.txt" -RedirectStandardError "$outDir\$role.err" -PassThru -NoNewWindow
    Start-Sleep -Seconds 2
}
foreach ($p in $procs) {
    if (-not $p.WaitForExit(90000)) { $p.Kill(); Write-Output "A test copy timed out and was stopped." }
}
foreach ($role in 'host', 'a', 'b') {
    Get-Content "$outDir\$role.txt" | Where-Object { $_ -like 'RESULT*' }
    Get-Content "$outDir\$role.err" | Where-Object { $_ -match 'ERROR|SCRIPT' } | Select-Object -First 10 | ForEach-Object { "[$role] $_" }
}

# Part 2: stealth over the network, one host and one joining player.
$procs = @()
foreach ($role in 'host', 'a') {
    $args = @('--headless', '--path', "`"$project`"", '--script', 'res://tests/run.gd', '--', 'net_stealth_check', $role)
    $procs += Start-Process -FilePath $godot -ArgumentList $args -RedirectStandardOutput "$outDir\s_$role.txt" -RedirectStandardError "$outDir\s_$role.err" -PassThru -NoNewWindow
    Start-Sleep -Seconds 2
}
foreach ($p in $procs) {
    if (-not $p.WaitForExit(90000)) { $p.Kill(); Write-Output "A stealth test copy timed out and was stopped." }
}
foreach ($role in 'host', 'a') {
    Get-Content "$outDir\s_$role.txt" | Where-Object { $_ -like 'RESULT*' }
    Get-Content "$outDir\s_$role.err" | Where-Object { $_ -match 'ERROR|SCRIPT' } | Select-Object -First 10 | ForEach-Object { "[stealth $role] $_" }
}
