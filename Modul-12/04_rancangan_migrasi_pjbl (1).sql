USE bukuku;

-- Penambahan indeks komposit untuk mempercepat filter laporan pengiriman barang keluar
CREATE INDEX idx_bk_konfirmasi_tanggal ON barang_keluar (status_konfirmasi, tanggal);

-- 2. Rancangan Query Utama (KF-03 & KF-08: Laporan Pengiriman Barang Keluar)
-- Menampilkan rincian surat jalan yang sudah terkonfirmasi (status_konfirmasi = 1)
SELECT bk.no_surat_jalan, bk.tanggal, tc.nama_toko,
       b.nama_barang, dbk.jumlah, b.satuan, dbk.harga_jual
FROM barang_keluar AS bk
JOIN toko_cabang AS tc ON bk.id_toko = tc.id_toko
JOIN detail_barang_keluar AS dbk ON bk.id_keluar = dbk.id_keluar
JOIN barang AS b ON dbk.id_barang = b.id_barang
WHERE bk.status_konfirmasi = 1
  AND bk.tanggal >= '2026-11-01';

-- 3. Rancangan RBAC / DCL Sesuai Prinsip Least Privilege (SKPL Subbab 2.2)
-- Role Admin Gudang: hanya operasional harian (tanpa DELETE & tanpa akses tabel pengguna)
CREATE ROLE IF NOT EXISTS 'role_admin_gudang';
GRANT SELECT, INSERT, UPDATE ON bukuku.barang TO 'role_admin_gudang';
GRANT SELECT, INSERT, UPDATE ON bukuku.barang_keluar TO 'role_admin_gudang';
GRANT SELECT, INSERT, UPDATE ON bukuku.detail_barang_keluar TO 'role_admin_gudang';
GRANT SELECT, INSERT, UPDATE ON bukuku.barang_masuk TO 'role_admin_gudang';
GRANT SELECT, INSERT, UPDATE ON bukuku.detail_barang_masuk TO 'role_admin_gudang';
GRANT SELECT, INSERT, UPDATE ON bukuku.retur TO 'role_admin_gudang';
GRANT SELECT ON bukuku.toko_cabang TO 'role_admin_gudang';
GRANT SELECT ON bukuku.pabrik TO 'role_admin_gudang';
GRANT SELECT, INSERT ON bukuku.log_aktivitas TO 'role_admin_gudang';

-- Role Owner: akses penuh termasuk view laporan stok & untung-rugi
CREATE ROLE IF NOT EXISTS 'role_owner';
GRANT ALL PRIVILEGES ON bukuku.* TO 'role_owner';

-- Penerapan ke akun pengguna (kredensial menggunakan placeholder)
CREATE USER IF NOT EXISTS 'admin1'@'%' IDENTIFIED BY '<PASSWORD_ADMIN_GUDANG>';
GRANT 'role_admin_gudang' TO 'admin1'@'%';
SET DEFAULT ROLE 'role_admin_gudang' TO 'admin1'@'%';

CREATE USER IF NOT EXISTS 'owner'@'%' IDENTIFIED BY '<PASSWORD_OWNER>';
GRANT 'role_owner' TO 'owner'@'%';
SET DEFAULT ROLE 'role_owner' TO 'owner'@'%';
