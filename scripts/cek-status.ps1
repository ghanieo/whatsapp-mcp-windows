# Quick health check: task state, listener, last bridge.log lines (status lines only, no message text).
. "$PSScriptRoot\common.ps1"
$ErrorActionPreference = 'Continue'

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Write-Host ("Task '{0}': {1}" -f $TaskName, $(if ($task) { $task.State } else { 'belum dipasang' }))
$listen = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
Write-Host ("Port 8080: {0}" -f $(if ($listen) { ($listen.LocalAddress | Sort-Object -Unique) -join ', ' } else { 'tidak listen' }))
$log = Join-Path $BridgeDir 'bridge.log'
if (Test-Path $log) {
    Write-Host 'Status terakhir di bridge.log:'
    Get-Content $log -Tail 2000 |
        Select-String -Pattern '=== |Connected to WhatsApp|REST server|logged out|Scan this QR|ERROR|StreamReplaced|Client outdated|Failed' |
        Select-Object -Last 8 | ForEach-Object { '  ' + $_.Line }
}
