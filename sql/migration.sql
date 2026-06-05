-- ============================================================
-- UNDANGANKU.ID — Supabase Migration
-- Jalankan file ini di Supabase > SQL Editor > Run
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROFILES (extend auth.users Supabase)
-- ============================================================
CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  nama        TEXT,
  no_wa       TEXT,
  role        TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('admin','reseller','customer')),
  reseller_id UUID REFERENCES profiles(id),   -- siapa reseller yg daftarkan customer ini
  kode_ref    TEXT UNIQUE,                     -- kode referral reseller
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. PAKET
-- ============================================================
CREATE TABLE paket (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama        TEXT NOT NULL,           -- Basic, Premium, Royal
  harga       INTEGER NOT NULL,        -- dalam rupiah
  durasi_hari INTEGER NOT NULL,        -- masa aktif
  max_foto    INTEGER DEFAULT 10,
  max_tamu    INTEGER DEFAULT 100,
  fitur       JSONB DEFAULT '[]',      -- array fitur tambahan
  aktif       BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Insert paket default
INSERT INTO paket (nama, harga, durasi_hari, max_foto, max_tamu, fitur) VALUES
('Basic',   79000,  90,  10, 100,  '["RSVP","Ucapan","Countdown","Musik"]'),
('Premium', 149000, 180, 30, 500,  '["RSVP","Ucapan","Countdown","Musik","Galeri Video","Live Streaming Link","Custom Domain"]'),
('Royal',   249000, 365, 60, 2000, '["RSVP","Ucapan","Countdown","Musik","Galeri Video","Live Streaming Link","Custom Domain","Amplop Digital","Prioritas Support"]');

-- ============================================================
-- 3. UNDANGAN
-- ============================================================
CREATE TABLE undangan (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  slug            TEXT UNIQUE NOT NULL,         -- rezaninda → undanganku.id/rezaninda
  tema            INTEGER DEFAULT 1 CHECK (tema BETWEEN 1 AND 6),
  paket_id        UUID REFERENCES paket(id),
  status          TEXT DEFAULT 'draft' CHECK (status IN ('draft','aktif','expired')),

  -- Pengantin Pria
  nama_pria       TEXT,
  panggilan_pria  TEXT,
  foto_pria       TEXT,
  ayah_pria       TEXT,
  ibu_pria        TEXT,
  ig_pria         TEXT,
  tiktok_pria     TEXT,

  -- Pengantin Wanita
  nama_wanita     TEXT,
  panggilan_wanita TEXT,
  foto_wanita     TEXT,
  ayah_wanita     TEXT,
  ibu_wanita      TEXT,
  ig_wanita       TEXT,
  tiktok_wanita   TEXT,

  -- Foto bersama / cover
  foto_cover      TEXT,
  foto_galeri     JSONB DEFAULT '[]',   -- array URL foto

  -- Acara
  tanggal_akad    TIMESTAMPTZ,
  lokasi_akad     TEXT,
  maps_akad       TEXT,
  tanggal_resepsi TIMESTAMPTZ,
  lokasi_resepsi  TEXT,
  maps_resepsi    TEXT,
  jam_resepsi_mulai TEXT,
  jam_resepsi_selesai TEXT,

  -- Tanggal Hijriah
  tanggal_hijri   TEXT,

  -- Konten tambahan
  quotes          TEXT,
  musik_url       TEXT,
  amplop_bank     TEXT,
  amplop_norek    TEXT,
  amplop_atas_nama TEXT,

  -- Meta
  views           INTEGER DEFAULT 0,
  expired_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. TAMU
-- ============================================================
CREATE TABLE tamu (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  undangan_id UUID NOT NULL REFERENCES undangan(id) ON DELETE CASCADE,
  nama        TEXT NOT NULL,
  no_wa       TEXT,
  link        TEXT GENERATED ALWAYS AS (
    '/u/' || (SELECT slug FROM undangan WHERE id = undangan_id) || '?tamu=' || nama
  ) STORED,
  sudah_kirim BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. RSVP
-- ============================================================
CREATE TABLE rsvp (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  undangan_id UUID NOT NULL REFERENCES undangan(id) ON DELETE CASCADE,
  nama_tamu   TEXT NOT NULL,
  status      TEXT CHECK (status IN ('hadir','tidak','mungkin')),
  ucapan      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. PEMBAYARAN
-- ============================================================
CREATE TABLE pembayaran (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES profiles(id),
  undangan_id     UUID REFERENCES undangan(id),
  paket_id        UUID REFERENCES paket(id),
  reseller_id     UUID REFERENCES profiles(id),   -- jika order via reseller
  nominal         INTEGER NOT NULL,
  kode_ref        TEXT,                            -- kode reseller saat bayar
  metode          TEXT,                            -- midtrans / xendit / manual
  status          TEXT DEFAULT 'pending' CHECK (status IN ('pending','sukses','gagal','refund')),
  midtrans_order_id TEXT,
  midtrans_token  TEXT,
  bukti_url       TEXT,                            -- untuk transfer manual
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. KOMISI RESELLER
-- ============================================================
CREATE TABLE komisi (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reseller_id   UUID NOT NULL REFERENCES profiles(id),
  pembayaran_id UUID NOT NULL REFERENCES pembayaran(id),
  dari_user_id  UUID REFERENCES profiles(id),
  nominal       INTEGER NOT NULL,          -- nominal komisi (rupiah)
  persen        INTEGER DEFAULT 20,        -- persen komisi
  status        TEXT DEFAULT 'pending' CHECK (status IN ('pending','siap_cair','cair')),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. PENARIKAN KOMISI (withdraw request)
-- ============================================================
CREATE TABLE penarikan (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reseller_id UUID NOT NULL REFERENCES profiles(id),
  nominal     INTEGER NOT NULL,
  bank        TEXT,
  no_rek      TEXT,
  atas_nama   TEXT,
  status      TEXT DEFAULT 'request' CHECK (status IN ('request','proses','selesai','ditolak')),
  catatan     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. NOTIFIKASI
-- ============================================================
CREATE TABLE notifikasi (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  judul       TEXT NOT NULL,
  pesan       TEXT,
  dibaca      BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TRIGGERS — auto update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated   BEFORE UPDATE ON profiles   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_undangan_updated   BEFORE UPDATE ON undangan   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_pembayaran_updated BEFORE UPDATE ON pembayaran FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_penarikan_updated  BEFORE UPDATE ON penarikan  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TRIGGER — auto buat komisi saat pembayaran sukses
-- ============================================================
CREATE OR REPLACE FUNCTION buat_komisi_otomatis()
RETURNS TRIGGER AS $$
DECLARE
  v_reseller_id UUID;
  v_nominal     INTEGER;
  v_persen      INTEGER := 20;
BEGIN
  IF NEW.status = 'sukses' AND OLD.status != 'sukses' THEN
    -- Cari reseller dari kode_ref atau reseller_id langsung
    SELECT p.id INTO v_reseller_id
    FROM profiles p
    WHERE p.kode_ref = NEW.kode_ref AND p.role = 'reseller'
    LIMIT 1;

    IF v_reseller_id IS NULL THEN
      v_reseller_id := NEW.reseller_id;
    END IF;

    IF v_reseller_id IS NOT NULL THEN
      v_nominal := ROUND(NEW.nominal * v_persen / 100);
      INSERT INTO komisi (reseller_id, pembayaran_id, dari_user_id, nominal, persen, status)
      VALUES (v_reseller_id, NEW.id, NEW.user_id, v_nominal, v_persen, 'siap_cair');
    END IF;

    -- Update status undangan jadi aktif
    IF NEW.undangan_id IS NOT NULL THEN
      UPDATE undangan SET
        status = 'aktif',
        expired_at = NOW() + (SELECT durasi_hari || ' days' FROM paket WHERE id = NEW.paket_id)::INTERVAL
      WHERE id = NEW.undangan_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_komisi_otomatis
AFTER UPDATE ON pembayaran
FOR EACH ROW EXECUTE FUNCTION buat_komisi_otomatis();

-- ============================================================
-- TRIGGER — auto buat profile saat user register
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'customer');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_new_user
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE profiles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE undangan   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tamu       ENABLE ROW LEVEL SECURITY;
ALTER TABLE rsvp       ENABLE ROW LEVEL SECURITY;
ALTER TABLE pembayaran ENABLE ROW LEVEL SECURITY;
ALTER TABLE komisi     ENABLE ROW LEVEL SECURITY;
ALTER TABLE penarikan  ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifikasi ENABLE ROW LEVEL SECURITY;

-- Profiles: bisa lihat sendiri, admin lihat semua
CREATE POLICY "profiles_self" ON profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "profiles_admin" ON profiles FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Undangan: owner bisa semua, public bisa baca by slug (untuk halaman undangan)
CREATE POLICY "undangan_owner" ON undangan FOR ALL USING (user_id = auth.uid());
CREATE POLICY "undangan_public_read" ON undangan FOR SELECT USING (status = 'aktif');
CREATE POLICY "undangan_admin" ON undangan FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Tamu: owner undangan saja
CREATE POLICY "tamu_owner" ON tamu FOR ALL USING (
  undangan_id IN (SELECT id FROM undangan WHERE user_id = auth.uid())
);

-- RSVP: public bisa insert, owner bisa baca
CREATE POLICY "rsvp_public_insert" ON rsvp FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "rsvp_owner_read" ON rsvp FOR SELECT USING (
  undangan_id IN (SELECT id FROM undangan WHERE user_id = auth.uid())
);

-- Pembayaran: user lihat sendiri, admin lihat semua
CREATE POLICY "pembayaran_self" ON pembayaran FOR ALL USING (user_id = auth.uid());
CREATE POLICY "pembayaran_admin" ON pembayaran FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Komisi: reseller lihat sendiri, admin lihat semua
CREATE POLICY "komisi_self" ON komisi FOR SELECT USING (reseller_id = auth.uid());
CREATE POLICY "komisi_admin" ON komisi FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Penarikan: reseller sendiri + admin
CREATE POLICY "penarikan_self" ON penarikan FOR ALL USING (reseller_id = auth.uid());
CREATE POLICY "penarikan_admin" ON penarikan FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Notifikasi: milik sendiri
CREATE POLICY "notifikasi_self" ON notifikasi FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- VIEWS — shortcut query berguna
-- ============================================================

-- Ringkasan komisi per reseller
CREATE VIEW v_saldo_reseller AS
SELECT
  reseller_id,
  SUM(CASE WHEN status = 'siap_cair' THEN nominal ELSE 0 END) AS saldo,
  SUM(nominal) AS total_komisi,
  COUNT(*) AS total_transaksi
FROM komisi
GROUP BY reseller_id;

-- Ringkasan admin dashboard
CREATE VIEW v_admin_summary AS
SELECT
  (SELECT COUNT(*) FROM profiles WHERE role = 'customer') AS total_customer,
  (SELECT COUNT(*) FROM profiles WHERE role = 'reseller') AS total_reseller,
  (SELECT COUNT(*) FROM undangan WHERE status = 'aktif') AS undangan_aktif,
  (SELECT COALESCE(SUM(nominal),0) FROM pembayaran WHERE status = 'sukses'
   AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW())) AS pendapatan_bulan_ini,
  (SELECT COUNT(*) FROM penarikan WHERE status = 'request') AS penarikan_pending;

-- ============================================================
-- STORAGE BUCKETS (jalankan di Dashboard > Storage)
-- ============================================================
-- Buat bucket berikut di Supabase Dashboard > Storage:
-- 1. "foto-undangan"  → public
-- 2. "musik"          → public  
-- 3. "bukti-bayar"    → private

-- ============================================================
-- DONE. Lanjut ke Authentication:
-- Dashboard > Authentication > Providers > Enable Google
-- Masukkan Google OAuth Client ID & Secret
-- Redirect URL: https://[project].supabase.co/auth/v1/callback
-- ============================================================
