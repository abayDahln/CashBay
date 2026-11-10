import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'CashBay'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @history.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get history;

  /// No description provided for @analytics.
  ///
  /// In id, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @add.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @reset.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In id, this message translates to:
  /// **'Terapkan'**
  String get apply;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get close;

  /// No description provided for @all.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get all;

  /// No description provided for @cash.
  ///
  /// In id, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @ewallet.
  ///
  /// In id, this message translates to:
  /// **'E-Wallet'**
  String get ewallet;

  /// No description provided for @income.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get expense;

  /// No description provided for @transfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @titipan.
  ///
  /// In id, this message translates to:
  /// **'Titipan'**
  String get titipan;

  /// No description provided for @titipanSaya.
  ///
  /// In id, this message translates to:
  /// **'Titipan Saya'**
  String get titipanSaya;

  /// No description provided for @titipanOrang.
  ///
  /// In id, this message translates to:
  /// **'Titipan Orang'**
  String get titipanOrang;

  /// No description provided for @totalBalance.
  ///
  /// In id, this message translates to:
  /// **'Total Saldo'**
  String get totalBalance;

  /// No description provided for @thisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get thisMonth;

  /// No description provided for @incomeLabel.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get expenseLabel;

  /// No description provided for @titipanPiutang.
  ///
  /// In id, this message translates to:
  /// **'Titipan & Piutang'**
  String get titipanPiutang;

  /// No description provided for @recentTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Terbaru'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat Semua'**
  String get viewAll;

  /// No description provided for @noTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get noTransactions;

  /// No description provided for @noTransactionsHint.
  ///
  /// In id, this message translates to:
  /// **'Transaksi yang kamu catat akan muncul di sini'**
  String get noTransactionsHint;

  /// No description provided for @idLabel.
  ///
  /// In id, this message translates to:
  /// **'ID: {id}'**
  String idLabel(int id);

  /// No description provided for @addTransaction.
  ///
  /// In id, this message translates to:
  /// **'Tambah Transaksi'**
  String get addTransaction;

  /// No description provided for @detailMain.
  ///
  /// In id, this message translates to:
  /// **'Detail utama'**
  String get detailMain;

  /// No description provided for @fundAndTime.
  ///
  /// In id, this message translates to:
  /// **'Sumber dana & waktu'**
  String get fundAndTime;

  /// No description provided for @notesAndAttachment.
  ///
  /// In id, this message translates to:
  /// **'Catatan & lampiran'**
  String get notesAndAttachment;

  /// No description provided for @titipanDirection.
  ///
  /// In id, this message translates to:
  /// **'Arah Titipan'**
  String get titipanDirection;

  /// No description provided for @amountTransaction.
  ///
  /// In id, this message translates to:
  /// **'Nominal transaksi'**
  String get amountTransaction;

  /// No description provided for @clearAmount.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan nominal'**
  String get clearAmount;

  /// No description provided for @tagOptional.
  ///
  /// In id, this message translates to:
  /// **'Tag (opsional)'**
  String get tagOptional;

  /// No description provided for @newTag.
  ///
  /// In id, this message translates to:
  /// **'Tag baru'**
  String get newTag;

  /// No description provided for @tagName.
  ///
  /// In id, this message translates to:
  /// **'Nama tag'**
  String get tagName;

  /// No description provided for @tagNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Liburan'**
  String get tagNameHint;

  /// No description provided for @descriptionTransfer.
  ///
  /// In id, this message translates to:
  /// **'Keterangan (opsional)'**
  String get descriptionTransfer;

  /// No description provided for @descriptionIncome.
  ///
  /// In id, this message translates to:
  /// **'Sumber Pendapatan'**
  String get descriptionIncome;

  /// No description provided for @descriptionExpense.
  ///
  /// In id, this message translates to:
  /// **'Nama Transaksi'**
  String get descriptionExpense;

  /// No description provided for @descriptionHintTransfer.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Pindah ke E-Wallet'**
  String get descriptionHintTransfer;

  /// No description provided for @descriptionHintIncome.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Gaji, Freelance'**
  String get descriptionHintIncome;

  /// No description provided for @descriptionHintExpense.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Makan siang, Bensin'**
  String get descriptionHintExpense;

  /// No description provided for @from.
  ///
  /// In id, this message translates to:
  /// **'Dari'**
  String get from;

  /// No description provided for @to.
  ///
  /// In id, this message translates to:
  /// **'Ke'**
  String get to;

  /// No description provided for @swapWallet.
  ///
  /// In id, this message translates to:
  /// **'Tukar dompet'**
  String get swapWallet;

  /// No description provided for @paymentMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran'**
  String get paymentMethod;

  /// No description provided for @destinationFund.
  ///
  /// In id, this message translates to:
  /// **'Tujuan Dana'**
  String get destinationFund;

  /// No description provided for @sourceFund.
  ///
  /// In id, this message translates to:
  /// **'Sumber Dana'**
  String get sourceFund;

  /// No description provided for @balanceLabel.
  ///
  /// In id, this message translates to:
  /// **'Saldo: {amount}'**
  String balanceLabel(String amount);

  /// No description provided for @titipanName.
  ///
  /// In id, this message translates to:
  /// **'Nama Titipan'**
  String get titipanName;

  /// No description provided for @titipanNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Titip uang ke Budi'**
  String get titipanNameHint;

  /// No description provided for @titipanReceiver.
  ///
  /// In id, this message translates to:
  /// **'Nama Penerima Titipan'**
  String get titipanReceiver;

  /// No description provided for @titipanGiver.
  ///
  /// In id, this message translates to:
  /// **'Nama Penitip'**
  String get titipanGiver;

  /// No description provided for @titipanReceiverHint.
  ///
  /// In id, this message translates to:
  /// **'Ke siapa Anda titip?'**
  String get titipanReceiverHint;

  /// No description provided for @titipanGiverHint.
  ///
  /// In id, this message translates to:
  /// **'Siapa yang nitip?'**
  String get titipanGiverHint;

  /// No description provided for @nameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get nameLabel;

  /// No description provided for @dueDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Jatuh Tempo'**
  String get dueDate;

  /// No description provided for @transactionDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Transaksi'**
  String get transactionDate;

  /// No description provided for @noteOptional.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get noteOptional;

  /// No description provided for @noteHintTitipan.
  ///
  /// In id, this message translates to:
  /// **'Catatan titipan...'**
  String get noteHintTitipan;

  /// No description provided for @noteHint.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan catatan...'**
  String get noteHint;

  /// No description provided for @attachmentOptional.
  ///
  /// In id, this message translates to:
  /// **'Lampiran Foto (opsional)'**
  String get attachmentOptional;

  /// No description provided for @removePhoto.
  ///
  /// In id, this message translates to:
  /// **'Hapus foto'**
  String get removePhoto;

  /// No description provided for @attachmentPhoto.
  ///
  /// In id, this message translates to:
  /// **'Lampiran foto'**
  String get attachmentPhoto;

  /// No description provided for @camera.
  ///
  /// In id, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri'**
  String get gallery;

  /// No description provided for @walletUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Dompet belum tersedia, muat ulang aplikasi'**
  String get walletUnavailable;

  /// No description provided for @walletNotFound.
  ///
  /// In id, this message translates to:
  /// **'Dompet {name} tidak ditemukan'**
  String walletNotFound(String name);

  /// No description provided for @walletMustDiffer.
  ///
  /// In id, this message translates to:
  /// **'Dompet asal dan tujuan harus berbeda'**
  String get walletMustDiffer;

  /// No description provided for @transferTo.
  ///
  /// In id, this message translates to:
  /// **'Transfer ke {name}'**
  String transferTo(String name);

  /// No description provided for @saved.
  ///
  /// In id, this message translates to:
  /// **'Berhasil disimpan'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan'**
  String get saveFailed;

  /// No description provided for @searchTransaction.
  ///
  /// In id, this message translates to:
  /// **'Cari transaksi...'**
  String get searchTransaction;

  /// No description provided for @clearSearch.
  ///
  /// In id, this message translates to:
  /// **'Hapus pencarian'**
  String get clearSearch;

  /// No description provided for @notFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ditemukan'**
  String get notFound;

  /// No description provided for @tryOtherKeyword.
  ///
  /// In id, this message translates to:
  /// **'Coba kata kunci lain'**
  String get tryOtherKeyword;

  /// No description provided for @noTxForFilter.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi untuk filter ini'**
  String get noTxForFilter;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get yesterday;

  /// No description provided for @filter.
  ///
  /// In id, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @detailTitipan.
  ///
  /// In id, this message translates to:
  /// **'Detail Titipan'**
  String get detailTitipan;

  /// No description provided for @detailTitipanOrang.
  ///
  /// In id, this message translates to:
  /// **'Detail Titipan Orang'**
  String get detailTitipanOrang;

  /// No description provided for @detailPengembalian.
  ///
  /// In id, this message translates to:
  /// **'Detail Pengembalian'**
  String get detailPengembalian;

  /// No description provided for @detailPenerimaan.
  ///
  /// In id, this message translates to:
  /// **'Detail Penerimaan'**
  String get detailPenerimaan;

  /// No description provided for @detailTransfer.
  ///
  /// In id, this message translates to:
  /// **'Detail Transfer'**
  String get detailTransfer;

  /// No description provided for @detailIncome.
  ///
  /// In id, this message translates to:
  /// **'Detail Pendapatan'**
  String get detailIncome;

  /// No description provided for @detailExpense.
  ///
  /// In id, this message translates to:
  /// **'Detail Pengeluaran'**
  String get detailExpense;

  /// No description provided for @attachment.
  ///
  /// In id, this message translates to:
  /// **'Lampiran'**
  String get attachment;

  /// No description provided for @date.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get date;

  /// No description provided for @method.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get method;

  /// No description provided for @sourceWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet Asal'**
  String get sourceWallet;

  /// No description provided for @destinationWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet Tujuan'**
  String get destinationWallet;

  /// No description provided for @wallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get wallet;

  /// No description provided for @description.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get description;

  /// No description provided for @note.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get note;

  /// No description provided for @information.
  ///
  /// In id, this message translates to:
  /// **'Informasi'**
  String get information;

  /// No description provided for @transactionInfo.
  ///
  /// In id, this message translates to:
  /// **'Informasi transaksi'**
  String get transactionInfo;

  /// No description provided for @editTransaction.
  ///
  /// In id, this message translates to:
  /// **'Ubah Transaksi'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In id, this message translates to:
  /// **'Hapus Transaksi'**
  String get deleteTransaction;

  /// No description provided for @deleteHistoryQ.
  ///
  /// In id, this message translates to:
  /// **'Hapus Riwayat?'**
  String get deleteHistoryQ;

  /// No description provided for @deleteHistoryDesc.
  ///
  /// In id, this message translates to:
  /// **'Riwayat ini akan disembunyikan dan tidak akan memengaruhi saldo saat ini.'**
  String get deleteHistoryDesc;

  /// No description provided for @historyDeleted.
  ///
  /// In id, this message translates to:
  /// **'Riwayat berhasil dihapus'**
  String get historyDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus'**
  String get deleteFailed;

  /// No description provided for @kindNotEditable.
  ///
  /// In id, this message translates to:
  /// **'Jenis transaksi tidak dapat diubah.'**
  String get kindNotEditable;

  /// No description provided for @titipanEditHint.
  ///
  /// In id, this message translates to:
  /// **'Titipan diubah dari layar detail titipan.'**
  String get titipanEditHint;

  /// No description provided for @amount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get amount;

  /// No description provided for @chooseWallet.
  ///
  /// In id, this message translates to:
  /// **'Pilih dompet'**
  String get chooseWallet;

  /// No description provided for @addPhoto.
  ///
  /// In id, this message translates to:
  /// **'Tambah Foto'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ganti Foto'**
  String get changePhoto;

  /// No description provided for @undoNewPhoto.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Foto Baru'**
  String get undoNewPhoto;

  /// No description provided for @noPhoto.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada foto'**
  String get noPhoto;

  /// No description provided for @filterTitipan.
  ///
  /// In id, this message translates to:
  /// **'Filter titipan'**
  String get filterTitipan;

  /// No description provided for @status.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @belumLunas.
  ///
  /// In id, this message translates to:
  /// **'Belum Lunas'**
  String get belumLunas;

  /// No description provided for @lunas.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get lunas;

  /// No description provided for @dateRange.
  ///
  /// In id, this message translates to:
  /// **'Rentang Tanggal'**
  String get dateRange;

  /// No description provided for @chooseDateRange.
  ///
  /// In id, this message translates to:
  /// **'Pilih rentang tanggal'**
  String get chooseDateRange;

  /// No description provided for @chooseDate.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get chooseDate;

  /// No description provided for @clearDateFilter.
  ///
  /// In id, this message translates to:
  /// **'Hapus filter tanggal'**
  String get clearDateFilter;

  /// No description provided for @addTitipan.
  ///
  /// In id, this message translates to:
  /// **'Tambah titipan'**
  String get addTitipan;

  /// No description provided for @remainingTitipanSaya.
  ///
  /// In id, this message translates to:
  /// **'Sisa titipan saya'**
  String get remainingTitipanSaya;

  /// No description provided for @remainingTitipanOrang.
  ///
  /// In id, this message translates to:
  /// **'Sisa titipan orang'**
  String get remainingTitipanOrang;

  /// No description provided for @noActiveTitipan.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada titipan belum lunas'**
  String get noActiveTitipan;

  /// No description provided for @activeTitipanCount.
  ///
  /// In id, this message translates to:
  /// **'{count} titipan belum lunas'**
  String activeTitipanCount(int count);

  /// No description provided for @thisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get thisWeek;

  /// No description provided for @previous.
  ///
  /// In id, this message translates to:
  /// **'Sebelumnya'**
  String get previous;

  /// No description provided for @noTitipanMatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada titipan yang cocok'**
  String get noTitipanMatch;

  /// No description provided for @changeOrResetFilter.
  ///
  /// In id, this message translates to:
  /// **'Coba ubah atau reset filter'**
  String get changeOrResetFilter;

  /// No description provided for @resetFilter.
  ///
  /// In id, this message translates to:
  /// **'Reset Filter'**
  String get resetFilter;

  /// No description provided for @noTitipan.
  ///
  /// In id, this message translates to:
  /// **'Belum ada titipan'**
  String get noTitipan;

  /// No description provided for @noTitipanOrang.
  ///
  /// In id, this message translates to:
  /// **'Belum ada titipan orang'**
  String get noTitipanOrang;

  /// No description provided for @noTitipanHint.
  ///
  /// In id, this message translates to:
  /// **'Catat uang yang Anda titipkan ke orang lain'**
  String get noTitipanHint;

  /// No description provided for @noTitipanOrangHint.
  ///
  /// In id, this message translates to:
  /// **'Catat uang orang lain yang Anda pegang'**
  String get noTitipanOrangHint;

  /// No description provided for @addTitipanOrang.
  ///
  /// In id, this message translates to:
  /// **'Tambah Titipan Orang'**
  String get addTitipanOrang;

  /// No description provided for @paid.
  ///
  /// In id, this message translates to:
  /// **'dibayar'**
  String get paid;

  /// No description provided for @received.
  ///
  /// In id, this message translates to:
  /// **'diterima'**
  String get received;

  /// No description provided for @paidFrom.
  ///
  /// In id, this message translates to:
  /// **'{paid} dibayar dari {total}'**
  String paidFrom(String paid, String total);

  /// No description provided for @receivedFrom.
  ///
  /// In id, this message translates to:
  /// **'{received} diterima dari {total}'**
  String receivedFrom(String received, String total);

  /// No description provided for @editTitipanAmount.
  ///
  /// In id, this message translates to:
  /// **'Ubah nominal titipan'**
  String get editTitipanAmount;

  /// No description provided for @remaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get remaining;

  /// No description provided for @totalTitipan.
  ///
  /// In id, this message translates to:
  /// **'Total Titipan'**
  String get totalTitipan;

  /// No description provided for @totalTitipanOrang.
  ///
  /// In id, this message translates to:
  /// **'Total Titipan Orang'**
  String get totalTitipanOrang;

  /// No description provided for @hasPaid.
  ///
  /// In id, this message translates to:
  /// **'Telah Dibayar'**
  String get hasPaid;

  /// No description provided for @hasReceived.
  ///
  /// In id, this message translates to:
  /// **'Telah Diterima'**
  String get hasReceived;

  /// No description provided for @dueDateLabel.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo'**
  String get dueDateLabel;

  /// No description provided for @noReturnHistory.
  ///
  /// In id, this message translates to:
  /// **'Belum ada histori pengembalian'**
  String get noReturnHistory;

  /// No description provided for @returnHistory.
  ///
  /// In id, this message translates to:
  /// **'Histori Pengembalian'**
  String get returnHistory;

  /// No description provided for @receiveReturn.
  ///
  /// In id, this message translates to:
  /// **'Terima Pengembalian'**
  String get receiveReturn;

  /// No description provided for @returnMoney.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan Uang'**
  String get returnMoney;

  /// No description provided for @returnRecorded.
  ///
  /// In id, this message translates to:
  /// **'Pengembalian berhasil dicatat'**
  String get returnRecorded;

  /// No description provided for @editTitipanAmountTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Nominal Titipan'**
  String get editTitipanAmountTitle;

  /// No description provided for @editReturnTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Pengembalian'**
  String get editReturnTitle;

  /// No description provided for @currentRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa saat ini {amount}'**
  String currentRemaining(String amount);

  /// No description provided for @maxReturn.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {amount}'**
  String maxReturn(String amount);

  /// No description provided for @titipanAmountUpdated.
  ///
  /// In id, this message translates to:
  /// **'Nominal titipan diperbarui'**
  String get titipanAmountUpdated;

  /// No description provided for @returnUpdated.
  ///
  /// In id, this message translates to:
  /// **'Pengembalian diperbarui'**
  String get returnUpdated;

  /// No description provided for @exceedsRemaining.
  ///
  /// In id, this message translates to:
  /// **'Melebihi sisa titipan ({amount})'**
  String exceedsRemaining(String amount);

  /// No description provided for @returnDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal pengembalian'**
  String get returnDate;

  /// No description provided for @saveFailedDetail.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan: {error}'**
  String saveFailedDetail(String error);

  /// No description provided for @amountLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get amountLabel;

  /// No description provided for @remainingTitipan.
  ///
  /// In id, this message translates to:
  /// **'Sisa titipan {amount}'**
  String remainingTitipan(String amount);

  /// No description provided for @payOff.
  ///
  /// In id, this message translates to:
  /// **'Lunasi {amount}'**
  String payOff(String amount);

  /// No description provided for @walletIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke dompet'**
  String get walletIn;

  /// No description provided for @walletOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari dompet'**
  String get walletOut;

  /// No description provided for @tagTransactions.
  ///
  /// In id, this message translates to:
  /// **'Tag Transaksi'**
  String get tagTransactions;

  /// No description provided for @addTag.
  ///
  /// In id, this message translates to:
  /// **'Tambah tag'**
  String get addTag;

  /// No description provided for @noTag.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tag {type}'**
  String noTag(String type);

  /// No description provided for @addTagHint.
  ///
  /// In id, this message translates to:
  /// **'Tambah tag untuk mengelompokkan transaksi'**
  String get addTagHint;

  /// No description provided for @addTagLabel.
  ///
  /// In id, this message translates to:
  /// **'Tambah Tag'**
  String get addTagLabel;

  /// No description provided for @defaultBadge.
  ///
  /// In id, this message translates to:
  /// **'Bawaan'**
  String get defaultBadge;

  /// No description provided for @tagOptions.
  ///
  /// In id, this message translates to:
  /// **'Opsi tag'**
  String get tagOptions;

  /// No description provided for @tagUpdated.
  ///
  /// In id, this message translates to:
  /// **'Tag diperbarui'**
  String get tagUpdated;

  /// No description provided for @tagAdded.
  ///
  /// In id, this message translates to:
  /// **'Tag ditambahkan'**
  String get tagAdded;

  /// No description provided for @tagInUse.
  ///
  /// In id, this message translates to:
  /// **'Tag \"{name}\" masih digunakan transaksi'**
  String tagInUse(String name);

  /// No description provided for @checkTagFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memeriksa tag: {error}'**
  String checkTagFailed(String error);

  /// No description provided for @deleteTagQ.
  ///
  /// In id, this message translates to:
  /// **'Hapus Tag?'**
  String get deleteTagQ;

  /// No description provided for @deleteTagDefault.
  ///
  /// In id, this message translates to:
  /// **'Tag bawaan \"{name}\" akan dihapus permanen.'**
  String deleteTagDefault(String name);

  /// No description provided for @deleteTagConfirm.
  ///
  /// In id, this message translates to:
  /// **'Tag \"{name}\" akan dihapus permanen.'**
  String deleteTagConfirm(String name);

  /// No description provided for @tagDeleted.
  ///
  /// In id, this message translates to:
  /// **'Tag dihapus'**
  String get tagDeleted;

  /// No description provided for @tagCannotDelete.
  ///
  /// In id, this message translates to:
  /// **'Tag tidak bisa dihapus (masih digunakan)'**
  String get tagCannotDelete;

  /// No description provided for @deleteTagFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus tag: {error}'**
  String deleteTagFailed(String error);

  /// No description provided for @tagNameField.
  ///
  /// In id, this message translates to:
  /// **'Nama Tag'**
  String get tagNameField;

  /// No description provided for @tagNameSample.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Gaji, Makan, Transport'**
  String get tagNameSample;

  /// No description provided for @tagDuplicate.
  ///
  /// In id, this message translates to:
  /// **'Tag {type} dengan nama ini sudah ada'**
  String tagDuplicate(String type);

  /// No description provided for @tagSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan tag'**
  String get tagSaveFailed;

  /// No description provided for @tagSaveFailedDetail.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan tag: {error}'**
  String tagSaveFailedDetail(String error);

  /// No description provided for @editTag.
  ///
  /// In id, this message translates to:
  /// **'Edit Tag'**
  String get editTag;

  /// No description provided for @iconSection.
  ///
  /// In id, this message translates to:
  /// **'Ikon'**
  String get iconSection;

  /// No description provided for @pendapatanLower.
  ///
  /// In id, this message translates to:
  /// **'pendapatan'**
  String get pendapatanLower;

  /// No description provided for @pengeluaranLower.
  ///
  /// In id, this message translates to:
  /// **'pengeluaran'**
  String get pengeluaranLower;

  /// No description provided for @iconSalary.
  ///
  /// In id, this message translates to:
  /// **'Gaji'**
  String get iconSalary;

  /// No description provided for @iconBusiness.
  ///
  /// In id, this message translates to:
  /// **'Bisnis'**
  String get iconBusiness;

  /// No description provided for @iconGift.
  ///
  /// In id, this message translates to:
  /// **'Hadiah'**
  String get iconGift;

  /// No description provided for @iconInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get iconInvestment;

  /// No description provided for @iconFood.
  ///
  /// In id, this message translates to:
  /// **'Makanan'**
  String get iconFood;

  /// No description provided for @iconTransport.
  ///
  /// In id, this message translates to:
  /// **'Transportasi'**
  String get iconTransport;

  /// No description provided for @iconShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja'**
  String get iconShopping;

  /// No description provided for @iconHealth.
  ///
  /// In id, this message translates to:
  /// **'Kesehatan'**
  String get iconHealth;

  /// No description provided for @iconEducation.
  ///
  /// In id, this message translates to:
  /// **'Pendidikan'**
  String get iconEducation;

  /// No description provided for @iconEntertainment.
  ///
  /// In id, this message translates to:
  /// **'Hiburan'**
  String get iconEntertainment;

  /// No description provided for @iconOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get iconOther;

  /// No description provided for @chartCashFlow.
  ///
  /// In id, this message translates to:
  /// **'Grafik Arus Kas'**
  String get chartCashFlow;

  /// No description provided for @noData.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data'**
  String get noData;

  /// No description provided for @noDataPeriod.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi pada periode ini'**
  String get noDataPeriod;

  /// No description provided for @modeDaily.
  ///
  /// In id, this message translates to:
  /// **'Harian'**
  String get modeDaily;

  /// No description provided for @modeMonthly.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get modeMonthly;

  /// No description provided for @modeYearly.
  ///
  /// In id, this message translates to:
  /// **'Tahunan'**
  String get modeYearly;

  /// No description provided for @previousPeriod.
  ///
  /// In id, this message translates to:
  /// **'Sebelumnya'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In id, this message translates to:
  /// **'Berikutnya'**
  String get nextPeriod;

  /// No description provided for @previousYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun sebelumnya'**
  String get previousYear;

  /// No description provided for @nextYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun berikutnya'**
  String get nextYear;

  /// No description provided for @difference.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get difference;

  /// No description provided for @surplus.
  ///
  /// In id, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @deficit.
  ///
  /// In id, this message translates to:
  /// **'Defisit'**
  String get deficit;

  /// No description provided for @themeMode.
  ///
  /// In id, this message translates to:
  /// **'Mode Tema'**
  String get themeMode;

  /// No description provided for @modeSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get modeSystem;

  /// No description provided for @modeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get modeLight;

  /// No description provided for @modeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get modeDark;

  /// No description provided for @accentColor.
  ///
  /// In id, this message translates to:
  /// **'Warna Aksen'**
  String get accentColor;

  /// No description provided for @customColor.
  ///
  /// In id, this message translates to:
  /// **'Warna khusus'**
  String get customColor;

  /// No description provided for @chooseCustomColor.
  ///
  /// In id, this message translates to:
  /// **'Pilih warna khusus'**
  String get chooseCustomColor;

  /// No description provided for @dataManagement.
  ///
  /// In id, this message translates to:
  /// **'Manajemen Data'**
  String get dataManagement;

  /// No description provided for @manageTags.
  ///
  /// In id, this message translates to:
  /// **'Kelola Tag Transaksi'**
  String get manageTags;

  /// No description provided for @manageTagsSub.
  ///
  /// In id, this message translates to:
  /// **'Tambah, ubah, atau hapus tag transaksi'**
  String get manageTagsSub;

  /// No description provided for @exportData.
  ///
  /// In id, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportSub.
  ///
  /// In id, this message translates to:
  /// **'Simpan backup ke file JSON'**
  String get exportSub;

  /// No description provided for @importData.
  ///
  /// In id, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @importSub.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan dari file backup'**
  String get importSub;

  /// No description provided for @deleteAllData.
  ///
  /// In id, this message translates to:
  /// **'Hapus Semua Data'**
  String get deleteAllData;

  /// No description provided for @resetApp.
  ///
  /// In id, this message translates to:
  /// **'Reset aplikasi ke kondisi awal'**
  String get resetApp;

  /// No description provided for @about.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In id, this message translates to:
  /// **'v1.0.0 - Personal Finance App'**
  String get appVersion;

  /// No description provided for @followSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get followSystem;

  /// No description provided for @chooseAccentColor.
  ///
  /// In id, this message translates to:
  /// **'Pilih Warna Aksen'**
  String get chooseAccentColor;

  /// No description provided for @hue.
  ///
  /// In id, this message translates to:
  /// **'Rona'**
  String get hue;

  /// No description provided for @saturation.
  ///
  /// In id, this message translates to:
  /// **'Saturasi'**
  String get saturation;

  /// No description provided for @brightness.
  ///
  /// In id, this message translates to:
  /// **'Kecerahan'**
  String get brightness;

  /// No description provided for @colorBlue.
  ///
  /// In id, this message translates to:
  /// **'Biru'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In id, this message translates to:
  /// **'Hijau'**
  String get colorGreen;

  /// No description provided for @colorRed.
  ///
  /// In id, this message translates to:
  /// **'Merah'**
  String get colorRed;

  /// No description provided for @colorPurple.
  ///
  /// In id, this message translates to:
  /// **'Ungu'**
  String get colorPurple;

  /// No description provided for @colorOrange.
  ///
  /// In id, this message translates to:
  /// **'Oranye'**
  String get colorOrange;

  /// No description provided for @colorTeal.
  ///
  /// In id, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @appearanceTheme.
  ///
  /// In id, this message translates to:
  /// **'Tampilan & Tema'**
  String get appearanceTheme;

  /// No description provided for @deleteAllQ.
  ///
  /// In id, this message translates to:
  /// **'Hapus Semua Data?'**
  String get deleteAllQ;

  /// No description provided for @deleteAllDesc.
  ///
  /// In id, this message translates to:
  /// **'Semua data transaksi, dompet, kategori, dan titipan akan dihapus. Tindakan ini tidak dapat dibatalkan.'**
  String get deleteAllDesc;

  /// No description provided for @typeDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ketik CONFIRM untuk konfirmasi'**
  String get typeDeleteConfirm;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus Semua'**
  String get deleteAllConfirm;

  /// No description provided for @allDeleted.
  ///
  /// In id, this message translates to:
  /// **'Semua data berhasil dihapus'**
  String get allDeleted;

  /// No description provided for @deleteAllFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus data: {error}'**
  String deleteAllFailed(String error);

  /// No description provided for @exportSuccess.
  ///
  /// In id, this message translates to:
  /// **'Data berhasil diexport ke {path}'**
  String exportSuccess(String path);

  /// No description provided for @exportFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal export: {error}'**
  String exportFailed(String error);

  /// No description provided for @importInvalid.
  ///
  /// In id, this message translates to:
  /// **'Format file backup tidak valid'**
  String get importInvalid;

  /// No description provided for @importSuccess.
  ///
  /// In id, this message translates to:
  /// **'Data berhasil diimport'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal import: {error}'**
  String importFailed(String error);

  /// No description provided for @importQ.
  ///
  /// In id, this message translates to:
  /// **'Import Data?'**
  String get importQ;

  /// No description provided for @importDesc.
  ///
  /// In id, this message translates to:
  /// **'Data saat ini akan diganti dengan isi file backup{when}. Tindakan ini tidak dapat dibatalkan.'**
  String importDesc(String when);

  /// No description provided for @replaceData.
  ///
  /// In id, this message translates to:
  /// **'Ganti Data'**
  String get replaceData;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @languageIndonesian.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In id, this message translates to:
  /// **'Inggris'**
  String get languageEnglish;

  /// No description provided for @languagePicked.
  ///
  /// In id, this message translates to:
  /// **'Bahasa diubah'**
  String get languagePicked;

  /// No description provided for @chatGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo! Saya asisten keuangan Anda. Tanyakan apa saja tentang transaksi dan keuangan Anda.'**
  String get chatGreeting;

  /// No description provided for @chatDeveloping.
  ///
  /// In id, this message translates to:
  /// **'Fitur chat bot sedang dikembangkan.'**
  String get chatDeveloping;

  /// No description provided for @chatHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik pesan...'**
  String get chatHint;

  /// No description provided for @sendMessage.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesan'**
  String get sendMessage;

  /// No description provided for @errorPrefix.
  ///
  /// In id, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @chooseTag.
  ///
  /// In id, this message translates to:
  /// **'Tag {type} dengan nama ini sudah ada'**
  String chooseTag(Object type);

  /// No description provided for @backupExportedAt.
  ///
  /// In id, this message translates to:
  /// **' (dibuat {date})'**
  String backupExportedAt(String date);

  /// No description provided for @titipanOpenCount.
  ///
  /// In id, this message translates to:
  /// **'{count} Terbuka'**
  String titipanOpenCount(int count);

  /// No description provided for @addTitipanTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Titipan'**
  String get addTitipanTitle;

  /// No description provided for @personName.
  ///
  /// In id, this message translates to:
  /// **'Nama Orang'**
  String get personName;

  /// No description provided for @progressPayment.
  ///
  /// In id, this message translates to:
  /// **'Progres pembayaran'**
  String get progressPayment;

  /// No description provided for @addAmountTooltip.
  ///
  /// In id, this message translates to:
  /// **'Tambah {amount}'**
  String addAmountTooltip(String amount);

  /// No description provided for @preset3Days.
  ///
  /// In id, this message translates to:
  /// **'3 Hari'**
  String get preset3Days;

  /// No description provided for @preset1Week.
  ///
  /// In id, this message translates to:
  /// **'1 Minggu'**
  String get preset1Week;

  /// No description provided for @preset2Weeks.
  ///
  /// In id, this message translates to:
  /// **'2 Minggu'**
  String get preset2Weeks;

  /// No description provided for @preset1Month.
  ///
  /// In id, this message translates to:
  /// **'1 Bulan'**
  String get preset1Month;

  /// No description provided for @preset3Months.
  ///
  /// In id, this message translates to:
  /// **'3 Bulan'**
  String get preset3Months;

  /// No description provided for @preset1Year.
  ///
  /// In id, this message translates to:
  /// **'1 Tahun'**
  String get preset1Year;

  /// No description provided for @transactionCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi'**
  String transactionCount(int count);

  /// No description provided for @amountRequired.
  ///
  /// In id, this message translates to:
  /// **'Nominal tidak boleh kosong'**
  String get amountRequired;

  /// No description provided for @amountPositive.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih dari 0'**
  String get amountPositive;

  /// No description provided for @amountMin.
  ///
  /// In id, this message translates to:
  /// **'Nominal minimal {min}'**
  String amountMin(String min);

  /// No description provided for @amountTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Nominal terlalu besar'**
  String get amountTooLarge;

  /// No description provided for @amountMax.
  ///
  /// In id, this message translates to:
  /// **'Nominal maksimal {max}'**
  String amountMax(String max);

  /// No description provided for @photoNotFound.
  ///
  /// In id, this message translates to:
  /// **'File foto tidak ditemukan'**
  String get photoNotFound;

  /// No description provided for @photoFormat.
  ///
  /// In id, this message translates to:
  /// **'Format foto harus JPG atau PNG'**
  String get photoFormat;

  /// No description provided for @photoTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Ukuran foto maksimal 10 MB'**
  String get photoTooLarge;

  /// No description provided for @fieldRequired.
  ///
  /// In id, this message translates to:
  /// **'{field} tidak boleh kosong'**
  String fieldRequired(String field);

  /// No description provided for @fieldMinChars.
  ///
  /// In id, this message translates to:
  /// **'{field} minimal {n} karakter'**
  String fieldMinChars(String field, int n);

  /// No description provided for @fieldMaxChars.
  ///
  /// In id, this message translates to:
  /// **'{field} maksimal {n} karakter'**
  String fieldMaxChars(String field, int n);

  /// No description provided for @fieldNeedsLetterOrDigit.
  ///
  /// In id, this message translates to:
  /// **'{field} harus mengandung huruf atau angka'**
  String fieldNeedsLetterOrDigit(String field);

  /// No description provided for @saveFailedError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan: {error}'**
  String saveFailedError(String error);

  /// No description provided for @tagExists.
  ///
  /// In id, this message translates to:
  /// **'Tag dengan nama ini sudah ada'**
  String get tagExists;

  /// No description provided for @totalBelowReturned.
  ///
  /// In id, this message translates to:
  /// **'Total tidak boleh kurang dari yang sudah dikembalikan ({amount})'**
  String totalBelowReturned(String amount);

  /// No description provided for @titipanIncomplete.
  ///
  /// In id, this message translates to:
  /// **'Data titipan tidak lengkap'**
  String get titipanIncomplete;

  /// No description provided for @returnExceedsTotal.
  ///
  /// In id, this message translates to:
  /// **'Pengembalian tidak boleh melebihi sisa titipan ({amount})'**
  String returnExceedsTotal(String amount);

  /// No description provided for @returnIncomplete.
  ///
  /// In id, this message translates to:
  /// **'Data pengembalian tidak lengkap'**
  String get returnIncomplete;

  /// No description provided for @notifTitipanTitle.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo titipan'**
  String get notifTitipanTitle;

  /// No description provided for @notifTitipanBody.
  ///
  /// In id, this message translates to:
  /// **'Titipan dengan {name} sudah jatuh tempo hari ini.'**
  String notifTitipanBody(String name);

  /// No description provided for @notifChannelName.
  ///
  /// In id, this message translates to:
  /// **'Jatuh Tempo Titipan'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In id, this message translates to:
  /// **'Pengingat jatuh tempo titipan'**
  String get notifChannelDesc;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'id':
      return LId();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
