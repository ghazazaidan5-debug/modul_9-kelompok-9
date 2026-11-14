-- ============================================================
-- DATABASE BUKUKU
-- Berdasarkan SKPL Sistem Pembukuan Gudang BUKUKU
-- DBMS: MySQL / MariaDB (XAMPP, phpMyAdmin)
-- ============================================================

CREATE DATABASE IF NOT EXISTS db_bukuku
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_bukuku;

-- ------------------------------------------------------------
-- 1. Tabel PABRIK
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pabrik (
    id_pabrik INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_pabrik VARCHAR(100) NOT NULL,
    kontak_sales VARCHAR(100),
    no_hp VARCHAR(20)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. Tabel BARANG
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS barang (
    id_barang INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_barang VARCHAR(100) NOT NULL,
    satuan VARCHAR(30) NOT NULL,
    stok_minimal INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_stok INT UNSIGNED NOT NULL DEFAULT 0,
    stok_rusak INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. Tabel TOKO_CABANG
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS toko_cabang (
    id_toko INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_toko VARCHAR(100) NOT NULL,
    nama_pemilik VARCHAR(100),
    alamat TEXT,
    no_hp VARCHAR(20),
    jenis_toko VARCHAR(50),
    status_tempo BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. Tabel PENGGUNA
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pengguna (
    id_pengguna INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    `role` ENUM('ADMIN_GUDANG', 'OWNER') NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. Tabel BARANG_MASUK
-- Satu transaksi barang masuk berasal dari satu pabrik
-- dan dicatat oleh satu pengguna.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 6. Tabel DETAIL_BARANG_MASUK
-- Menyimpan barang, jumlah, dan harga beli per nota.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 7. Tabel BARANG_KELUAR
-- Satu transaksi pengiriman ditujukan ke satu toko
-- dan dicatat oleh satu pengguna.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 8. Tabel DETAIL_BARANG_KELUAR
-- Menyimpan barang, jumlah, dan harga jual per pengiriman.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 9. Tabel RETUR
-- jenis_retur:
--   KE_PABRIK  = barang dikembalikan dari gudang ke pabrik
--   DARI_TOKO  = barang dikembalikan dari toko ke gudang
-- Untuk KE_PABRIK, isi id_pabrik dan kosongkan id_toko.
-- Untuk DARI_TOKO, isi id_toko dan kosongkan id_pabrik.
-- status_layak_jual diisi untuk retur DARI_TOKO.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 10. Tabel LOG_AKTIVITAS
-- Mencatat pengguna, aksi, tabel yang diubah, ID record,
-- dan waktu aktivitas. Isi sebelum/sesudah perubahan
-- memang tidak disimpan sesuai batasan SKPL.
-- ------------------------------------------------------------
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
