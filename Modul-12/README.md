# Praktikum Modul 12: Pemrosesan Query, Migrasi Awal, dan Kontrol Akses (DCL)

## Identitas Kelompok
* **Proyek PjBL:** BUKUKU (Sistem Pembukuan Gudang Distributor Bumbu Dapur)
* **Paradigma & DBMS Target:** NewSQL — **TiDB** (`8.0.11-TiDB-v7.5.1`)
* **Kelas / Prodi:** Kelas 1-C / Teknologi Rekayasa Perangkat Lunak – Politeknik Negeri Madiun
* **Anggota Kelompok:**
  1. Azzam Fauzy (264311062)
  2. Ghaza Zaidan Al-Ghifari (264311069)
  3. Muhammad Zakiy Fuadiy (264311077)

## Struktur Direktori Repository
```text
praktikum_modul12/
├── scripts/
│   ├── 01_migrasi_data_latihan.sql      # Skrip DDL & DML migrasi database latihan (transport_db)
│   ├── 02_query_transportasi.sql        # Skrip pengujian query SELECT & EXPLAIN ANALYZE
│   ├── 03_pengujian_dcl.sql             # Skrip pengujian GRANT, REVOKE, dan Least Privilege
│   └── 04_rancangan_migrasi_pjbl.sql    # Blueprint skema, query, dan RBAC proyek BUKUKU
├── dokumentasi/
│   └── (screenshot bukti eksekusi DBeaver/TiDB)
├── diagram/
│   └── (gambar Query Tree)
└── README.md
```

## Ringkasan Langkah Eksekusi
1. **Tahap 1 & 2 (Migrasi Latihan):** menjalankan `01_migrasi_data_latihan.sql` pada instance TiDB menggunakan akun administrator (`root`), lalu kueri pada `02_query_transportasi.sql` untuk memverifikasi keluaran 3 baris perjalanan (`T001`, `T003`, `T005`).
2. **Tahap 3 (Optimisasi & Query Cost):** Menjalankan perintah `EXPLAIN ANALYZE` pada `02_query_transportasi.sql` untuk mengamati *Selection Pushdown* pada lapisan penyimpanan `cop[tikv]`.
3. **Tahap 4 (Keamanan DCL):** Menjalankan `03_pengujian_dcl.sql` secara bergantian antara sesi `root` dan `report_user` untuk membuktikan pembatasan hak akses (`SELECT` berhasil, `DELETE` ditolak, dan `SELECT` ditolak setelah `REVOKE`).
4. **Tahap 5 (Blueprint Proyek BUKUKU):** Berisi rancangan skema relasional ternormalisasi, indeks komposit, kueri laporan barang keluar, serta pembagian *role* `role_admin_gudang` dan `role_owner` pada `04_rancangan_migrasi_pjbl.sql`.


