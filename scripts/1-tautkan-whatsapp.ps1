# Step 1: get wabridge.exe (download + SHA256 check, unless you built it yourself) and link the phone via QR.
. "$PSScriptRoot\common.ps1"

if (-not (Test-Path $BridgeExe)) {
    $expected = (Get-Content (Join-Path $BridgeDir 'wabridge.exe.sha256') -Raw).Trim().Split(' ')[0].ToLower()
    Write-Host "Mengunduh wabridge.exe dari $ReleaseUrl ..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmp = "$BridgeExe.download"
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $tmp -UseBasicParsing
    $actual = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $expected) {
        Remove-Item $tmp -Force
        throw "SHA256 tidak cocok (dapat $actual, harusnya $expected). File dibuang. Build sendiri: lihat README bagian 'Build sendiri'."
    }
    Move-Item $tmp $BridgeExe
    Write-Host 'wabridge.exe OK (SHA256 cocok).'
}

Stop-Bridge
Set-Location $BridgeDir
Write-Host ''
Write-Host '=== Scan QR di bawah dari HP: WhatsApp > Perangkat tertaut > Tautkan perangkat ==='
Write-Host '    QR berganti tiap ~20 detik. Setelah tertaut, riwayat chat akan mengalir masuk.'
Write-Host '    Tunggu sampai log berhenti mengalir deras (bisa 5-15 menit), lalu tekan Ctrl+C.'
Write-Host '    Kalau QR tidak muncul: perangkat ini masih tertaut. Logout dulu di HP, lalu ulangi.'
Write-Host ''
& $BridgeExe
