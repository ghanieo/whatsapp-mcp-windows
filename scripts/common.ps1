# Shared paths and helpers for the setup scripts (dot-sourced).
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$BridgeDir = Join-Path $Root 'whatsapp-bridge'
$ServerDir = Join-Path $Root 'whatsapp-mcp-server'
$BridgeExe = Join-Path $BridgeDir 'wabridge.exe'
$TaskName = 'WhatsApp Bridge'
$ReleaseUrl = 'https://github.com/ghanieo/whatsapp-mcp-windows/releases/latest/download/wabridge.exe'

function Find-Uv {
    $cmd = Get-Command uv -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # winget installs uv here; PATH only updates in new terminals
    $hit = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\astral-sh.uv_*\uv.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { return $hit.FullName }
    throw 'uv belum terpasang. Jalankan: winget install --id astral-sh.uv -e   lalu buka terminal baru.'
}

function Stop-Bridge {
    # Stops the scheduled task (if any) and any wabridge.exe started from this folder
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task -and $task.State -eq 'Running') { Stop-ScheduledTask -TaskName $TaskName }
    Get-Process wabridge -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $BridgeExe } | Stop-Process -Force
}
