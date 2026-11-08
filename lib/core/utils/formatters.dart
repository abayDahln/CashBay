import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats digits as Rupiah thousands ("1500000" → "1.500.000") while typing.
/// Non-digits are stripped; the caret is kept relative to the typed digits.
class RupiahInputFormatter extends TextInputFormatter {
  static final NumberFormat _format = NumberFormat.decimalPattern('id_ID');

  /// Hard cap on digits so values stay well inside double precision.
  static const int maxDigits = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = digits.isEmpty ? '' : _format.format(int.parse(digits));
    // Keep the caret where the user was typing: place it after the same
    // number of digits that sat before the caret in the raw input.
    final digitsBeforeCaret = newValue.text
        .substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final offset = _offsetAfterDigits(text, digitsBeforeCaret);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  /// Index in [text] just after its first [count] digits (end when fewer).
  static int _offsetAfterDigits(String text, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text.codeUnitAt(i))) {
        seen++;
        if (seen == count) return i + 1;
      }
    }
    return text.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

  static String formatValue(double value) =>
      value <= 0 ? '' : _format.format(value.toInt());
}

class InputValidation {
  static const int maxName = 100;
  static const int maxDescription = 200;
  static const int maxNote = 500;
  static const int maxCategory = 50;
  static const int maxBillName = 100;
  static const int maxPersonName = 100;
  static const int maxFileSize = 10 * 1024 * 1024;
  static const double maxAmount = 999999999999999;
  static const List<String> allowedImageExt = ['jpg', 'jpeg', 'png'];

  /// Parses a Rupiah input ("1.500.000", "Rp 1.500") into a number, or null.
  static double? parseAmount(String? v) {
    if (v == null) return null;
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label tidak boleh kosong';
    return null;
  }

  /// Required + trimmed length check + must contain a letter or digit.
  static String? name(String? v, String label, {int max = maxName}) {
    final req = required(v, label);
    if (req != null) return req;
    final t = v!.trim();
    if (t.length < 2) return '$label minimal 2 karakter';
    if (t.length > max) return '$label maksimal $max karakter';
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(t)) {
      return '$label harus mengandung huruf atau angka';
    }
    return null;
  }

  /// Optional text with a max length.
  static String? maxLength(String? v, String label, int max) {
    if (v != null && v.trim().length > max) {
      return '$label maksimal $max karakter';
    }
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

  static String? amount(String? v) => amountInRange(v);

  /// Amount validator with optional bounds, e.g. remaining debt or the
  /// source wallet balance (`max`) and a minimum (`min`, default > 0).
  static String? amountInRange(
    String? v, {
    double? min,
    double? max,
    String? maxMessage,
  }) {
    final amount = parseAmount(v);
    if (amount == null) return 'Nominal tidak boleh kosong';
    if (amount <= 0) return 'Nominal harus lebih dari 0';
    if (min != null && amount < min) {
      return 'Nominal minimal ${CurrencyFormatter.format(min)}';
    }
    if (amount > maxAmount) return 'Nominal terlalu besar';
    if (max != null && amount > max) {
      return maxMessage ?? 'Nominal maksimal ${CurrencyFormatter.format(max)}';
    }
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