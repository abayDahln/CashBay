import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cashbay/features/profile/presentation/providers/profile_provider.dart';

/// Profile is offline/decorative: name falls back to the default when blank,
/// other fields may be empty, and everything round-trips through prefs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to the default name with empty fields', () async {
    final p = ProfileProvider();
    await p.load();

    expect(p.name, 'User Bay');
    expect(p.bio, isEmpty);
    expect(p.gender, isNull);
    expect(p.birthDate, isNull);
    expect(p.photoPath, isNull);
  });

  test('blank name falls back to the default', () async {
    final p = ProfileProvider();
    await p.save(
      name: '   ',
      bio: 'hi',
      gender: 'male',
      birthDate: DateTime(1990, 5, 1),
      photoPath: null,
    );

    expect(p.name, 'User Bay');
    expect(p.bio, 'hi');
    expect(p.gender, 'male');
  });

  test('saved values round-trip through prefs', () async {
    final p = ProfileProvider();
    await p.save(
      name: 'Budi',
      bio: 'hello',
      gender: 'female',
      birthDate: DateTime(1995, 3, 2),
      photoPath: '/tmp/x.png',
    );

    final reloaded = ProfileProvider();
    await reloaded.load();
    expect(reloaded.name, 'Budi');
    expect(reloaded.bio, 'hello');
    expect(reloaded.gender, 'female');
    expect(reloaded.birthDate, DateTime(1995, 3, 2));
    expect(reloaded.photoPath, '/tmp/x.png');
  });
}
