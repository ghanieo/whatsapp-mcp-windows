# Step 4: install the Python deps and register the "whatsapp" MCP server in Claude Code (user scope).
. "$PSScriptRoot\common.ps1"

$uv = Find-Uv
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw 'Perintah "claude" tidak ditemukan. Install Claude Code dulu (lihat README), lalu buka terminal baru.'
}
$allowed = Join-Path $ServerDir 'allowed_chats.txt'
if (-not (Test-Path $allowed)) { Copy-Item (Join-Path $ServerDir 'allowed_chats.example.txt') $allowed }

& $uv sync --project $ServerDir
if ($LASTEXITCODE -ne 0) { throw 'uv sync gagal.' }

$ErrorActionPreference = 'Continue'
& claude mcp get whatsapp *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host 'MCP "whatsapp" sudah ada, diganti dengan yang baru.'
    & claude mcp remove whatsapp -s user
}
& claude mcp add whatsapp -s user -- $uv --directory $ServerDir run main.py
& claude mcp get whatsapp
Write-Host ''
Write-Host 'Selesai. Tool WhatsApp muncul di sesi Claude yang BARU dibuka sesudah ini.'
