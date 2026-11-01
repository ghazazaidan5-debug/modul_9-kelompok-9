# Modul9_Kelompok 9

# Praktikum Denormalisasi: Basis Data Penjualan Sederhana
Perbandingan query **JOIN + agregasi** (sebelum) dengan query **kolom turunan hasil denormalisasi** (sesudah) pada kasus fiktif basis data penjualan.

---
## Identitas
### Anggota Kelompok

|  No  |           Nama          |     NIM     |
|:-----|:------------------------|:------------|
|  1   | [Isi nama anggota 1]    | [Isi NIM]   |
|  2   | ghaza zaidan al-ghifari    | 264311069 |
|  3   | [Isi nama anggota 3]    | [Isi NIM]   |

---

## Daftar Isi

* [Deskripsi](#deskripsi)
* [Struktur Database](#struktur-database)
* [Isi Repositori](#isi-repositori)
* [Hasil Perbandingan](#hasil-perbandingan)
* [Kelebihan Denormalisasi](#kelebihan-denormalisasi)
* [Risiko Denormalisasi](#risiko-denormalisasi)

---

## Deskripsi
Praktikum ini membandingkan dua cara memperoleh total belanja per pelanggan:

1. **Sebelum:** dihitung langsung (*on-the-fly*) dengan menggabungkan 3 tabel menggunakan JOIN dan fungsi agregasi.
2. **Sesudah:** dibaca dari kolom `total_belanja` yang sudah disimpan di tabel `pelanggan` (denormalisasi).

---

## Struktur Database

|       Tabel      |                                             Keterangan                                           |
|:-----------------|:-------------------------------------------------------------------------------------------------|
| `pelanggan`      | Data master pelanggan (`id_pelanggan`, `nama_pelanggan`, ...)                                    |
| `pesanan`        | Data pesanan, terhubung ke `pelanggan` lewat `id_pelanggan`                                      |
| `detail_pesanan` | Rincian barang per pesanan (`jumlah`, `harga_satuan`), terhubung ke `pesanan` lewat `id_pesanan` |

---

## Isi Repositori

|                            Berkas / Folder                          |           Keterangan           |
|:--------------------------------------------------------------------|:-------------------------------|
| [README.md](README.md)                                              | Dokumentasi praktikum          |
| [berkas.sql](berkas.sql)                                            | Script Tahap 1, 2, dan 3       |
| [Bukti Eksekusi/](Bukti%20Eksekusi/)                                | Folder bukti eksekusi          |
| ![Hasil Tahap 1](Bukti%20Eksekusi/Tahap%201.png)                    | Screenshot hasil Tahap 1       |
| ![Hasil Tahap 3](Bukti%20Eksekusi/Tahap%203.png)                    | Screenshot hasil Tahap 3       |

---

### Tahap 1: Query JOIN + Agregasi (Sebelum)

Menghitung total belanja per pelanggan secara *on-the-fly*.

```sql
SELECT
    p.id_pelanggan,
    p.nama_pelanggan,
    SUM(dp.jumlah * dp.harga_satuan) AS kalkulasi_total_belanja
FROM pelanggan p
JOIN pesanan ps ON p.id_pelanggan = ps.id_pelanggan
JOIN detail_pesanan dp ON ps.id_pesanan = dp.id_pesanan
GROUP BY p.id_pelanggan, p.nama_pelanggan;
```

**Catatan kompleksitas:**

* 3 tabel, 2 INNER JOIN
* 1 fungsi agregasi (`SUM`) dengan `GROUP BY` 2 kolom
* Beban komputasi: dihitung ulang setiap eksekusi, sebanding dengan jumlah baris `detail_pesanan`
* Waktu eksekusi: 0,001 detik

### Tahap 2: Denormalisasi (DDL)

Menambahkan kolom turunan `total_belanja` pada tabel `pelanggan`, lalu mengisinya dengan hasil perhitungan Tahap 1.

```sql
-- Perintah DDL: menambahkan kolom turunan
ALTER TABLE pelanggan
ADD COLUMN total_belanja DECIMAL(15,2) DEFAULT 0;

-- Perintah DML: sinkronisasi data awal menggunakan subquery
UPDATE pelanggan p
SET total_belanja = (
    SELECT COALESCE(SUM(dp.jumlah * dp.harga_satuan), 0)
    FROM pesanan ps
    JOIN detail_pesanan dp ON ps.id_pesanan = dp.id_pesanan
    WHERE ps.id_pelanggan = p.id_pelanggan
);
```

### Tahap 3: Pembuktian (Sesudah)

Membaca nilai yang sudah tersimpan, tanpa JOIN dan tanpa agregasi.

```sql
SELECT
    id_pelanggan,
    nama_pelanggan,
    total_belanja
FROM pelanggan;
```

* 1 tabel, 0 JOIN, tanpa agregasi
* Waktu eksekusi: 0,001 detik

---

## Hasil Perbandingan

|      Aspek     |       Tahap 1 (JOIN)       | Tahap 3 (Denormalisasi)    |
|:---------------|:--------------------------:|:--------------------------:|
| Tabel diakses  | 3                          | 1                          |
| Jumlah JOIN    | 2                          | 0                          |
| Agregasi       | SUM + GROUP BY             | Tidak ada                  |
| Waktu eksekusi | 0,001 detik                | 0,001 detik                |
| Hasil          | Budi 250.000, Siti 100.000 | Budi 250.000, Siti 100.000 |

**Kesimpulan:** hasilnya sama, tetapi query denormalisasi lebih sederhana karena tidak perlu JOIN dan agregasi. Pada data percobaan yang hanya beberapa baris, selisih waktu belum terlihat (keduanya 0,001 detik). Perbedaan kecepatan baru terasa pada data ribuan sampai jutaan baris.

### Bukti Eksekusi

**Tahap 1 (JOIN)**

![Hasil Tahap 1](Bukti%20Eksekusi/Tahap%201.png)

**Tahap 3 (Denormalisasi)**

![Hasil Tahap 3](Bukti%20Eksekusi/Tahap%203.png)

---

## Kelebihan Denormalisasi

Kelebihan utamanya adalah **kecepatan pembacaan data (*read performance*) meningkat dan kode SQL lebih sederhana**. Pada data berskala besar, JOIN yang dikombinasikan dengan `SUM` dan `GROUP BY` memaksa server memindai dan menghitung ulang banyak baris setiap kali data diminta. Dengan denormalisasi, hasil hitung sudah tersimpan di satu kolom tabel master, sehingga aplikasi cukup menjalankan `SELECT` sederhana ke satu tabel.

## Risiko Denormalisasi

Risiko utamanya adalah **anomali pembaruan (*update anomaly*) yang memicu inkonsistensi data**. Nilai `total_belanja` tersimpan statis di tabel `pelanggan`, sehingga tidak berubah otomatis jika ada transaksi baru di `detail_pesanan`, atau jika data transaksi lama diubah atau dihapus. Agar tetap sinkron, dibutuhkan mekanisme tambahan seperti *database trigger* atau logika khusus di sisi aplikasi. Proses tulis juga menjadi lebih berat dan butuh ruang penyimpanan tambahan.

---
