# CashBay

CashBay adalah aplikasi pencatatan keuangan pribadi berbasis Flutter yang berjalan sepenuhnya offline. Semua data disimpan di SQLite lokal dan tidak membutuhkan server. Aplikasi ini mencatat pemasukan, pengeluaran, transfer antar dompet, serta tagihan utang dan piutang. Nilai transaksi ditampilkan dalam Rupiah.

## Dukungan Platform

* **Android**
* **iOS** (Beta)



## Fitur

- Dashboard menampilkan total saldo, ringkasan pemasukan dan pengeluaran, saldo tagihan (saya dan orang), serta transaksi terbaru.
- Transaksi dapat dibuat sebagai pendapatan, pengeluaran, transfer antar dompet (Cash dan E-Wallet), atau tagihan. Setiap transaksi dapat disertai foto, catatan, kategori, tanggal, dan metode pembayaran.
- Riwayat transaksi dikelompokkan berdasarkan tanggal dan dapat dicari serta difilter berdasarkan tipe.
- Riwayat dapat diedit dan dihapus. Edit dibatasi pada deskripsi, catatan, dan foto, sedangkan penghapusan bersifat lunak dan tidak mengubah saldo.
- Tagihan dikelola sebagai utang dan piutang, lengkap dengan status pembayaran dan riwayat pembayaran.
- Kategori untuk pemasukan dan pengeluaran dapat dikelola; tersedia satu set kategori bawaan.
- Data dapat dihapus seluruhnya, diekspor, atau diimpor sebagai file JSON dari halaman Pengaturan.

Layar Laporan (grafik arus kas) dan Chat AI sudah disiapkan di dalam kode, tetapi belum diaktifkan pada navigasi bawah.

## Teknologi

- Flutter / Dart 3.11.1
- Provider untuk manajemen state
- sqflite untuk penyimpanan SQLite
- sqflite_common_ffi untuk pengujian dan desktop
- intl untuk format Rupiah dan tanggal
- image_picker untuk unggah foto
- path_provider untuk lokasi file backup
- fl_chart untuk grafik laporan

Tema antarmuka memakai Material 3 dengan warna monokrom dan font SF Pro.

## Instalasi

Pastikan Flutter telah terpasang, lalu jalankan perintah berikut.

```
flutter pub get
flutter run
```

## Testing

```
flutter test
flutter test integration_test/ -d windows
```

## Struktur Proyek

```
lib/
├── core/
│   ├── database/       # Inisialisasi dan migrasi SQLite
│   ├── theme/          # Tema aplikasi
│   ├── utils/          # Formatter dan validasi
│   └── widgets/        # Widget bersama
└── features/
    ├── dashboard/      # Dompet dan beranda
    ├── transactions/   # Transaksi, riwayat, dan detail
    ├── debts/          # Tagihan utang dan piutang
    ├── categories/     # Kelola kategori
    ├── report/         # Laporan (grafik)
    ├── chat/           # Chat AI
    └── settings/       # Pengaturan dan backup
```

Setiap fitur dipisahkan menjadi lapisan data (model dan repository) dan lapisan presentasi (layar dan provider).

## Skema Data

Tabel yang digunakan: `wallets`, `categories`, `transactions`, `debts`, `debt_payments`.

Beberapa aturan yang perlu diketahui:

- Saldo dompet dihitung dari `pendapatan - pengeluaran - transfer keluar + transfer masuk`. Transaksi yang dihapus secara lunak tidak ikut dihitung.
- Tagihan selalu dibuat dengan status lunas dan sekaligus membuat satu entri transaksi.

