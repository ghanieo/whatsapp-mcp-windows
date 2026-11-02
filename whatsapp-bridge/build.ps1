# Optional: build wabridge.exe yourself instead of downloading it.
# Needs Go (winget install --id GoLang.Go -e) and gcc for CGO/SQLite
# (winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e). Open a new terminal after installing.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command gcc -ErrorAction SilentlyContinue)) {
    $gcc = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_*\mingw64\bin" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gcc) { throw 'gcc tidak ditemukan. Install WinLibs (lihat komentar di atas).' }
    $env:PATH = "$($gcc.FullName);$env:PATH"
}
$env:CGO_ENABLED = '1'
go build -trimpath -ldflags '-s -w' -o wabridge.exe .
if ($LASTEXITCODE -ne 0) { throw 'go build gagal.' }
Get-FileHash wabridge.exe -Algorithm SHA256 | Select-Object Hash
