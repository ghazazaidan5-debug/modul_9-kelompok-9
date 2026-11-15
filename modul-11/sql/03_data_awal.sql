-- ============================================================
-- 03_data_awal.sql
-- Data awal. SEMUA DATA FIKTIF. Jangan memasukkan data pribadi nyata.
-- ============================================================
USE bukuku_modul11;

-- ------------------------------------------------------------
-- (A) Data inti BUKUKU (distributor bumbu dapur)
--     Stok TIDAK diisi manual; stok terbentuk dari trigger
--     saat barang masuk, barang keluar, dan retur dicatat.
-- ------------------------------------------------------------
-- password_hash di bawah hanya PENGISI. Di aplikasi nyata simpan hash bcrypt/argon2
-- dari password yang diatur sendiri dan JANGAN commit kredensial asli ke Git.
INSERT INTO pengguna (id_pengguna, nama, role, username, password_hash) VALUES
(1, 'Budi Santoso',   'Owner',        'owner',  'HASH_CONTOH_BUKAN_PASSWORD_ASLI_1'),
(2, 'Sari Wulandari', 'Admin Gudang', 'admin1', 'HASH_CONTOH_BUKAN_PASSWORD_ASLI_2');

INSERT INTO pabrik (id_pabrik, nama_pabrik, kontak_sales, no_hp) VALUES
(1, 'PT Sumber Pangan Nusantara', 'Pak Rudi',   '0812-0000-0001'),
(2, 'CV Kecap Jaya Abadi',        'Bu Lilis',   '0812-0000-0002'),
(3, 'UD Bawang Emas',             'Pak Hendra', '0812-0000-0003'),
(4, 'PT Rasa Gurih Makmur',       'Bu Dewi',    '0812-0000-0004');

INSERT INTO barang (id_barang, nama_barang, satuan, stok_minimal) VALUES
(1, 'Tepung Terigu 25 kg', 'sak',    20),
(2, 'Kecap Asin 620 ml',   'karton', 15),
(3, 'Bawang Goreng 500 g', 'dus',    10),
(4, 'Penyedap Rasa Ayam',  'karton', 12);

INSERT INTO toko_cabang (id_toko, nama_toko, nama_pemilik, alamat, no_hp, jenis_toko, status_tempo) VALUES
(1, 'Toko Sumber Rejeki', 'Bu Siti',    'Jl. Kenanga No. 5, Madiun',   '0813-0000-0001', 'Toko Kelontong', 0),
(2, 'Warung Barokah',     'Pak Slamet', 'Jl. Melati No. 12, Madiun',   '0813-0000-0002', 'Warung',         1),
(3, 'Toko Maju Jaya',     'Pak Anton',  'Jl. Pahlawan No. 21, Magetan','0813-0000-0003', 'Toko Kelontong', 0);

-- Barang masuk (nota dari pabrik)
INSERT INTO barang_masuk (id_masuk, no_nota, tanggal, id_pabrik, id_pengguna) VALUES
(1, 'INV-2026-0001', '2026-11-02', 1, 2),
(2, 'INV-2026-0002', '2026-11-03', 2, 2),
(3, 'INV-2026-0003', '2026-11-04', 3, 2),
(4, 'INV-2026-0004', '2026-11-05', 4, 2),
(5, 'INV-2026-0005', '2026-11-09', 1, 2);   -- harga tepung naik

INSERT INTO detail_barang_masuk (id_masuk, id_barang, jumlah, harga_beli) VALUES
(1, 1, 100, 185000),
(2, 2,  60, 210000),
(3, 3,  40, 320000),
(4, 4,  50, 275000),
(5, 1,  50, 190000);

-- Barang keluar (surat jalan ke toko)
INSERT INTO barang_keluar (id_keluar, no_surat_jalan, tanggal, status_konfirmasi, id_toko, id_pengguna) VALUES
(1, 'SJ-2026-0001', '2026-11-06', 1, 1, 2),
(2, 'SJ-2026-0002', '2026-11-07', 1, 2, 2),
(3, 'SJ-2026-0003', '2026-11-10', 0, 3, 2);   -- belum dikonfirmasi (dipakai untuk uji KF-04)

INSERT INTO detail_barang_keluar (id_keluar, id_barang, jumlah, harga_jual) VALUES
(1, 1, 30, 205000),
(1, 2, 20, 235000),
(2, 1, 25, 205000),
(2, 3, 15, 350000),
(3, 2, 10, 235000),
(3, 4, 20, 300000),
(3, 1, 90, 210000);

-- Retur
INSERT INTO retur (jenis_retur, tanggal, id_barang, jumlah, alasan, no_nota_asal, status_layak_jual, id_pabrik, id_toko) VALUES
('KE_PABRIK', '2026-11-08', 2, 5, 'cacat',      'INV-2026-0002', NULL, 2, NULL),
('DARI_TOKO', '2026-11-11', 3, 2, 'tidak laku', NULL,            1,    NULL, 2),
('DARI_TOKO', '2026-11-11', 2, 3, 'rusak',      NULL,            0,    NULL, 1);


SELECT id_barang, nama_barang, jumlah_stok, stok_rusak FROM barang;

-- ------------------------------------------------------------
-- (B) Data untuk latihan JSON (Tahap 3 modul), dengan data BUKUKU
--     Setiap jenis barang punya atribut JSON yang BERBEDA.
-- ------------------------------------------------------------
INSERT INTO jenis_barang (nama_jenis)
VALUES
    ('Tepung'),
    ('Kecap'),
    ('Bawang Goreng'),
    ('Penyedap Rasa');

SELECT * FROM jenis_barang;

-- Barang 1: Tepung Terigu 25 kg
INSERT INTO barang_spesifikasi (id_barang, id_jenis, spesifikasi)
VALUES (
    1, 1,
    '{
        "merek": "Tepung Rejeki",
        "berat_kg": 25,
        "kadar_protein": "12%",
        "kemasan": "karung"
    }'
);

-- Barang 2: Kecap Asin 620 ml
INSERT INTO barang_spesifikasi (id_barang, id_jenis, spesifikasi)
VALUES (
    2, 2,
    '{
        "volume_ml": 620,
        "isi_per_karton": 12,
        "bahan": "kedelai",
        "kemasan": "botol",
        "label": ["Halal"]
    }'
);

-- Barang 3: Bawang Goreng 500 g
INSERT INTO barang_spesifikasi (id_barang, id_jenis, spesifikasi)
VALUES (
    3, 3,
    '{
        "berat_gram": 500,
        "isi_per_dus": 20,
        "masa_simpan_bulan": 6,
        "kemasan": "plastik"
    }'
);

-- Barang 4: Penyedap Rasa Ayam
INSERT INTO barang_spesifikasi (id_barang, id_jenis, spesifikasi)
VALUES (
    4, 4,
    '{
        "rasa": "ayam",
        "berat_gram": 250,
        "isi_per_karton": 10,
        "kemasan": "plastik",
        "label": ["Halal", "BPOM"]
    }'
);

SELECT * FROM barang_spesifikasi;

-- ------------------------------------------------------------
-- (C) Data untuk latihan pemetaan objek (Tahap 4 modul)
--     Transaksi (induk) -> BarangMasuk / BarangKeluar / Retur (turunan)
-- ------------------------------------------------------------
INSERT INTO transaksi_objek (no_dokumen, jenis_transaksi, tanggal, atribut)
VALUES
(
    'INV-2026-0001', 'BarangMasuk', '2026-11-02',
    '{"id_pabrik": 1, "id_pengguna": 2, "jumlah_jenis_barang": 1}'
),
(
    'SJ-2026-0001', 'BarangKeluar', '2026-11-06',
    '{"id_toko": 1, "id_pengguna": 2, "status_konfirmasi": true, "jumlah_jenis_barang": 2}'
),
(
    'RETUR-2026-0001', 'Retur', '2026-11-08',
    '{"jenis_retur": "KE_PABRIK", "id_barang": 2, "jumlah": 5, "alasan": "cacat", "no_nota_asal": "INV-2026-0002"}'
);
