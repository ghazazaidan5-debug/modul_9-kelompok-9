# Modul9_Kelompok 9

# Praktikum Denormalisasi: Basis Data Penjualan Sederhana
Perbandingan query **JOIN + agregasi** (sebelum) dengan query **kolom turunan hasil denormalisasi** (sesudah) pada kasus fiktif basis data penjualan.

---
## Identitas
### Anggota Kelompok

|  No  |           Nama          |     NIM     |
|:-----|:------------------------|:------------|
|  1   | Azzam fauzy               | 264311062   |
|  2   | Ghaza Zaidan Al-ghifari    | 264311069 |
|  3   | Muhammad zakiy Fuadiy    | 264311077   |

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
| `pelanggan`      | Data master pelanggan (`id_pelanggan`, `nama_pelanggan`)                                    |
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

* Kueri ini membutuhkan operasi JOIN sebanyak dua kali untuk menghubungkan tiga tabel yang berbeda.
* Beban Komputasi: Sistem database harus memindai dulu baris di tabel pelanggan, mencocokkannya dengan pesanan, lalu mencocokkannya lagi dengan detail_pesanan. Setelah itu, database harus mengalikan jumlah * harga_satuan, menjumlahkannya (SUM), dan mengelompokkannya (GROUP BY).
* Waktu eksekusi: 0,024 detik
* jika digunakan dalam skala besar maka beban komputasi akan dilakukan setiap kueri dijalankan

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

* 1 tabel, 0 JOIN, tanpa agregasi menjadikan lebih ringkas sehingga lebih sederhana
* Waktu eksekusi: 0,001 detik

---

## Hasil Perbandingan

|      Aspek     |       Tahap 1 (JOIN)       | Tahap 3 (Denormalisasi)    |
|:---------------|:--------------------------:|:--------------------------:|
| Struktur Kueri  | Panjang dan rumit (Menggunakan 2 JOIN, SUM(), GROUP BY). | Sangat pendek dan sederhana (SELECT biasa). |
| Kecepatan / Performa  | Lebih lambat karena database menghitung ulang dari awal setiap saat. |Sangat cepat karena database hanya membaca nilai yang sudah jadi. |
|Beban Kerja     | Tinggi (melakukan operasi perkalian, penjumlahan, dan pencocokan relasi). | Ringan (hanya membaca satu tabel saja).|
| Waktu eksekusi | 0,024 detik                | 0,001 detik                |
| Konsekuensi|Tidak ada risiko data tidak sinkron.| adanya risiko data tidak konsisten.|

**Kesimpulan:** hasilnya berbeda, query denormalisasi lebih sederhana karena tidak perlu JOIN dan agregasi. Pada data percobaan yang hanya beberapa baris, selisih waktu terlihat (antara 0.024 detik saat JOIN dan 0.0001 detik saat denormalisasi). dan mungkin akan sangat terasa saat data mencapai jutaan.

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
