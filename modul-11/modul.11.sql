# ============================================================
# DATABASE BUKUKU
# Berdasarkan SKPL Sistem Pembukuan Gudang BUKUKU sebelumnya yang kita buat
# DBMS: MySQL / MariaDB (XAMPP, phpMyAdmin)
# ============================================================

CREATE DATABASE IF NOT EXISTS db_bukuku
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_bukuku;

# 1. Tabel PABRIK
CREATE TABLE IF NOT EXISTS pabrik (
    id_pabrik INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_pabrik VARCHAR(100) NOT NULL,
    kontak_sales VARCHAR(100),
    no_hp VARCHAR(20)
) ENGINE=InnoDB;

# 2. Tabel BARANG
CREATE TABLE IF NOT EXISTS barang (
    id_barang INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_barang VARCHAR(100) NOT NULL,
    satuan VARCHAR(30) NOT NULL,
    stok_minimal INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_stok INT UNSIGNED NOT NULL DEFAULT 0,
    stok_rusak INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

# 3. Tabel TOKO_CABANG
CREATE TABLE IF NOT EXISTS toko_cabang (
    id_toko INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_toko VARCHAR(100) NOT NULL,
    nama_pemilik VARCHAR(100),
    alamat TEXT,
    no_hp VARCHAR(20),
    jenis_toko VARCHAR(50),
    status_tempo BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

# 4. Tabel PENGGUNA
CREATE TABLE IF NOT EXISTS pengguna (
    id_pengguna INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    `role` ENUM('ADMIN_GUDANG', 'OWNER') NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

# 5. Tabel BARANG_MASUK
# Satu transaksi barang masuk berasal dari satu pabrik
# dan dicatat oleh satu pengguna.
CREATE TABLE IF NOT EXISTS barang_masuk (
    id_masuk INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    no_nota VARCHAR(50) NOT NULL,
    tanggal DATE NOT NULL,
    id_pabrik INT UNSIGNED NOT NULL,
    id_pengguna INT UNSIGNED NOT NULL,
    CONSTRAINT uq_barang_masuk_no_nota UNIQUE (no_nota),
    CONSTRAINT fk_masuk_pabrik
        FOREIGN KEY (id_pabrik) REFERENCES pabrik(id_pabrik)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_masuk_pengguna
        FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

# 6. Tabel DETAIL_BARANG_MASUK
# Menyimpan barang, jumlah, dan harga beli per nota.
CREATE TABLE IF NOT EXISTS detail_barang_masuk (
    id_detail_masuk INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_masuk INT UNSIGNED NOT NULL,
    id_barang INT UNSIGNED NOT NULL,
    jumlah INT UNSIGNED NOT NULL,
    harga_beli DECIMAL(15,2) UNSIGNED NOT NULL,
    CONSTRAINT uq_detail_masuk_barang UNIQUE (id_masuk, id_barang),
    CONSTRAINT fk_detail_masuk_header
        FOREIGN KEY (id_masuk) REFERENCES barang_masuk(id_masuk)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_detail_masuk_barang
        FOREIGN KEY (id_barang) REFERENCES barang(id_barang)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

# 7. Tabel BARANG_KELUAR
# Satu transaksi pengiriman ditujukan ke satu toko
# dan dicatat oleh satu pengguna.
CREATE TABLE IF NOT EXISTS barang_keluar (
    id_keluar INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    no_surat_jalan VARCHAR(50) NOT NULL,
    tanggal DATE NOT NULL,
    status_konfirmasi BOOLEAN NOT NULL DEFAULT FALSE,
    id_toko INT UNSIGNED NOT NULL,
    id_pengguna INT UNSIGNED NOT NULL,
    CONSTRAINT uq_barang_keluar_no_surat UNIQUE (no_surat_jalan),
    CONSTRAINT fk_keluar_toko
        FOREIGN KEY (id_toko) REFERENCES toko_cabang(id_toko)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_keluar_pengguna
        FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

# 8. Tabel DETAIL_BARANG_KELUAR
# Menyimpan barang, jumlah, dan harga jual per pengiriman.
CREATE TABLE IF NOT EXISTS detail_barang_keluar (
    id_detail_keluar INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_keluar INT UNSIGNED NOT NULL,
    id_barang INT UNSIGNED NOT NULL,
    jumlah INT UNSIGNED NOT NULL,
    harga_jual DECIMAL(15,2) UNSIGNED NOT NULL,
    CONSTRAINT uq_detail_keluar_barang UNIQUE (id_keluar, id_barang),
    CONSTRAINT fk_detail_keluar_header
        FOREIGN KEY (id_keluar) REFERENCES barang_keluar(id_keluar)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_detail_keluar_barang
        FOREIGN KEY (id_barang) REFERENCES barang(id_barang)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

# 9. Tabel RETUR
# jenis_retur:
# KE_PABRIK  = barang dikembalikan dari gudang ke pabrik
# DARI_TOKO  = barang dikembalikan dari toko ke gudang
# Untuk KE_PABRIK, isi id_pabrik dan kosongkan id_toko.
# Untuk DARI_TOKO, isi id_toko dan kosongkan id_pabrik.
# status_layak_jual diisi untuk retur DARI_TOKO.
CREATE TABLE IF NOT EXISTS retur (
    id_retur INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    jenis_retur ENUM('KE_PABRIK', 'DARI_TOKO') NOT NULL,
    jumlah INT UNSIGNED NOT NULL,
    alasan VARCHAR(255) NOT NULL,
    tanggal DATE NOT NULL,
    status_layak_jual BOOLEAN NULL,
    no_nota_asal VARCHAR(50) NULL,
    id_barang INT UNSIGNED NOT NULL,
    id_pabrik INT UNSIGNED NULL,
    id_toko INT UNSIGNED NULL,
    CONSTRAINT fk_retur_barang
        FOREIGN KEY (id_barang) REFERENCES barang(id_barang)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_retur_pabrik
        FOREIGN KEY (id_pabrik) REFERENCES pabrik(id_pabrik)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_retur_toko
        FOREIGN KEY (id_toko) REFERENCES toko_cabang(id_toko)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_retur_pihak CHECK (
        (jenis_retur = 'KE_PABRIK' AND id_pabrik IS NOT NULL AND id_toko IS NULL)
        OR
        (jenis_retur = 'DARI_TOKO' AND id_toko IS NOT NULL AND id_pabrik IS NULL)
    ),
    CONSTRAINT chk_retur_status_layak CHECK (
        (jenis_retur = 'KE_PABRIK' AND status_layak_jual IS NULL)
        OR
        (jenis_retur = 'DARI_TOKO' AND status_layak_jual IS NOT NULL)
    )
) ENGINE=InnoDB;

# 10. Tabel LOG_AKTIVITAS
# Mencatat pengguna, aksi, tabel yang diubah, ID record,
# dan waktu aktivitas. Isi sebelum/sesudah perubahan
# memang tidak disimpan sesuai batasan SKPL.
CREATE TABLE IF NOT EXISTS log_aktivitas (
    id_log BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_pengguna INT UNSIGNED NOT NULL,
    aksi ENUM('UBAH', 'HAPUS') NOT NULL,
    tabel_target VARCHAR(64) NOT NULL,
    id_record VARCHAR(64) NOT NULL,
    waktu DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_pengguna
        FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

# ============================================================
# SELESAI
# Catatan:
# 1. Script ini membuat struktur database, belum mengisi data.
# 2. Stok barang perlu diperbarui oleh proses aplikasi/transaksi.
# 3. Hak akses Owner/Admin dan pencatatan log perlu diterapkan
# pada program aplikasi (atau trigger, jika diminta dosen).
# 4. Gunakan password_hash untuk menyimpan hasil hash password,
# bukan password asli.
# ============================================================


#percobaan untuk json

-- CREATE DATABASE IF NOT EXISTS bukuku_modul11
--     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
use db_bukuku;

SHOW DATABASES;

#script yag digunakan untuk membuat tabel pada sistem bukuku

CREATE TABLE jenis_barang (
    id_jenis   INT AUTO_INCREMENT PRIMARY KEY,
    nama_jenis VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE barang_spesifikasi (
    id_barang   INT PRIMARY KEY,
    id_jenis    INT NOT NULL,
    spesifikasi JSON NOT NULL,

    CONSTRAINT fk_spesifikasi_barang FOREIGN KEY (id_barang) REFERENCES barang(id_barang),
    CONSTRAINT fk_spesifikasi_jenis  FOREIGN KEY (id_jenis)  REFERENCES jenis_barang(id_jenis)
) ENGINE=InnoDB;

CREATE TABLE transaksi_objek (
    id_transaksi    INT AUTO_INCREMENT PRIMARY KEY,
    no_dokumen      VARCHAR(30) NOT NULL,
    jenis_transaksi VARCHAR(30) NOT NULL,   
    tanggal         DATE NOT NULL,
    atribut         JSON
) ENGINE=InnoDB;

# (C) TRIGGER: menjaga stok otomatis (stored program)
DELIMITER $$

# KF-02: barang masuk -> stok bertambah
CREATE TRIGGER trg_detail_masuk_ai
AFTER INSERT ON detail_barang_masuk
FOR EACH ROW
BEGIN
    UPDATE barang
    SET jumlah_stok = jumlah_stok + NEW.jumlah
    WHERE id_barang = NEW.id_barang;
END$$

# KF-03: barang keluar ditolak bila stok kurang (stok tidak boleh minus)
CREATE TRIGGER trg_detail_keluar_bi
BEFORE INSERT ON detail_barang_keluar
FOR EACH ROW
BEGIN
    DECLARE v_stok  INT DEFAULT 0;
    DECLARE v_pesan VARCHAR(100);

    SELECT jumlah_stok INTO v_stok
    FROM barang
    WHERE id_barang = NEW.id_barang;

    IF v_stok < NEW.jumlah THEN
        SET v_pesan = CONCAT('Stok tidak cukup. Sisa stok: ', v_stok);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_pesan;
    END IF;
END$$

# KF-03: barang keluar -> stok berkurang
CREATE TRIGGER trg_detail_keluar_ai
AFTER INSERT ON detail_barang_keluar
FOR EACH ROW
BEGIN
    UPDATE barang
    SET jumlah_stok = jumlah_stok - NEW.jumlah
    WHERE id_barang = NEW.id_barang;
END$$

# KF-05: retur ke pabrik tidak boleh melebihi stok
CREATE TRIGGER trg_retur_bi
BEFORE INSERT ON retur
FOR EACH ROW
BEGIN
    DECLARE v_stok  INT DEFAULT 0;
    DECLARE v_pesan VARCHAR(100);

    IF NEW.jenis_retur = 'KE_PABRIK' THEN
        SELECT jumlah_stok INTO v_stok
        FROM barang
        WHERE id_barang = NEW.id_barang;

        IF v_stok < NEW.jumlah THEN
            SET v_pesan = CONCAT('Retur ditolak. Sisa stok: ', v_stok);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_pesan;
        END IF;
    END IF;
END$$

# KF-05: penyesuaian stok setelah retur
# ke pabrik            -> stok layak jual berkurang
# dari toko, layak jual -> stok layak jual bertambah
# dari toko, rusak      -> stok rusak bertambah (tidak ikut stok jual)
CREATE TRIGGER trg_retur_ai
AFTER INSERT ON retur
FOR EACH ROW
BEGIN
    IF NEW.jenis_retur = 'KE_PABRIK' THEN
        UPDATE barang
        SET jumlah_stok = jumlah_stok - NEW.jumlah
        WHERE id_barang = NEW.id_barang;
    ELSEIF NEW.status_layak_jual = 1 THEN
        UPDATE barang
        SET jumlah_stok = jumlah_stok + NEW.jumlah
        WHERE id_barang = NEW.id_barang;
    ELSE
        UPDATE barang
        SET stok_rusak = stok_rusak + NEW.jumlah
        WHERE id_barang = NEW.id_barang;
    END IF;
END$$

DELIMITER ;

#laporan

# KF-06 dan KF-08: laporan stok + penanda stok menipis
CREATE VIEW v_laporan_stok AS
SELECT
    id_barang,
    nama_barang,
    satuan,
    stok_minimal,
    jumlah_stok,
    stok_rusak,
    CASE WHEN jumlah_stok < stok_minimal THEN 'MENIPIS' ELSE 'AMAN' END AS status_stok
FROM barang;

CREATE VIEW v_stok_menipis AS
SELECT * FROM v_laporan_stok WHERE status_stok = 'MENIPIS';

# KF-08: harga beli diambil dari nota barang masuk TERAKHIR untuk tiap barang
CREATE VIEW v_harga_beli_terakhir AS
SELECT id_barang, harga_beli
FROM (
    SELECT
        d.id_barang,
        d.harga_beli,
        ROW_NUMBER() OVER (
            PARTITION BY d.id_barang
            ORDER BY m.tanggal DESC, m.id_masuk DESC, d.id_detail_masuk DESC
        ) AS urutan
    FROM detail_barang_masuk d
    JOIN barang_masuk m ON m.id_masuk = d.id_masuk
) AS t
WHERE urutan = 1;

# KF-08: untung = (harga jual - harga beli) x jumlah  (hanya untuk Owner)
CREATE VIEW v_laporan_untung_rugi AS
SELECT
    k.tanggal,
    k.no_surat_jalan,
    t.nama_toko,
    b.nama_barang,
    dk.jumlah,
    h.harga_beli,
    dk.harga_jual,
    (dk.harga_jual - h.harga_beli) * dk.jumlah AS untung
FROM detail_barang_keluar dk
JOIN barang_keluar k ON k.id_keluar = dk.id_keluar
JOIN toko_cabang  t ON t.id_toko   = k.id_toko
JOIN barang       b ON b.id_barang = dk.id_barang
JOIN v_harga_beli_terakhir h ON h.id_barang = dk.id_barang;

# (A) Data inti BUKUKU (distributor bumbu dapur)
# Stok TIDAK diisi manual; stok terbentuk dari trigger
# saat barang masuk, barang keluar, dan retur dicatat.
# password_hash di bawah hanya PENGISI. Di aplikasi nyata simpan hash bcrypt/argon2
# dari password yang diatur sendiri dan JANGAN commit kredensial asli ke Git.
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

# Barang masuk (nota dari pabrik)
INSERT INTO barang_masuk (id_masuk, no_nota, tanggal, id_pabrik, id_pengguna) VALUES
(1, 'INV-2026-0001', '2026-11-02', 1, 2),
(2, 'INV-2026-0002', '2026-11-03', 2, 2),
(3, 'INV-2026-0003', '2026-11-04', 3, 2),
(4, 'INV-2026-0004', '2026-11-05', 4, 2),
(5, 'INV-2026-0005', '2026-11-09', 1, 2); # harga tepung naik

INSERT INTO detail_barang_masuk (id_masuk, id_barang, jumlah, harga_beli) VALUES
(1, 1, 100, 185000),
(2, 2,  60, 210000),
(3, 3,  40, 320000),
(4, 4,  50, 275000),
(5, 1,  50, 190000);

# Barang keluar (surat jalan ke toko)
INSERT INTO barang_keluar (id_keluar, no_surat_jalan, tanggal, status_konfirmasi, id_toko, id_pengguna) VALUES
(1, 'SJ-2026-0001', '2026-11-06', 1, 1, 2),
(2, 'SJ-2026-0002', '2026-11-07', 1, 2, 2),
(3, 'SJ-2026-0003', '2026-11-10', 0, 3, 2); # belum dikonfirmasi (dipakai untuk uji KF-04)

INSERT INTO detail_barang_keluar (id_keluar, id_barang, jumlah, harga_jual) VALUES
(1, 1, 30, 205000),
(1, 2, 20, 235000),
(2, 1, 25, 205000),
(2, 3, 15, 350000),
(3, 2, 10, 235000),
(3, 4, 20, 300000),
(3, 1, 90, 210000);

# Retur
INSERT INTO retur (jenis_retur, tanggal, id_barang, jumlah, alasan, no_nota_asal, status_layak_jual, id_pabrik, id_toko) VALUES
('KE_PABRIK', '2026-11-08', 2, 5, 'cacat',      'INV-2026-0002', NULL, 2, NULL),
('DARI_TOKO', '2026-11-11', 3, 2, 'tidak laku', NULL,            1,    NULL, 2),
('DARI_TOKO', '2026-11-11', 2, 3, 'rusak',      NULL,            0,    NULL, 1);


SELECT id_barang, nama_barang, jumlah_stok, stok_rusak FROM barang;

# (B) Data untuk latihan JSON (Tahap 3 modul), dengan data BUKUKU
# Setiap jenis barang punya atribut JSON yang BERBEDA.
INSERT INTO jenis_barang (nama_jenis)
VALUES
    ('Tepung'),
    ('Kecap'),
    ('Bawang Goreng'),
    ('Penyedap Rasa');

SELECT * FROM jenis_barang;

# Barang 1: Tepung Terigu 25 kg
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

# Barang 2: Kecap Asin 620 ml
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

# Barang 3: Bawang Goreng 500 g
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

# Barang 4: Penyedap Rasa Ayam
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

# (C) Data untuk latihan pemetaan objek (Tahap 4 modul)
# Transaksi (induk) -> BarangMasuk / BarangKeluar / Retur (turunan)
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


# ============================================================
# 1. IDENTIFIKASI DBMS
# ============================================================

# 1.1 Nama, versi, dan jenis DBMS
SELECT VERSION();
SELECT @@version_comment;

# 1.2 Database, storage engine, karakter set
SHOW DATABASES;
SHOW ENGINES; # InnoDB: Support = DEFAULT, Transactions = YES
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';

# 1.3 Dukungan fungsi JSON
SELECT
    JSON_VALID('{"nama":"Budi"}')               AS json_valid,
    JSON_EXTRACT('{"nama":"Budi"}', '$.nama')   AS nama;
# Hasil diharapkan: json_valid = 1 | nama = "Budi"

# 1.4 Informasi server
SELECT NOW();
SELECT DATABASE(); # bukuku_modul11

# 1.5 Fasilitas transaksi (START TRANSACTION, ROLLBACK)
START TRANSACTION;
    UPDATE barang SET stok_minimal = 999 WHERE id_barang = 1;
    SELECT id_barang, nama_barang, stok_minimal FROM barang WHERE id_barang = 1;

ROLLBACK;
SELECT id_barang, nama_barang, stok_minimal FROM barang WHERE id_barang = 1;


# ============================================================
# 2. READ - membaca atribut JSON (SELECT)
# ============================================================

# 2.1 Membaca satu atribut: kemasan
SELECT b.nama_barang, JSON_EXTRACT(s.spesifikasi, '$.kemasan') AS kemasan
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;

# 2.2 Membaca atribut yang tidak dimiliki semua barang: isi_per_karton
SELECT b.nama_barang, JSON_EXTRACT(s.spesifikasi, '$.isi_per_karton') AS isi_per_karton
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;

# 2.3 Membaca atribut lain: berat_gram
SELECT b.nama_barang, JSON_EXTRACT(s.spesifikasi, '$.berat_gram') AS berat_gram
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;

# 2.4 Mencari barang berdasarkan nilai atribut
SELECT b.nama_barang, b.satuan
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kadar_protein')) = '12%';

SELECT b.nama_barang, b.jumlah_stok
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kemasan')) = 'plastik';

# 2.5 Mencari di dalam array JSON (label)
SELECT b.nama_barang
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_CONTAINS(JSON_EXTRACT(s.spesifikasi, '$.label'), '"BPOM"') = 1;


# ============================================================
# 3. UPDATE - mengubah atribut JSON (JSON_SET)
# Kasus: kadar protein tepung berubah dari 12% menjadi 13%
# ============================================================

UPDATE barang_spesifikasi
SET spesifikasi = JSON_SET(spesifikasi, '$.kadar_protein', '13%')
WHERE id_barang = 1;

# Periksa hasil
SELECT id_barang, JSON_EXTRACT(spesifikasi, '$.kadar_protein') AS kadar_protein
FROM barang_spesifikasi
WHERE id_barang = 1;

# Pencarian setelah perubahan
SELECT b.nama_barang
FROM barang_spesifikasi s JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kadar_protein')) = '13%';

SELECT b.nama_barang
FROM barang_spesifikasi s JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kadar_protein')) = '12%';


# ============================================================
# 4. UPDATE - menambah atribut baru (JSON_SET dan JSON_ARRAY_APPEND)
# ============================================================

# 4.1 JSON_SET pada key yang belum ada: atribut baru ditambahkan
# Kasus: tepung mendapat atribut pemasok_utama
UPDATE barang_spesifikasi
SET spesifikasi = JSON_SET(spesifikasi, '$.pemasok_utama', 'PT Sumber Pangan Nusantara')
WHERE id_barang = 1;

SELECT id_barang, spesifikasi FROM barang_spesifikasi WHERE id_barang = 1;

# 4.2 JSON_ARRAY_APPEND: menambah elemen ke array yang sudah ada
# Kasus: kecap mendapat label baru "BPOM" pada array label
UPDATE barang_spesifikasi
SET spesifikasi = JSON_ARRAY_APPEND(spesifikasi, '$.label', 'BPOM')
WHERE id_barang = 2;

SELECT id_barang, JSON_EXTRACT(spesifikasi, '$.label') AS label
FROM barang_spesifikasi
WHERE id_barang = 2;

# Periksa lewat pencarian array
SELECT b.nama_barang
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_CONTAINS(JSON_EXTRACT(s.spesifikasi, '$.label'), '"BPOM"') = 1;


# ============================================================
# 5. DELETE - menghapus atribut JSON (JSON_REMOVE)
# ============================================================

# 5.1 Menghapus satu atribut: pemasok_utama pada tepung
UPDATE barang_spesifikasi
SET spesifikasi = JSON_REMOVE(spesifikasi, '$.pemasok_utama')
WHERE id_barang = 1;

SELECT id_barang, spesifikasi FROM barang_spesifikasi WHERE id_barang = 1;

# 5.2 Menghapus satu elemen array: label "BPOM" pada kecap (elemen ke-2, indeks 1)
UPDATE barang_spesifikasi
SET spesifikasi = JSON_REMOVE(spesifikasi, '$.label[1]')
WHERE id_barang = 2;

SELECT id_barang, JSON_EXTRACT(spesifikasi, '$.label') AS label
FROM barang_spesifikasi
WHERE id_barang = 2;

# Hanya penyedap yang berlabel BPOM lagi
SELECT b.nama_barang
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_CONTAINS(JSON_EXTRACT(s.spesifikasi, '$.label'), '"BPOM"') = 1;


# ============================================================
# 6. FUNGSI JSON LAINNYA
# ============================================================

# 6.1 Membuat objek dan array JSON
SELECT JSON_OBJECT('nama', 'Sari Wulandari', 'role', 'Admin Gudang', 'aktif', TRUE) AS data_pengguna;
SELECT JSON_ARRAY('Tepung Terigu', 'Kecap Asin', 'Bawang Goreng', 'Penyedap Rasa')   AS daftar_barang;

# 6.2 Memeriksa validitas JSON
SELECT JSON_VALID('{"nama":"Budi","role":"Owner"}') AS json_valid; # 1
SELECT JSON_VALID('{nama: Budi}')                   AS json_tidak_valid; # 0

# 6.3 Menghitung jumlah atribut
SELECT b.nama_barang, JSON_LENGTH(s.spesifikasi) AS jumlah_atribut
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;


# ============================================================
# 7. PEMETAAN OBJEK KE TABEL RELASIONAL (tabel transaksi_objek)
# Satu tabel untuk Transaksi; jenisnya dibedakan oleh kolom jenis_transaksi
# ============================================================

# 7.1 Mengambil data berdasarkan jenis objek
SELECT id_transaksi, no_dokumen, tanggal, atribut
FROM transaksi_objek WHERE jenis_transaksi = 'BarangMasuk';    

SELECT id_transaksi, no_dokumen, tanggal, atribut
FROM transaksi_objek WHERE jenis_transaksi = 'BarangKeluar';   

SELECT id_transaksi, no_dokumen, tanggal, atribut
FROM transaksi_objek WHERE jenis_transaksi = 'Retur';          

# 7.2 Mencari lewat atribut khusus turunan (hanya Retur yang punya "alasan")
SELECT no_dokumen, JSON_EXTRACT(atribut, '$.alasan') AS alasan
FROM transaksi_objek
WHERE JSON_UNQUOTE(JSON_EXTRACT(atribut, '$.alasan')) = 'cacat';

# 7.3 Menggabungkan data relasional (JOIN) dan atribut JSON
SELECT
    b.id_barang,
    b.nama_barang,
    j.nama_jenis,
    b.jumlah_stok,
    JSON_EXTRACT(s.spesifikasi, '$.kemasan') AS kemasan
FROM barang b
JOIN barang_spesifikasi s ON s.id_barang = b.id_barang
JOIN jenis_barang j       ON j.id_jenis  = s.id_jenis;


# ============================================================
# 8. INSERT dan DELETE BARIS
# ============================================================

# 8.1 INSERT: barang baru beserta spesifikasinya
INSERT INTO barang (nama_barang, satuan, stok_minimal)
VALUES ('Penyedap Rasa Sapi', 'karton', 12);

INSERT INTO barang_spesifikasi (id_barang, id_jenis, spesifikasi)
VALUES (
    (SELECT id_barang FROM barang WHERE nama_barang = 'Penyedap Rasa Sapi'),
    4,
    '{"rasa": "sapi", "berat_gram": 250, "isi_per_karton": 10, "kemasan": "plastik"}'
);

SELECT COUNT(*) AS jumlah_barang FROM barang;     

# 8.2 DELETE: hapus spesifikasi dulu, baru barangnya (urutan karena FOREIGN KEY)
DELETE FROM barang_spesifikasi
WHERE id_barang = (SELECT id_barang FROM barang WHERE nama_barang = 'Penyedap Rasa Sapi');

DELETE FROM barang WHERE nama_barang = 'Penyedap Rasa Sapi';

SELECT COUNT(*) AS jumlah_barang FROM barang;   


# ============================================================
# 9. INDEKS UNTUK ATRIBUT JSON (opsional)
# Kolom turunan (generated column) + indeks mempercepat pencarian kemasan
# ============================================================

ALTER TABLE barang_spesifikasi
    ADD COLUMN kemasan_teks VARCHAR(30)
        GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(spesifikasi, '$.kemasan'))) STORED,
    ADD INDEX idx_spesifikasi_kemasan (kemasan_teks);

SELECT id_barang, kemasan_teks FROM barang_spesifikasi WHERE kemasan_teks = 'plastik';
