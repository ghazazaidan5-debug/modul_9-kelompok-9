
-- ------------------------------------------------------------
-- (B) Tabel tambahan untuk praktikum Modul 11 (di luar ERD inti SKPL)
--     Dipakai untuk latihan JSON dan pemodelan objek pada data BUKUKU.
-- ------------------------------------------------------------

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

-- ------------------------------------------------------------
-- (C) TRIGGER: menjaga stok otomatis (stored program)
-- ------------------------------------------------------------
DELIMITER $$

-- KF-02: barang masuk -> stok bertambah
CREATE TRIGGER trg_detail_masuk_ai
AFTER INSERT ON detail_barang_masuk
FOR EACH ROW
BEGIN
    UPDATE barang
    SET jumlah_stok = jumlah_stok + NEW.jumlah
    WHERE id_barang = NEW.id_barang;
END$$

-- KF-03: barang keluar ditolak bila stok kurang (stok tidak boleh minus)
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

-- KF-03: barang keluar -> stok berkurang
CREATE TRIGGER trg_detail_keluar_ai
AFTER INSERT ON detail_barang_keluar
FOR EACH ROW
BEGIN
    UPDATE barang
    SET jumlah_stok = jumlah_stok - NEW.jumlah
    WHERE id_barang = NEW.id_barang;
END$$

-- KF-05: retur ke pabrik tidak boleh melebihi stok
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

-- KF-05: penyesuaian stok setelah retur
--   ke pabrik            -> stok layak jual berkurang
--   dari toko, layak jual -> stok layak jual bertambah
--   dari toko, rusak      -> stok rusak bertambah (tidak ikut stok jual)
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

-- ------------------------------------------------------------
-- (D) VIEW: laporan
-- ------------------------------------------------------------

-- KF-06 dan KF-08: laporan stok + penanda stok menipis
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

-- KF-08: harga beli diambil dari nota barang masuk TERAKHIR untuk tiap barang
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

-- KF-08: untung = (harga jual - harga beli) x jumlah  (hanya untuk Owner)
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
