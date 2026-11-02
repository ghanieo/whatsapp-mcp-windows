# Windows replacement for the macOS LaunchAgent (KeepAlive).
# Started at logon by the "WhatsApp Bridge" scheduled task; keeps wabridge.exe alive
# and appends its output to bridge.log (rotated at 20 MB, one .old copy kept).
$ErrorActionPreference = 'Continue'
$dir = $PSScriptRoot
Set-Location $dir
$log = Join-Path $dir 'bridge.log'
$exe = Join-Path $dir 'wabridge.exe'

while ($true) {
    if ((Test-Path $log) -and (Get-Item $log).Length -gt 20MB) {
        Move-Item $log "$log.old" -Force
    }
    Add-Content -Path $log -Encoding utf8 -Value "=== $(Get-Date -Format s) starting wabridge ==="
    # cmd handles the redirection so the bridge's UTF-8 output is appended byte-for-byte
    & cmd.exe /c "`"$exe`" >> `"$log`" 2>&1"
    Add-Content -Path $log -Encoding utf8 -Value "=== $(Get-Date -Format s) wabridge exited (code $LASTEXITCODE), restarting in 15s ==="
    Start-Sleep -Seconds 15
}
