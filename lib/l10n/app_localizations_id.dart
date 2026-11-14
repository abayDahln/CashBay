// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class LId extends L {
  LId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'CashBay';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get history => 'Riwayat';

  @override
  String get analytics => 'Analitik';

  @override
  String get settings => 'Pengaturan';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get profileName => 'Nama';

  @override
  String get profileNameRequired => 'Nama tidak boleh kosong';

  @override
  String get profileBio => 'Bio';

  @override
  String get profileGender => 'Jenis Kelamin';

  @override
  String get profileGenderMale => 'Laki-laki';

  @override
  String get profileGenderFemale => 'Perempuan';

  @override
  String get profileGenderOther => 'Lainnya';

  @override
  String get profileBirthDate => 'Tanggal Lahir';

  @override
  String get profileNotSet => 'Belum diisi';

  @override
  String get profileChangePhoto => 'Ganti Foto';

  @override
  String get back => 'Kembali';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get add => 'Tambah';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Hapus';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Terapkan';

  @override
  String get close => 'Tutup';

  @override
  String get all => 'Semua';

  @override
  String get cash => 'Cash';

  @override
  String get ewallet => 'E-Wallet';

  @override
  String get income => 'Pendapatan';

  @override
  String get expense => 'Pengeluaran';

  @override
  String get transfer => 'Transfer';

  @override
  String get titipan => 'Titipan';

  @override
  String get titipanSaya => 'Titipan Saya';

  @override
  String get titipanOrang => 'Titipan Orang';

  @override
  String get totalBalance => 'Total Saldo';

  @override
  String get thisMonth => 'Bulan Ini';

  @override
  String get incomeLabel => 'Pendapatan';

  @override
  String get expenseLabel => 'Pengeluaran';

  @override
  String get titipanPiutang => 'Titipan & Piutang';

  @override
  String get recentTransactions => 'Transaksi Terbaru';

  @override
  String get transactionsLabel => 'Transaksi';

  @override
  String get viewAll => 'Lihat Semua';

  @override
  String get noTransactions => 'Belum ada transaksi';

  @override
  String get noTransactionsHint =>
      'Transaksi yang kamu catat akan muncul di sini';

  @override
  String idLabel(int id) {
    return 'ID: $id';
  }

  @override
  String get addTransaction => 'Tambah Transaksi';

  @override
  String get detailMain => 'Detail utama';

  @override
  String get fundAndTime => 'Sumber dana & waktu';

  @override
  String get notesAndAttachment => 'Catatan & lampiran';

  @override
  String get titipanDirection => 'Arah Titipan';

  @override
  String get amountTransaction => 'Nominal transaksi';

  @override
  String get clearAmount => 'Kosongkan nominal';

  @override
  String get tagOptional => 'Tag (opsional)';

  @override
  String get newTag => 'Tag baru';

  @override
  String get tagName => 'Nama tag';

  @override
  String get tagNameHint => 'Contoh: Liburan';

  @override
  String get descriptionTransfer => 'Keterangan (opsional)';

  @override
  String get descriptionIncome => 'Sumber Pendapatan';

  @override
  String get descriptionExpense => 'Nama Transaksi';

  @override
  String get descriptionHintTransfer => 'Contoh: Pindah ke E-Wallet';

  @override
  String get descriptionHintIncome => 'Contoh: Gaji, Freelance';

  @override
  String get descriptionHintExpense => 'Contoh: Makan siang, Bensin';

  @override
  String get from => 'Dari';

  @override
  String get to => 'Ke';

  @override
  String get swapWallet => 'Tukar dompet';

  @override
  String get paymentMethod => 'Metode Pembayaran';

  @override
  String get destinationFund => 'Tujuan Dana';

  @override
  String get sourceFund => 'Sumber Dana';

  @override
  String balanceLabel(String amount) {
    return 'Saldo: $amount';
  }

  @override
  String get titipanName => 'Nama Titipan';

  @override
  String get titipanNameHint => 'Contoh: Titip uang ke Budi';

  @override
  String get titipanReceiver => 'Nama Penerima Titipan';

  @override
  String get titipanGiver => 'Nama Penitip';

  @override
  String get titipanReceiverHint => 'Ke siapa Anda titip?';

  @override
  String get titipanGiverHint => 'Siapa yang nitip?';

  @override
  String get nameLabel => 'Nama';

  @override
  String get dueDate => 'Tanggal Jatuh Tempo';

  @override
  String get transactionDate => 'Tanggal Transaksi';

  @override
  String get noteOptional => 'Catatan (opsional)';

  @override
  String get noteHintTitipan => 'Catatan titipan...';

  @override
  String get noteHint => 'Tambahkan catatan...';

  @override
  String get attachmentOptional => 'Lampiran Foto (opsional)';

  @override
  String get removePhoto => 'Hapus foto';

  @override
  String get attachmentPhoto => 'Lampiran foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get walletUnavailable => 'Dompet belum tersedia, muat ulang aplikasi';

  @override
  String walletNotFound(String name) {
    return 'Dompet $name tidak ditemukan';
  }

  @override
  String get walletMustDiffer => 'Dompet asal dan tujuan harus berbeda';

  @override
  String transferExceedsBalance(String amount) {
    return 'Nominal melebihi saldo ($amount)';
  }

  @override
  String get allBalance => 'Semua';

  @override
  String transferTo(String name) {
    return 'Transfer ke $name';
  }

  @override
  String get saved => 'Berhasil disimpan';

  @override
  String get saveFailed => 'Gagal menyimpan';

  @override
  String get cashIn => 'Uang Masuk';

  @override
  String get cashOut => 'Uang Keluar';

  @override
  String get searchTransaction => 'Cari transaksi...';

  @override
  String get clearSearch => 'Hapus pencarian';

  @override
  String get notFound => 'Tidak ditemukan';

  @override
  String get tryOtherKeyword => 'Coba kata kunci lain';

  @override
  String get noTxForFilter => 'Tidak ada transaksi untuk filter ini';

  @override
  String get today => 'Hari Ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get filter => 'Filter';

  @override
  String get detailTitipan => 'Detail Titipan';

  @override
  String get detailTitipanOrang => 'Detail Titipan Orang';

  @override
  String get detailPengembalian => 'Detail Pengembalian';

  @override
  String get detailPenerimaan => 'Detail Penerimaan';

  @override
  String get detailTransfer => 'Detail Transfer';

  @override
  String get detailIncome => 'Detail Pendapatan';

  @override
  String get detailExpense => 'Detail Pengeluaran';

  @override
  String get attachment => 'Lampiran';

  @override
  String get date => 'Tanggal';

  @override
  String get method => 'Metode';

  @override
  String get sourceWallet => 'Dompet Asal';

  @override
  String get destinationWallet => 'Dompet Tujuan';

  @override
  String get wallet => 'Dompet';

  @override
  String get description => 'Deskripsi';

  @override
  String get note => 'Catatan';

  @override
  String get information => 'Informasi';

  @override
  String get transactionInfo => 'Informasi transaksi';

  @override
  String get editTransaction => 'Ubah Transaksi';

  @override
  String get deleteTransaction => 'Hapus Transaksi';

  @override
  String get deleteHistoryQ => 'Hapus Riwayat?';

  @override
  String get deleteHistoryDesc =>
      'Riwayat ini akan disembunyikan dan tidak akan memengaruhi saldo saat ini.';

  @override
  String get historyDeleted => 'Riwayat berhasil dihapus';

  @override
  String get deleteFailed => 'Gagal menghapus';

  @override
  String get kindNotEditable => 'Jenis transaksi tidak dapat diubah.';

  @override
  String get titipanEditHint => 'Titipan diubah dari layar detail titipan.';

  @override
  String get amount => 'Nominal';

  @override
  String get chooseWallet => 'Pilih dompet';

  @override
  String get addPhoto => 'Tambah Foto';

  @override
  String get changePhoto => 'Ganti Foto';

  @override
  String get undoNewPhoto => 'Batalkan Foto Baru';

  @override
  String get noPhoto => 'Tidak ada foto';

  @override
  String get filterTitipan => 'Filter titipan';

  @override
  String get status => 'Status';

  @override
  String get belumLunas => 'Belum Lunas';

  @override
  String get lunas => 'Lunas';

  @override
  String get dateRange => 'Rentang Tanggal';

  @override
  String get chooseDateRange => 'Pilih rentang tanggal';

  @override
  String get chooseDate => 'Pilih tanggal';

  @override
  String get clearDateFilter => 'Hapus filter tanggal';

  @override
  String get addTitipan => 'Tambah titipan';

  @override
  String get remainingTitipanSaya => 'Sisa titipan saya';

  @override
  String get remainingTitipanOrang => 'Sisa titipan orang';

  @override
  String get noActiveTitipan => 'Tidak ada titipan belum lunas';

  @override
  String activeTitipanCount(int count) {
    return '$count titipan belum lunas';
  }

  @override
  String get thisWeek => 'Minggu Ini';

  @override
  String get previous => 'Sebelumnya';

  @override
  String get noTitipanMatch => 'Tidak ada titipan yang cocok';

  @override
  String get changeOrResetFilter => 'Coba ubah atau reset filter';

  @override
  String get resetFilter => 'Reset Filter';

  @override
  String get noTitipan => 'Belum ada titipan';

  @override
  String get noTitipanOrang => 'Belum ada titipan orang';

  @override
  String get noTitipanHint => 'Catat uang yang Anda titipkan ke orang lain';

  @override
  String get noTitipanOrangHint => 'Catat uang orang lain yang Anda pegang';

  @override
  String get addTitipanOrang => 'Tambah Titipan Orang';

  @override
  String get paid => 'dibayar';

  @override
  String get received => 'diterima';

  @override
  String paidFrom(String paid, String total) {
    return '$paid dibayar dari $total';
  }

  @override
  String receivedFrom(String received, String total) {
    return '$received diterima dari $total';
  }

  @override
  String get editTitipanAmount => 'Ubah nominal titipan';

  @override
  String get remaining => 'Sisa';

  @override
  String get totalTitipan => 'Total Titipan';

  @override
  String get totalTitipanOrang => 'Total Titipan Orang';

  @override
  String get hasPaid => 'Telah Dibayar';

  @override
  String get hasReceived => 'Telah Diterima';

  @override
  String get dueDateLabel => 'Jatuh tempo';

  @override
  String get noReturnHistory => 'Belum ada histori pengembalian';

  @override
  String get returnHistory => 'Histori Pengembalian';

  @override
  String get receiveReturn => 'Terima Pengembalian';

  @override
  String get returnMoney => 'Kembalikan Uang';

  @override
  String get returnRecorded => 'Pengembalian berhasil dicatat';

  @override
  String get editTitipanAmountTitle => 'Ubah Nominal Titipan';

  @override
  String get editReturnTitle => 'Ubah Pengembalian';

  @override
  String currentRemaining(String amount) {
    return 'Sisa saat ini $amount';
  }

  @override
  String maxReturn(String amount) {
    return 'Maksimal $amount';
  }

  @override
  String get titipanAmountUpdated => 'Nominal titipan diperbarui';

  @override
  String get returnUpdated => 'Pengembalian diperbarui';

  @override
  String exceedsRemaining(String amount) {
    return 'Melebihi sisa titipan ($amount)';
  }

  @override
  String get returnDate => 'Tanggal pengembalian';

  @override
  String saveFailedDetail(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get amountLabel => 'Jumlah';

  @override
  String remainingTitipan(String amount) {
    return 'Sisa titipan $amount';
  }

  @override
  String payOff(String amount) {
    return 'Lunasi $amount';
  }

  @override
  String get walletIn => 'Masuk ke dompet';

  @override
  String get walletOut => 'Keluar dari dompet';

  @override
  String get tagTransactions => 'Tag Transaksi';

  @override
  String get addTag => 'Tambah tag';

  @override
  String noTag(String type) {
    return 'Belum ada tag $type';
  }

  @override
  String get addTagHint => 'Tambah tag untuk mengelompokkan transaksi';

  @override
  String get addTagLabel => 'Tambah Tag';

  @override
  String get defaultBadge => 'Bawaan';

  @override
  String get tagOptions => 'Opsi tag';

  @override
  String get tagUpdated => 'Tag diperbarui';

  @override
  String get tagAdded => 'Tag ditambahkan';

  @override
  String tagInUse(String name) {
    return 'Tag \"$name\" masih digunakan transaksi';
  }

  @override
  String checkTagFailed(String error) {
    return 'Gagal memeriksa tag: $error';
  }

  @override
  String get deleteTagQ => 'Hapus Tag?';

  @override
  String deleteTagDefault(String name) {
    return 'Tag bawaan \"$name\" akan dihapus permanen.';
  }

  @override
  String deleteTagConfirm(String name) {
    return 'Tag \"$name\" akan dihapus permanen.';
  }

  @override
  String get tagDeleted => 'Tag dihapus';

  @override
  String get tagCannotDelete => 'Tag tidak bisa dihapus (masih digunakan)';

  @override
  String deleteTagFailed(String error) {
    return 'Gagal menghapus tag: $error';
  }

  @override
  String get tagNameField => 'Nama Tag';

  @override
  String get tagNameSample => 'Contoh: Gaji, Makan, Transport';

  @override
  String tagDuplicate(String type) {
    return 'Tag $type dengan nama ini sudah ada';
  }

  @override
  String get tagSaveFailed => 'Gagal menyimpan tag';

  @override
  String tagSaveFailedDetail(String error) {
    return 'Gagal menyimpan tag: $error';
  }

  @override
  String get editTag => 'Edit Tag';

  @override
  String get iconSection => 'Ikon';

  @override
  String get pendapatanLower => 'pendapatan';

  @override
  String get pengeluaranLower => 'pengeluaran';

  @override
  String get iconSalary => 'Gaji';

  @override
  String get iconBusiness => 'Bisnis';

  @override
  String get iconGift => 'Hadiah';

  @override
  String get iconInvestment => 'Investasi';

  @override
  String get iconFood => 'Makanan';

  @override
  String get iconTransport => 'Transportasi';

  @override
  String get iconShopping => 'Belanja';

  @override
  String get iconHealth => 'Kesehatan';

  @override
  String get iconEducation => 'Pendidikan';

  @override
  String get iconEntertainment => 'Hiburan';

  @override
  String get iconOther => 'Lainnya';

  @override
  String get chartCashFlow => 'Grafik Arus Kas';

  @override
  String get noData => 'Tidak ada data';

  @override
  String get noDataPeriod => 'Belum ada transaksi pada periode ini';

  @override
  String get modeDaily => 'Harian';

  @override
  String get modeMonthly => 'Bulan';

  @override
  String get modeYearly => 'Tahun';

  @override
  String get previousPeriod => 'Sebelumnya';

  @override
  String get nextPeriod => 'Berikutnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun berikutnya';

  @override
  String get customRange => 'Rentang Kustom';

  @override
  String get customFilter => 'Filter';

  @override
  String get rangeStart => 'Mulai';

  @override
  String get rangeEnd => 'Sampai';

  @override
  String get resetRange => 'Reset';

  @override
  String get applyRange => 'Terapkan';

  @override
  String get selectMonthStart => 'Pilih bulan mulai';

  @override
  String get selectMonthEnd => 'Pilih bulan sampai';

  @override
  String get selectYearStart => 'Pilih tahun mulai';

  @override
  String get selectYearEnd => 'Pilih tahun sampai';

  @override
  String get rangeMaxMonths => 'Rentang maksimal 12 bulan';

  @override
  String get rangeMaxYears => 'Rentang maksimal 12 tahun';

  @override
  String get rangeEndBeforeStart => 'Bulan/tahun akhir harus setelah awal';

  @override
  String get rangeFuture => 'Tidak boleh melewati bulan/tahun ini';

  @override
  String get allData => 'Semua data';

  @override
  String get allTime => 'Semua';

  @override
  String get difference => 'Selisih';

  @override
  String get surplus => 'Surplus';

  @override
  String get deficit => 'Defisit';

  @override
  String get themeMode => 'Mode Tema';

  @override
  String get modeSystem => 'Sistem';

  @override
  String get modeLight => 'Terang';

  @override
  String get modeDark => 'Gelap';

  @override
  String get accentColor => 'Warna Aksen';

  @override
  String get customColor => 'Warna khusus';

  @override
  String get chooseCustomColor => 'Pilih warna khusus';

  @override
  String get dataManagement => 'Manajemen Data';

  @override
  String get manageTags => 'Kelola Tag Transaksi';

  @override
  String get manageTagsSub => 'Tambah, ubah, atau hapus tag transaksi';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportSub => 'Simpan backup ke file JSON';

  @override
  String get importData => 'Import Data';

  @override
  String get importSub => 'Pulihkan dari file backup';

  @override
  String get deleteAllData => 'Hapus Semua Data';

  @override
  String get resetApp => 'Reset aplikasi ke kondisi awal';

  @override
  String get about => 'Tentang';

  @override
  String get appVersion => 'v1.0.0 - Personal Finance App';

  @override
  String get followSystem => 'Ikuti sistem';

  @override
  String get chooseAccentColor => 'Pilih Warna Aksen';

  @override
  String get hue => 'Rona';

  @override
  String get saturation => 'Saturasi';

  @override
  String get brightness => 'Kecerahan';

  @override
  String get colorBlue => 'Biru';

  @override
  String get colorGreen => 'Hijau';

  @override
  String get colorRed => 'Merah';

  @override
  String get colorPurple => 'Ungu';

  @override
  String get colorOrange => 'Oranye';

  @override
  String get colorTeal => 'Teal';

  @override
  String get appearanceTheme => 'Tampilan & Tema';

  @override
  String get deleteAllQ => 'Hapus Semua Data?';

  @override
  String get deleteAllDesc =>
      'Semua data transaksi, dompet, kategori, dan titipan akan dihapus. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get typeDeleteConfirm => 'Ketik CONFIRM untuk konfirmasi';

  @override
  String get deleteAllConfirm => 'Hapus Semua';

  @override
  String get allDeleted => 'Semua data berhasil dihapus';

  @override
  String deleteAllFailed(String error) {
    return 'Gagal menghapus data: $error';
  }

  @override
  String exportSuccess(String path) {
    return 'Data berhasil diexport ke $path';
  }

  @override
  String exportFailed(String error) {
    return 'Gagal export: $error';
  }

  @override
  String get importInvalid => 'Format file backup tidak valid';

  @override
  String get importSuccess => 'Data berhasil diimport';

  @override
  String importFailed(String error) {
    return 'Gagal import: $error';
  }

  @override
  String get importQ => 'Import Data?';

  @override
  String importDesc(String when) {
    return 'Data saat ini akan diganti dengan isi file backup$when. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get replaceData => 'Ganti Data';

  @override
  String get language => 'Bahasa';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageEnglish => 'Inggris';

  @override
  String get languagePicked => 'Bahasa diubah';

  @override
  String get chatGreeting =>
      'Halo! Saya asisten keuangan Anda. Tanyakan apa saja tentang transaksi dan keuangan Anda.';

  @override
  String get chatDeveloping => 'Fitur chat bot sedang dikembangkan.';

  @override
  String get chatHint => 'Ketik pesan...';

  @override
  String get sendMessage => 'Kirim pesan';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String chooseTag(Object type) {
    return 'Tag $type dengan nama ini sudah ada';
  }

  @override
  String backupExportedAt(String date) {
    return ' (dibuat $date)';
  }

  @override
  String titipanOpenCount(int count) {
    return '$count Terbuka';
  }

  @override
  String get addTitipanTitle => 'Tambah Titipan';

  @override
  String get personName => 'Nama Orang';

  @override
  String get progressPayment => 'Progres pembayaran';

  @override
  String addAmountTooltip(String amount) {
    return 'Tambah $amount';
  }

  @override
  String get preset3Days => '3 Hari';

  @override
  String get preset1Week => '1 Minggu';

  @override
  String get preset2Weeks => '2 Minggu';

  @override
  String get preset1Month => '1 Bulan';

  @override
  String get preset3Months => '3 Bulan';

  @override
  String get preset1Year => '1 Tahun';

  @override
  String transactionCount(int count) {
    return '$count transaksi';
  }

  @override
  String get amountRequired => 'Nominal tidak boleh kosong';

  @override
  String get amountPositive => 'Nominal harus lebih dari 0';

  @override
  String amountMin(String min) {
    return 'Nominal minimal $min';
  }

  @override
  String get amountTooLarge => 'Nominal terlalu besar';

  @override
  String amountMax(String max) {
    return 'Nominal maksimal $max';
  }

  @override
  String get photoNotFound => 'File foto tidak ditemukan';

  @override
  String get photoFormat => 'Format foto harus JPG atau PNG';

  @override
  String get photoTooLarge => 'Ukuran foto maksimal 10 MB';

  @override
  String fieldRequired(String field) {
    return '$field tidak boleh kosong';
  }

  @override
  String fieldMinChars(String field, int n) {
    return '$field minimal $n karakter';
  }

  @override
  String fieldMaxChars(String field, int n) {
    return '$field maksimal $n karakter';
  }

  @override
  String fieldNeedsLetterOrDigit(String field) {
    return '$field harus mengandung huruf atau angka';
  }

  @override
  String saveFailedError(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get tagExists => 'Tag dengan nama ini sudah ada';

  @override
  String totalBelowReturned(String amount) {
    return 'Total tidak boleh kurang dari yang sudah dikembalikan ($amount)';
  }

  @override
  String get titipanIncomplete => 'Data titipan tidak lengkap';

  @override
  String returnExceedsTotal(String amount) {
    return 'Pengembalian tidak boleh melebihi sisa titipan ($amount)';
  }

  @override
  String get returnIncomplete => 'Data pengembalian tidak lengkap';

  @override
  String get notifTitipanTitle => 'Jatuh tempo titipan';

  @override
  String notifTitipanBody(String name) {
    return 'Titipan dengan $name sudah jatuh tempo hari ini.';
  }

  @override
  String get notifChannelName => 'Jatuh Tempo Titipan';

  @override
  String get notifChannelDesc => 'Pengingat jatuh tempo titipan';
}
