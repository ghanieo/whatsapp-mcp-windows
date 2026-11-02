# Prints chat names + JIDs from the local messages.db so you can fill allowed_chats.txt.
# Read-only. Usage: cari_chat.py [search term]   (no term = 30 most recent chats)
import os
import sqlite3
import sys

DB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "whatsapp-bridge", "store", "messages.db")

if not os.path.exists(DB):
    sys.exit("messages.db belum ada. Jalankan 1-tautkan-whatsapp.bat dulu.")

term = " ".join(sys.argv[1:]).strip()
conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
sql = "SELECT jid, name, last_message_time FROM chats"
params = ()
if term:
    sql += " WHERE LOWER(name) LIKE LOWER(?) OR jid LIKE ?"
    params = (f"%{term}%", f"%{term}%")
sql += " ORDER BY datetime(last_message_time) DESC LIMIT 30"

rows = conn.execute(sql, params).fetchall()
if not rows:
    print("Tidak ada chat yang cocok. Coba potongan nomor HP (mis. 81234) atau nama grup.")
for jid, name, last in rows:
    print(f"{jid:<40} {str(name)[:35]:<35} {str(last)[:16]}")
print()
print("Salin JID (kolom kiri) ke whatsapp-mcp-server\\allowed_chats.txt, satu per baris.")
print("Chat pribadi bisa muncul 2x (...@s.whatsapp.net dan ...@lid): masukkan keduanya.")
