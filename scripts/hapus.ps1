# Uninstall: stop the bridge, remove the logon task and the MCP registration.
# Chat data (whatsapp-bridge\store, bridge.log) is NOT deleted; delete the folder yourself if you want it gone.
. "$PSScriptRoot\common.ps1"
$ErrorActionPreference = 'Continue'

Stop-Bridge
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Task '$TaskName' dihapus."
}
if (Get-Command claude -ErrorAction SilentlyContinue) { & claude mcp remove whatsapp -s user }
Write-Host ''
Write-Host 'Jangan lupa: di HP, WhatsApp > Perangkat tertaut > logout perangkat bridge ini.'
Write-Host 'Data chat masih ada di whatsapp-bridge\store dan bridge.log; hapus folder repo ini kalau mau bersih total.'
