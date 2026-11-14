import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cashbay/core/theme/theme_preferences_provider.dart';
import 'package:cashbay/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  tearDown(() => ThemePreferencesProvider.localeCode = 'id');

  group('formatShort units follow the UI language', () {
    test('Indonesian uses rb / jt / m', () {
      ThemePreferencesProvider.localeCode = 'id';
      expect(CurrencyFormatter.formatShort(1500), '1,5rb');
      expect(CurrencyFormatter.formatShort(1500000), '1,5jt');
      expect(CurrencyFormatter.formatShort(2500000000), '2,5m');
      expect(CurrencyFormatter.formatShort(-2000), '-2rb');
    });

    test('English uses k / m / b', () {
      ThemePreferencesProvider.localeCode = 'en';
      expect(CurrencyFormatter.formatShort(1500), '1,5k');
      expect(CurrencyFormatter.formatShort(1500000), '1,5m');
      expect(CurrencyFormatter.formatShort(2500000000), '2,5b');
      expect(CurrencyFormatter.formatShort(-1500), '-1,5k');
    });

    test('below 1000 keeps the plain number in both languages', () {
      for (final code in ['id', 'en']) {
        ThemePreferencesProvider.localeCode = code;
        expect(CurrencyFormatter.formatShort(999), '999');
        expect(CurrencyFormatter.formatShort(0), '0');
      }
    });
  });

  group('formatMedium units follow the UI language', () {
    test('Indonesian uses Jt / M / T', () {
      ThemePreferencesProvider.localeCode = 'id';
      expect(CurrencyFormatter.formatMedium(1500000), 'Rp 1,5 Jt');
      expect(CurrencyFormatter.formatMedium(2500000000), 'Rp 2,5 M');
      expect(CurrencyFormatter.formatMedium(3000000000000), 'Rp 3 T');
      expect(CurrencyFormatter.formatMedium(1500), 'Rp 1.500');
    });

    test('English uses K / M / B / T', () {
      ThemePreferencesProvider.localeCode = 'en';
      expect(CurrencyFormatter.formatMedium(1500), 'Rp 1,5K');
      expect(CurrencyFormatter.formatMedium(1500000), 'Rp 1,5M');
      expect(CurrencyFormatter.formatMedium(2500000000), 'Rp 2,5B');
      expect(CurrencyFormatter.formatMedium(3000000000000), 'Rp 3T');
    });

    test('sign is preserved', () {
      ThemePreferencesProvider.localeCode = 'en';
      expect(CurrencyFormatter.formatMedium(-1500000), '-Rp 1,5M');
    });
  });
}
