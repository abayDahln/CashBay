# CashBay

CashBay itu aplikasi catatan keuangan pribadi yang dibikin dengan Flutter dan jalan sepenuhnya offline. Semua data disimpan di SQLite lokal, jadi nggak butuh server sama sekali — cukup buka aplikasinya, catat transaksinya, beres. Aplikasi ini mencatat pendapatan, pengeluaran, transfer antar dompet, plus tagihan utang dan piutang. Semua nominal dalam Rupiah.

## Fitur

- **Dashboard** menampilkan total saldo, ringkasan pendapatan dan pengeluaran, saldo tagihan, dan transaksi terbaru.
- **Transaksi** bisa dibuat sebagai pendapatan, pengeluaran, transfer antar dompet, atau tagihan. Tiap transaksi bisa dilengkapi foto, catatan, kategori, tanggal, dan metode pembayaran.
- **Riwayat** dikelompokkan per tanggal, bisa dicari dan difilter berdasarkan tipe. Transaksi bisa diedit atau dihapus. Edit terbatas pada deskripsi, catatan, dan foto; penghapusan bersifat lunak dan tidak mengubah saldo.
- **Analitik** menampilkan grafik batang per bulan untuk pendapatan atau pengeluaran. Bisa digeser ke tahun sebelumnya, dan ketuk salah satu batang untuk melihat daftar transaksi di bulan itu.
- **Tagihan** dikelola sebagai utang dan piutang, lengkap dengan status dan riwayat pembayaran.
- **Kategori** untuk pendapatan dan pengeluaran bisa diatur, sudah ada satu set bawaan.
- **Profil** bersifat hiasan saja — foto, nama (default "User Bay"), bio, jenis kelamin, dan tanggal lahir — semuanya tersimpan lokal dan bebas diedit. Tombol ⚙️ di kanannya membuka Pengaturan.
- **Pengaturan** untuk mengubah tema dan bahasa, menghapus seluruh data, serta ekspor/impor data sebagai file JSON.
- Data bisa dihapus seluruhnya, diekspor, atau diimpor sebagai file JSON dari halaman Pengaturan.

## Teknologi

- Flutter / Dart 3.11.1
- Provider untuk manajemen state
- sqflite untuk penyimpanan SQLite (sqflite_common_ffi untuk pengujian dan desktop)
- intl untuk format Rupiah dan tanggal
- image_picker untuk unggah foto
- path_provider untuk lokasi file backup
- fl_chart untuk grafik analitik
- shared_preferences untuk preferensi tema, bahasa, dan data profil

Tema memakai Material 3 dengan warna aksen yang bisa diganti dari Pengaturan, plus dukungan mode terang dan gelap.

## Instalasi

Pastikan Flutter sudah terpasang, lalu jalankan:

```
flutter pub get
flutter run
```

## Testing

```
flutter test                       # tes biasa (disarankan --concurrency=1)
flutter test integration_test/ -d windows   # tes integrasi di Windows
```

## Platform

* **Android**
* **iOS** (Beta)
* **Windows** (untuk pengembangan dan pengujian)

## Struktur Proyek

```
lib/
├── core/
│   ├── database/       # Inisialisasi dan migrasi SQLite
│   ├── theme/          # Tema dan preferensi
│   ├── utils/          # Formatter dan validasi
│   └── widgets/        # Widget bersama
└── features/
    ├── dashboard/      # Dompet dan beranda
    ├── transactions/   # Transaksi, riwayat, dan detail
    ├── debts/          # Tagihan utang dan piutang
    ├── categories/     # Kelola kategori
    ├── report/         # Analitik (grafik)
    ├── profile/        # Profil pengguna (hiasan)
    └── settings/       # Pengaturan dan backup
```

Tiap fitur dipisah jadi lapisan data (model dan repository) dan lapisan presentasi (layar dan provider).

## Skema Data

Tabel yang dipakai: `wallets`, `categories`, `transactions`, `debts`, `debt_payments`.

Beberapa aturan yang perlu diketahui:

- Saldo dompet dihitung dari `pendapatan - pengeluaran - transfer keluar + transfer masuk`. Transaksi yang dihapus lunak tidak ikut dihitung.
- Tagihan selalu dibuat dengan status lunas dan sekaligus membuat satu entri transaksi.
- Transaksi titipan menggeser saldo dompet, tapi tidak dihitung sebagai pendapatan atau pengeluaran.


