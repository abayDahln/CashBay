import 'dart:io';
import 'package:intl/intl.dart';

class InputValidation {
  static const int maxName = 100;
  static const int maxDescription = 200;
  static const int maxNote = 500;
  static const int maxCategory = 50;
  static const int maxBillName = 100;
  static const int maxPersonName = 100;
  static const int maxFileSize = 10 * 1024 * 1024;
  static const List<String> allowedImageExt = ['jpg', 'jpeg', 'png'];

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label tidak boleh kosong';
    return null;
  }

  static String? imageFile(String? path) {
    if (path == null || path.isEmpty) return null;
    final ext = path.split('.').last.toLowerCase();
    if (!allowedImageExt.contains(ext)) return 'Format foto harus JPG atau PNG';
    final file = File(path);
    if (!file.existsSync()) return 'File foto tidak ditemukan';
    if (file.lengthSync() > maxFileSize) return 'Ukuran foto maksimal 10 MB';
    return null;
  }

  static String? amount(String? v) {
    if (v == null || v.isEmpty) return 'Jumlah tidak boleh kosong';
    final amount = double.tryParse(v.replaceAll('.', ''));
    if (amount == null || amount <= 0) return 'Masukkan nominal yang valid';
    if (amount > 999999999999999999) return 'Nominal terlalu besar';
    return null;
  }
}

class CurrencyFormatter {
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormat = NumberFormat.decimalPattern('id_ID');

  static String format(double amount) {
    return _rupiahFormat.format(amount);
  }

  static String formatWithSign(double amount, {bool showPlus = true}) {
    final sign = amount >= 0 ? (showPlus ? '+' : '') : '-';
    return '$sign${format(amount.abs())}';
  }

  static String _formatWithSep(double value) {
    _decimalFormat.maximumFractionDigits = value == value.roundToDouble() ? 0 : 2;
    return _decimalFormat.format(value);
  }

  static String _maybeSign(double amount, String formatted) {
    if (amount < 0) return '-$formatted';
    return formatted;
  }

  static String formatShort(double amount) {
    final a = amount.abs();
    if (a >= 100000000) {
      return _maybeSign(amount, '${_formatWithSep(a / 1000000000)}m');
    }
    if (a >= 1000000) {
      return _maybeSign(amount, '${_formatWithSep(a / 1000000)}jt');
    }
    if (a >= 1000) {
      return _maybeSign(amount, '${_formatWithSep(a / 1000)}rb');
    }
    return _maybeSign(amount, _formatWithSep(a));
  }

  static String formatMedium(double amount) {
    final a = amount.abs();
    if (a >= 1000000000000000) {
      return _maybeSign(amount, 'Rp ${_formatWithSep(a / 1000000000000000)} Kuadriliun');
    }
    if (a >= 1000000000000) {
      return _maybeSign(amount, 'Rp ${_formatWithSep(a / 1000000000000)} T');
    }
    if (a >= 1000000000) {
      return _maybeSign(amount, 'Rp ${_formatWithSep(a / 1000000000)} M');
    }
    if (a >= 1000000) {
      return _maybeSign(amount, 'Rp ${_formatWithSep(a / 1000000)} Jt');
    }
    return format(amount);
  }
}

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }
}