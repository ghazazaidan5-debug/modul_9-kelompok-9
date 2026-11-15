
-- ============================================================
-- 1. IDENTIFIKASI DBMS
-- ============================================================

-- 1.1 Nama, versi, dan jenis DBMS
SELECT VERSION();
SELECT @@version_comment;

-- 1.2 Database, storage engine, karakter set
SHOW DATABASES;
SHOW ENGINES;                                     -- InnoDB: Support = DEFAULT, Transactions = YES
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';

-- 1.3 Dukungan fungsi JSON
SELECT
    JSON_VALID('{"nama":"Budi"}')               AS json_valid,
    JSON_EXTRACT('{"nama":"Budi"}', '$.nama')   AS nama;
-- Hasil diharapkan: json_valid = 1 | nama = "Budi"

-- 1.4 Informasi server
SELECT NOW();
SELECT DATABASE();                                -- bukuku_modul11

-- 1.5 Fasilitas transaksi (START TRANSACTION, ROLLBACK)
START TRANSACTION;
    UPDATE barang SET stok_minimal = 999 WHERE id_barang = 1;
    SELECT id_barang, nama_barang, stok_minimal FROM barang WHERE id_barang = 1;

ROLLBACK;
SELECT id_barang, nama_barang, stok_minimal FROM barang WHERE id_barang = 1;


-- ============================================================
-- 2. READ - membaca atribut JSON (SELECT)
-- ============================================================

-- 2.1 Membaca satu atribut: kemasan
SELECT b.nama_barang, JSON_EXTRACT(s.spesifikasi, '$.kemasan') AS kemasan
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;

-- 2.2 Membaca atribut yang tidak dimiliki semua barang: isi_per_karton
SELECT b.nama_barang, JSON_EXTRACT(s.spesifikasi, '$.isi_per_karton') AS isi_per_karton
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;

-- 2.3 Membaca atribut lain: berat_gram
SELECT b.nama_barang, JSON_EXTRACT(s.spesifikasi, '$.berat_gram') AS berat_gram
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;

-- 2.4 Mencari barang berdasarkan nilai atribut
SELECT b.nama_barang, b.satuan
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kadar_protein')) = '12%';

SELECT b.nama_barang, b.jumlah_stok
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kemasan')) = 'plastik';

-- 2.5 Mencari di dalam array JSON (label)
SELECT b.nama_barang
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_CONTAINS(JSON_EXTRACT(s.spesifikasi, '$.label'), '"BPOM"') = 1;


-- ============================================================
-- 3. UPDATE - mengubah atribut JSON (JSON_SET)
-- Kasus: kadar protein tepung berubah dari 12% menjadi 13%
-- ============================================================

UPDATE barang_spesifikasi
SET spesifikasi = JSON_SET(spesifikasi, '$.kadar_protein', '13%')
WHERE id_barang = 1;

-- Periksa hasil
SELECT id_barang, JSON_EXTRACT(spesifikasi, '$.kadar_protein') AS kadar_protein
FROM barang_spesifikasi
WHERE id_barang = 1;

-- Pencarian setelah perubahan
SELECT b.nama_barang
FROM barang_spesifikasi s JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kadar_protein')) = '13%';

SELECT b.nama_barang
FROM barang_spesifikasi s JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(s.spesifikasi, '$.kadar_protein')) = '12%';


-- ============================================================
-- 4. UPDATE - menambah atribut baru (JSON_SET dan JSON_ARRAY_APPEND)
-- ============================================================

-- 4.1 JSON_SET pada key yang belum ada: atribut baru ditambahkan
--     Kasus: tepung mendapat atribut pemasok_utama
UPDATE barang_spesifikasi
SET spesifikasi = JSON_SET(spesifikasi, '$.pemasok_utama', 'PT Sumber Pangan Nusantara')
WHERE id_barang = 1;

SELECT id_barang, spesifikasi FROM barang_spesifikasi WHERE id_barang = 1;

-- 4.2 JSON_ARRAY_APPEND: menambah elemen ke array yang sudah ada
--     Kasus: kecap mendapat label baru "BPOM" pada array label
UPDATE barang_spesifikasi
SET spesifikasi = JSON_ARRAY_APPEND(spesifikasi, '$.label', 'BPOM')
WHERE id_barang = 2;

SELECT id_barang, JSON_EXTRACT(spesifikasi, '$.label') AS label
FROM barang_spesifikasi
WHERE id_barang = 2;

-- Periksa lewat pencarian array
SELECT b.nama_barang
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_CONTAINS(JSON_EXTRACT(s.spesifikasi, '$.label'), '"BPOM"') = 1;


-- ============================================================
-- 5. DELETE - menghapus atribut JSON (JSON_REMOVE)
-- ============================================================

-- 5.1 Menghapus satu atribut: pemasok_utama pada tepung
UPDATE barang_spesifikasi
SET spesifikasi = JSON_REMOVE(spesifikasi, '$.pemasok_utama')
WHERE id_barang = 1;

SELECT id_barang, spesifikasi FROM barang_spesifikasi WHERE id_barang = 1;

-- 5.2 Menghapus satu elemen array: label "BPOM" pada kecap (elemen ke-2, indeks 1)
UPDATE barang_spesifikasi
SET spesifikasi = JSON_REMOVE(spesifikasi, '$.label[1]')
WHERE id_barang = 2;

SELECT id_barang, JSON_EXTRACT(spesifikasi, '$.label') AS label
FROM barang_spesifikasi
WHERE id_barang = 2;

-- Hanya penyedap yang berlabel BPOM lagi
SELECT b.nama_barang
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang
WHERE JSON_CONTAINS(JSON_EXTRACT(s.spesifikasi, '$.label'), '"BPOM"') = 1;


-- ============================================================
-- 6. FUNGSI JSON LAINNYA
-- ============================================================

-- 6.1 Membuat objek dan array JSON
SELECT JSON_OBJECT('nama', 'Sari Wulandari', 'role', 'Admin Gudang', 'aktif', TRUE) AS data_pengguna;
SELECT JSON_ARRAY('Tepung Terigu', 'Kecap Asin', 'Bawang Goreng', 'Penyedap Rasa')   AS daftar_barang;

-- 6.2 Memeriksa validitas JSON
SELECT JSON_VALID('{"nama":"Budi","role":"Owner"}') AS json_valid;        -- 1
SELECT JSON_VALID('{nama: Budi}')                   AS json_tidak_valid;   -- 0

-- 6.3 Menghitung jumlah atribut
SELECT b.nama_barang, JSON_LENGTH(s.spesifikasi) AS jumlah_atribut
FROM barang_spesifikasi s
JOIN barang b ON b.id_barang = s.id_barang;


-- ============================================================
-- 7. PEMETAAN OBJEK KE TABEL RELASIONAL (tabel transaksi_objek)
-- Satu tabel untuk Transaksi; jenisnya dibedakan oleh kolom jenis_transaksi
-- ============================================================

-- 7.1 Mengambil data berdasarkan jenis objek
SELECT id_transaksi, no_dokumen, tanggal, atribut
FROM transaksi_objek WHERE jenis_transaksi = 'BarangMasuk';    

SELECT id_transaksi, no_dokumen, tanggal, atribut
FROM transaksi_objek WHERE jenis_transaksi = 'BarangKeluar';   

SELECT id_transaksi, no_dokumen, tanggal, atribut
FROM transaksi_objek WHERE jenis_transaksi = 'Retur';          

-- 7.2 Mencari lewat atribut khusus turunan (hanya Retur yang punya "alasan")
SELECT no_dokumen, JSON_EXTRACT(atribut, '$.alasan') AS alasan
FROM transaksi_objek
WHERE JSON_UNQUOTE(JSON_EXTRACT(atribut, '$.alasan')) = 'cacat';

-- 7.3 Menggabungkan data relasional (JOIN) dan atribut JSON
SELECT
    b.id_barang,
    b.nama_barang,
    j.nama_jenis,
    b.jumlah_stok,
    JSON_EXTRACT(s.spesifikasi, '$.kemasan') AS kemasan
FROM barang b
JOIN barang_spesifikasi s ON s.id_barang = b.id_barang
JOIN jenis_barang j       ON j.id_jenis  = s.id_jenis;


-- ============================================================
-- 8. INSERT dan DELETE BARIS
-- ============================================================

-- 8.1 INSERT: barang baru beserta spesifikasinya
INSERT INTO barang (nama_barang, satuan, stok_minimal)
VALUES ('Penyedap Rasa Sapi', 'karton', 12);

INSERT INTO barang_spesifikasi (id_barang, id_jenis, spesifikasi)
VALUES (
    (SELECT id_barang FROM barang WHERE nama_barang = 'Penyedap Rasa Sapi'),
    4,
    '{"rasa": "sapi", "berat_gram": 250, "isi_per_karton": 10, "kemasan": "plastik"}'
);

SELECT COUNT(*) AS jumlah_barang FROM barang;     

-- 8.2 DELETE: hapus spesifikasi dulu, baru barangnya (urutan karena FOREIGN KEY)
DELETE FROM barang_spesifikasi
WHERE id_barang = (SELECT id_barang FROM barang WHERE nama_barang = 'Penyedap Rasa Sapi');

DELETE FROM barang WHERE nama_barang = 'Penyedap Rasa Sapi';

SELECT COUNT(*) AS jumlah_barang FROM barang;   


-- ============================================================
-- 9. INDEKS UNTUK ATRIBUT JSON (opsional)
-- Kolom turunan (generated column) + indeks mempercepat pencarian kemasan
-- ============================================================

ALTER TABLE barang_spesifikasi
    ADD COLUMN kemasan_teks VARCHAR(30)
        GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(spesifikasi, '$.kemasan'))) STORED,
    ADD INDEX idx_spesifikasi_kemasan (kemasan_teks);

SELECT id_barang, kemasan_teks FROM barang_spesifikasi WHERE kemasan_teks = 'plastik';
