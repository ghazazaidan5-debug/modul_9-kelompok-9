---pembuatan
CREATE DATABASE toko online;

USE toko online;

CREATE TABLE pelanggan (
    id_pelanggan INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_pelanggan VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE produk (
    id_produk INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_produk VARCHAR(100) NOT NULL,
    harga_produk DECIMAL(12,2) NOT NULL,
    stok INT U+NSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE pesanan (
    id_pesanan INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT UNSIGNED NOT NULL,
    tanggal DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_pesanan ENUM(
        'baru',
        'diproses',
        'selesai',
        'batal'
    ) NOT NULL DEFAULT 'baru',

    CONSTRAINT fk_pesanan_pelanggan
    FOREIGN KEY (id_pelanggan)
    REFERENCES pelanggan(id_pelanggan)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE detail_pesanan (
    id_pesanan INT UNSIGNED NOT NULL,
    id_produk INT UNSIGNED NOT NULL,
    jumlah INT UNSIGNED NOT NULL,
    harga_saat_transaksi DECIMAL(12,2) NOT NULL,

    PRIMARY KEY (id_pesanan, id_produk),

    CONSTRAINT fk_detail_pesanan
    FOREIGN KEY (id_pesanan)
    REFERENCES pesanan(id_pesanan)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

    CONSTRAINT fk_detail_produk
    FOREIGN KEY (id_produk)
    REFERENCES produk(id_produk)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

---pengujian 
INSERT INTO pesanan
    (id_pesanan, id_pelanggan, tanggal)
VALUES
    (105, 999, '2026-10-05 10:00:00');

DELETE FROM pelanggan
WHERE id_pelanggan = 1;

START TRANSACTION;

INSERT INTO pesanan
    (id_pesanan, id_pelanggan, tanggal, status_pesanan)
VALUES
    (103, 1, '2026-10-05 09:00:00', 'baru');

INSERT INTO detail_pesanan
    (id_pesanan, id_produk, jumlah, harga_saat_transaksi)
VALUES
    (103, 11, 2, 100000);

COMMIT;


START TRANSACTION;

INSERT INTO pesanan
    (id_pesanan, id_pelanggan, tanggal, status_pesanan)
VALUES
    (104, 2, '2026-10-06 10:00:00', 'baru');

INSERT INTO detail_pesanan
    (id_pesanan, id_produk, jumlah, harga_saat_transaksi)
VALUES
    (104, 10, 1, 200000);

ROLLBACK;



