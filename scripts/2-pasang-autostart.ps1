# Step 2: register the logon task and start the bridge in the background now.
. "$PSScriptRoot\common.ps1"

if (-not (Test-Path (Join-Path $BridgeDir 'store\whatsapp.db'))) {
    throw 'Belum tertaut. Jalankan 1-tautkan-whatsapp.bat dulu.'
}
Stop-Bridge
& (Join-Path $BridgeDir 'install-task.ps1')
Start-ScheduledTask -TaskName $TaskName
Write-Host 'Menunggu bridge tersambung...'
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    if (Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue) {
        Write-Host 'OK: bridge jalan di latar belakang (127.0.0.1:8080) dan akan otomatis jalan tiap login.'
        return
    }
}
Write-Warning 'Bridge belum listen di 127.0.0.1:8080. Cek whatsapp-bridge\bridge.log (baris paling bawah).'
