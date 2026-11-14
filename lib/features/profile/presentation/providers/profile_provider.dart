import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-only, decorative profile. Purely cosmetic data the user can edit;
/// nothing here touches wallets or transactions.
class ProfileProvider extends ChangeNotifier {
  static const _key = 'user_profile';
  static const defaultName = 'User Bay';

  SharedPreferences? _preferences;

  String _name = defaultName;
  String _bio = '';
  String? _gender; // null = not set
  DateTime? _birthDate;
  String? _photoPath;

  String get name => _name;
  String get bio => _bio;
  String? get gender => _gender;
  DateTime? get birthDate => _birthDate;
  String? get photoPath => _photoPath;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final raw = _preferences!.getString(_key);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _name = (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : defaultName;
      _bio = map['bio'] as String? ?? '';
      _gender = map['gender'] as String?;
      final birth = map['birthDate'] as String?;
      _birthDate = birth == null ? null : DateTime.tryParse(birth);
      _photoPath = map['photoPath'] as String?;
    }
    notifyListeners();
  }

  Future<void> save({
    required String name,
    required String bio,
    required String? gender,
    required DateTime? birthDate,
    required String? photoPath,
  }) async {
    _preferences ??= await SharedPreferences.getInstance();
    // Name is the only required field; fall back to the default if blank.
    _name = name.trim().isEmpty ? defaultName : name.trim();
    _bio = bio.trim();
    _gender = gender;
    _birthDate = birthDate;
    _photoPath = photoPath;
    await _preferences!.setString(
      _key,
      jsonEncode({
        'name': _name,
        'bio': _bio,
        'gender': _gender,
        'birthDate': _birthDate?.toIso8601String(),
        'photoPath': _photoPath,
      }),
    );
    notifyListeners();
  }
}
