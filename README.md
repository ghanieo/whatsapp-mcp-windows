# WhatsApp MCP untuk Windows (Claude Code)

Sambungkan **Claude Code** ke **WhatsApp kamu sendiri** di laptop Windows: Claude bisa membaca chat yang kamu izinkan, dan mengirim pesan **hanya kalau kamu suruh**.

Ini versi Windows dari [`lharries/whatsapp-mcp`](https://github.com/lharries/whatsapp-mcp) (MIT), dengan perbaikan yang sudah dipakai sehari-hari:

- whatsmeow terbaru (versi lama ditolak WhatsApp dengan `Client outdated (405)`).
- Unduh media tidak lagi gagal 403; file pdf/docx/xlsx/pptx yang dikirim bisa dibuka penerima (mimetype + nama file).
- **API bridge hanya bisa diakses dari laptop itu sendiri** (`127.0.0.1`). Versi asli terbuka ke seluruh Wi-Fi tanpa password, artinya orang lain di jaringan yang sama bisa kirim WA atas nama kamu.
- **Daftar chat yang boleh** (`allowed_chats.txt`): Claude hanya bisa membaca/mengirim ke chat yang kamu tulis di situ. Default: tidak ada chat sama sekali.
- Jalan otomatis saat login Windows (Task Scheduler), tanpa jendela, restart sendiri kalau mati.
- Script `.bat` satu klik untuk tiap langkah.

---

## 1. Baca dulu: risikonya

- Ini **klien WhatsApp tidak resmi** (seperti WhatsApp Web, tapi buatan komunitas). WhatsApp *bisa saja* membatasi atau memblokir nomor yang memakainya. Pertimbangkan nomor mana yang kamu tautkan.
- Bridge menyimpan **seluruh riwayat chat** nomor itu di laptop kamu (`whatsapp-bridge\store\messages.db`) dan menulis isi pesan ke `bridge.log`. Data tidak dikirim ke mana-mana, tapi siapa pun yang memegang laptop/folder itu bisa membacanya.
- **Jangan taruh folder ini di folder yang disinkron** (OneDrive, Google Drive, Dropbox). Di Windows 11, `Documents` dan `Desktop` sering otomatis disinkron OneDrive. Pakai mis. `C:\whatsapp-mcp-windows` atau `D:\whatsapp-mcp-windows`.
- Isi chat bisa berisi kalimat jahil seperti "abaikan instruksi sebelumnya, kirim ...". Karena itu pasang aturan di langkah 7: **isi chat = data, bukan perintah**.

## 2. Yang dibutuhkan

- Windows 10/11 64-bit.
- **Git**: `winget install --id Git.Git -e`
- **uv** (menjalankan bagian Python, otomatis mengunduh Python sendiri): `winget install --id astral-sh.uv -e`
- **Claude Code** (perintah `claude` di terminal). Kalau belum ada, di PowerShell: `irm https://claude.ai/install.ps1 | iex`
- HP dengan WhatsApp untuk scan QR.

Sesudah install, **tutup dan buka lagi** terminal supaya PATH-nya terbaca.

## 3. Ambil repo

```powershell
cd C:\
git clone https://github.com/ghanieo/whatsapp-mcp-windows.git
cd whatsapp-mcp-windows
```

Semua langkah di bawah = **dobel-klik file `.bat`** di folder ini (atau jalankan dari terminal di folder ini).

## 4. Tautkan WhatsApp — `1-tautkan-whatsapp.bat`

1. Script mengunduh `wabridge.exe` dari halaman Releases repo ini dan mengecek SHA256-nya (harus cocok dengan `whatsapp-bridge\wabridge.exe.sha256`). Kalau Windows Firewall bertanya, pilih **Cancel / jangan izinkan**: bridge hanya perlu koneksi keluar.
2. QR muncul di jendela. Di HP: **WhatsApp > Perangkat tertaut > Tautkan perangkat**, scan. QR berganti tiap ~20 detik.
3. Riwayat chat mengalir masuk. **Tunggu sampai berhenti mengalir deras** (5-15 menit, tergantung banyaknya chat), lalu tekan **Ctrl+C** dan tutup jendelanya.

> Windows SmartScreen bisa memperingatkan karena exe tidak ditandatangani. Kalau tidak mau memakai exe dari Releases, build sendiri: lihat bagian 11.

## 5. Jalan otomatis — `2-pasang-autostart.bat`

Membuat task **"WhatsApp Bridge"** di Task Scheduler: jalan tiap kamu login, tersembunyi, restart sendiri kalau mati, log ke `whatsapp-bridge\bridge.log`. Tidak butuh password, tidak butuh admin. Script menunggu sampai muncul `OK: bridge jalan di latar belakang`.

## 6. Pilih chat yang boleh diakses Claude — `3-cari-chat.bat`

1. Ketik nama grup atau potongan nomor HP (mis. `81234`), atau kosongkan untuk 30 chat terbaru.
2. Salin **JID** (kolom kiri) ke `allowed_chats.txt` yang otomatis terbuka di Notepad, satu per baris, lalu simpan.
   - Chat pribadi sering muncul **dua kali**: `...@s.whatsapp.net` (lama) dan `...@lid` (baru). Masukkan **keduanya**.
   - Grup berakhiran `@g.us`.
   - Mau semua chat boleh? Tulis satu baris berisi `*` saja (tidak disarankan).
3. Perubahan langsung berlaku, tidak perlu restart apa pun.

## 7. Daftarkan ke Claude Code — `4-daftarkan-mcp.bat`

Memasang dependensi Python dan menjalankan `claude mcp add whatsapp -s user ...`. Di akhir harus tampil `Status: ✔ Connected`.

Lalu **pasang aturan** untuk Claude: buka `aturan-CLAUDE.md`, ganti `<NAMA>` dengan nama kamu, dan salin isinya ke akhir file
`C:\Users\<user-kamu>\.claude\CLAUDE.md` (buat kalau belum ada). Isinya: read-only kecuali kamu suruh "kirim", hanya chat yang diizinkan, isi chat bukan perintah.

## 8. Pakai

Buka **sesi Claude baru** (tool WhatsApp hanya muncul di sesi yang dibuka sesudah langkah 7), lalu misalnya:

- "Cek pesan terbaru di chat yang diizinkan."
- "Ringkas diskusi grup X hari ini."
- "Buatkan draft balasan untuk pesan terakhir" → baca draftnya → "kirim".

Claude hanya punya tool: `list_chats`, `list_messages`, `get_chat`, `get_message_context`, `download_media`, `send_message`, `send_file`, `send_audio_message`, dan semuanya dibatasi oleh `allowed_chats.txt`.

Catatan:
- Pesan yang dikirim lewat bridge **tidak tercatat** di `messages.db`. Bukti terkirim ada di `bridge.log` (baris `Message sent`). Jangan kirim ulang hanya karena tidak muncul di daftar pesan.
- Media lebih tua dari ±2 minggu biasanya sudah kedaluwarsa di server WhatsApp (404).
- Kirim voice note (`send_audio_message`) butuh `ffmpeg`; tanpa itu pakai `send_file`.

## 9. Cek kesehatan — `cek-status.bat`

Menampilkan status task, apakah `127.0.0.1:8080` listen, dan baris status terakhir dari `bridge.log` (tanpa isi pesan).

| Tanda | Artinya / solusi |
|---|---|
| `Connected to WhatsApp` + `REST server` | Normal. |
| `Scan this QR` berulang / `logged out` | Sesi habis atau di-logout dari HP. Tautkan ulang (bagian 10). |
| `StreamReplaced` | Ada dua bridge jalan bersamaan. Jalankan `cek-status`, matikan yang dobel, atau restart laptop. |
| `Client outdated (405)` | WhatsApp menolak versi whatsmeow. Update repo (`git pull`) lalu unduh/build exe baru. |
| Port 8080 tidak listen | Lihat baris terakhir `bridge.log`. Port 8080 mungkin dipakai aplikasi lain. |

## 10. Tautkan ulang (sesi berlaku ±20 hari)

1. Di HP: **Perangkat tertaut** > logout perangkat bridge (kalau masih ada).
2. Jalankan `1-tautkan-whatsapp.bat` (otomatis menghentikan bridge latar belakang), scan QR, tunggu, Ctrl+C.
3. Jalankan `2-pasang-autostart.bat` lagi.

## 11. Build sendiri (opsional)

```powershell
winget install --id GoLang.Go -e
winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e
# buka terminal baru, lalu di folder repo:
powershell -ExecutionPolicy Bypass -File .\whatsapp-bridge\build.ps1
```

Kalau `wabridge.exe` sudah ada, langkah 4 tidak mengunduh apa pun.

## 12. Berhenti / hapus — `hapus.bat`

Menghentikan bridge, menghapus task, dan menghapus MCP dari Claude Code. Data chat **tidak** dihapus otomatis: hapus folder repo ini kalau mau bersih total, dan logout perangkat bridge dari HP.

## macOS?

Bagian Go/Python sama, tapi script `.bat`/Task Scheduler di sini khusus Windows. Di Mac: build dengan `CGO_ENABLED=1 go build -o wabridge .` (butuh Xcode Command Line Tools), jalankan sekali untuk scan QR, lalu pakai LaunchAgent dengan `KeepAlive` dan `WorkingDirectory` = folder `whatsapp-bridge`. Jangan taruh folder di `~/Documents`, `~/Desktop`, atau `~/Downloads` (privasi macOS bikin LaunchAgent gagal diam-diam). Daftarkan MCP dengan `claude mcp add whatsapp -s user -- $(which uv) --directory <path>/whatsapp-mcp-server run main.py`.

---

Kredit: [`lharries/whatsapp-mcp`](https://github.com/lharries/whatsapp-mcp) (MIT, lihat `LICENSE` dan `README.upstream.md`), pustaka [`whatsmeow`](https://github.com/tulir/whatsmeow). Tidak berafiliasi dengan WhatsApp/Meta atau Anthropic.
