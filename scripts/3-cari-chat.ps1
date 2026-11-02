# Step 3: find chat JIDs for allowed_chats.txt, then open it in Notepad.
. "$PSScriptRoot\common.ps1"

$uv = Find-Uv
$allowed = Join-Path $ServerDir 'allowed_chats.txt'
if (-not (Test-Path $allowed)) { Copy-Item (Join-Path $ServerDir 'allowed_chats.example.txt') $allowed }

$term = $args -join ' '
if (-not $term) { $term = Read-Host 'Cari chat (nama grup / potongan nomor, kosongkan = 30 chat terbaru)' }
$env:PYTHONIOENCODING = 'utf-8'
& $uv run --project $ServerDir python -I (Join-Path $PSScriptRoot 'cari_chat.py') $term
Start-Process notepad.exe $allowed
