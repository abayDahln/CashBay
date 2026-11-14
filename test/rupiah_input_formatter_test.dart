import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashbay/core/utils/formatters.dart';

TextEditingValue _edit(String text, int caret) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret));

void main() {
  final f = RupiahInputFormatter();

  test('typing at the end appends and keeps caret at end', () {
    final r = f.formatEditUpdate(_edit('1.500', 5), _edit('1.5000', 6));
    expect(r.text, '15.000');
    expect(r.selection.baseOffset, 6);
  });

  test('typing in the middle keeps the caret in place', () {
    // "1.000" -> insert "0" after the first digit -> "10.000", caret after it.
    final r = f.formatEditUpdate(_edit('1.000', 1), _edit('10.000', 2));
    expect(r.text, '10.000');
    expect(r.selection.baseOffset, 2);
  });

  test('editing in the middle does not jump to the end', () {
    // "12.345" caret after "12." (3), typing "9" -> "129.345", caret after 9.
    final r = f.formatEditUpdate(_edit('12.345', 3), _edit('129.345', 4));
    expect(r.text, '129.345');
    expect(r.selection.baseOffset, 3);
  });

  test('strips leading zeros', () {
    final r = f.formatEditUpdate(_edit('', 0), _edit('007', 3));
    expect(r.text, '7');
  });

  test('rejects input past the digit limit', () {
    const max = '999.999.999.999.999'; // 15 digits
    final r = f.formatEditUpdate(_edit(max, max.length), _edit('${max}0', max.length + 1));
    expect(r.text, max);
  });

  group('formatValue', () {
    test('clamps to maxAmount instead of throwing', () {
      expect(RupiahInputFormatter.formatValue(double.maxFinite), '999.999.999.999.999');
      expect(
        RupiahInputFormatter.formatValue(InputValidation.maxAmount + 1000),
        '999.999.999.999.999',
      );
      // Non-finite values have no meaningful amount: empty, never a crash.
      expect(RupiahInputFormatter.formatValue(double.infinity), '');
      expect(RupiahInputFormatter.formatValue(double.negativeInfinity), '');
      expect(RupiahInputFormatter.formatValue(double.nan), '');
    });

    test('keeps values at or below the limit untouched', () {
      expect(RupiahInputFormatter.formatValue(1500), '1.500');
      expect(
        RupiahInputFormatter.formatValue(InputValidation.maxAmount),
        '999.999.999.999.999',
      );
      expect(RupiahInputFormatter.formatValue(0), '');
      expect(RupiahInputFormatter.formatValue(-5), '');
    });
  });
}
