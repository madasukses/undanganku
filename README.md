# Undanganku.id — Panduan Deploy

## Struktur File
```
/
├── index.html              ← Landing page (TODO)
├── login.html              ← Login Google
├── auth-callback.html      ← Handler OAuth redirect
├── vercel.json             ← Routing config
├── js/
│   ├── supabase.js         ← Supabase client (ISI URL & KEY)
│   └── auth.js             ← Auth helper
├── admin/
│   └── dashboard.html      ← Dashboard admin
├── reseller/
│   └── dashboard.html      ← Dashboard reseller
├── customer/
│   └── dashboard.html      ← Dashboard customer
├── themes/
│   └── undangan.html       ← Template undangan (6 tema)
└── sql/
    └── migration.sql       ← Jalankan di Supabase
```

---

## Step 1 — Supabase

1. Buat project baru di https://supabase.com
2. Masuk ke **SQL Editor**
3. Paste isi `sql/migration.sql` → klik **Run**
4. Masuk ke **Authentication > Providers**
   - Enable **Google**
   - Masukkan Google OAuth Client ID & Secret
   - Redirect URL: `https://[project-id].supabase.co/auth/v1/callback`
5. Masuk ke **Storage** → buat 3 bucket:
   - `foto-undangan` → Public
   - `musik` → Public
   - `bukti-bayar` → Private
6. Masuk ke **Settings > API** → copy:
   - Project URL
   - anon/public key

---

## Step 2 — Edit supabase.js

Buka `js/supabase.js`, ganti:
```js
const SUPABASE_URL  = 'https://XXXXXXXX.supabase.co';
const SUPABASE_ANON = 'eyXXXXXXXXXXXXX...';
```

---

## Step 3 — GitHub

```bash
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/USERNAME/undanganku.git
git push -u origin main
```

---

## Step 4 — Vercel

1. Buka https://vercel.com → New Project
2. Import repo GitHub tadi
3. **Framework Preset**: Other
4. **Build Command**: kosongkan
5. **Output Directory**: kosongkan (root)
6. Klik **Deploy**

### Environment Variables di Vercel (opsional, lebih aman):
Tidak diperlukan untuk sekarang karena pakai anon key di frontend.
Nanti saat ada server-side (Midtrans webhook dll), tambahkan di Settings > Environment Variables.

---

## Step 5 — Google OAuth Setup

1. Buka https://console.cloud.google.com
2. Buat project baru
3. APIs & Services → Credentials → Create OAuth 2.0 Client ID
4. Application type: Web
5. Authorized redirect URIs:
   - `https://[project-id].supabase.co/auth/v1/callback`
6. Copy Client ID & Secret ke Supabase Auth > Google provider

---

## Step 6 — Set Role Admin Manual

Setelah pertama kali login dengan Google, jalankan di Supabase SQL Editor:

```sql
UPDATE profiles SET role = 'admin' WHERE email = 'emailkamu@gmail.com';
```

---

## Alur URL

| URL | Halaman |
|-----|---------|
| `undanganku.id/login` | Login Google |
| `undanganku.id/admin/dashboard` | Dashboard admin |
| `undanganku.id/reseller/dashboard` | Dashboard reseller |
| `undanganku.id/customer/dashboard` | Dashboard customer |
| `undanganku.id/rezaninda` | Halaman undangan (slug) |
| `undanganku.id/rezaninda?tamu=Budi` | Undangan atas nama Budi |

---

## Komisi Reseller

- Saat pembayaran sukses → trigger otomatis hitung 20% komisi
- Komisi masuk ke tabel `komisi` dengan status `siap_cair`
- Reseller lihat saldo di dashboard → klik "Tarik Saldo"
- Admin approve di dashboard → transfer manual ke rekening reseller
- Update status penarikan ke `selesai`

---

## 6 Tema Template

| Tema | Nama | Warna |
|------|------|-------|
| 1 | Classic Gold | Dark brown + emas |
| 2 | Rose Garden | Pink blush |
| 3 | Emerald | Hijau gelap |
| 4 | Midnight Blue | Biru gelap |
| 5 | Cream & Sage | Krem terang (light) |
| 6 | Dusty Mauve | Ungu keabu-abuan |

Ganti tema di dashboard customer → field `tema` di tabel `undangan` (angka 1-6).

---

## Paywall

- Tamu buka undangan → progress bar 10 detik berjalan
- Setelah 10 detik → popup paywall muncul
- Jika sudah bayar → cek Supabase → paywall tidak muncul
- Popup bisa ditutup ("Lihat dulu") tapi muncul lagi tiap 30 detik
