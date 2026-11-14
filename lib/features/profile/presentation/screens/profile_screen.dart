import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/profile_provider.dart';

/// Profile tab: purely decorative data stored offline. The gear opens the full
/// settings screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) => ListView(
          padding: EdgeInsets.zero,
          children: [
            _Banner(profile: profile, onSettings: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: t.profileBio,
                    value: profile.bio.isEmpty ? t.profileNotSet : profile.bio,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.wc_outlined,
                    label: t.profileGender,
                    value: _genderLabel(t, profile.gender),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: t.profileBirthDate,
                    value: profile.birthDate == null
                        ? t.profileNotSet
                        : DateFormatter.formatDate(profile.birthDate!),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showEditSheet(context, profile),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(t.editProfile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: scheme.surface,
    );
  }

  static String _genderLabel(L t, String? gender) => switch (gender) {
    'male' => t.profileGenderMale,
    'female' => t.profileGenderFemale,
    'other' => t.profileGenderOther,
    _ => t.profileNotSet,
  };

  void _showEditSheet(BuildContext context, ProfileProvider profile) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }
}

/// Gradient banner holding the settings button, avatar, and name.
class _Banner extends StatelessWidget {
  final ProfileProvider profile;
  final VoidCallback onSettings;
  const _Banner({required this.profile, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: t.settings,
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
                color: scheme.onPrimaryContainer,
              ),
            ),
            _Avatar(profile: profile, radius: 48),
            const SizedBox(height: 12),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ProfileProvider profile;
  final double radius;
  const _Avatar({required this.profile, required this.radius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = profile.photoPath;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.surface,
      foregroundImage: photo == null ? null : FileImage(File(photo)),
      child: Text(
        profile.name.isEmpty ? '?' : profile.name.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: text.bodyLarge?.copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final ProfileProvider profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  String? _gender;
  DateTime? _birthDate;
  String? _photoPath;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _bio = TextEditingController(text: p.bio);
    _gender = p.gender;
    _birthDate = p.birthDate;
    _photoPath = p.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _photoPath = picked.path);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _submitted = true);
      return;
    }
    widget.profile.save(
      name: name,
      bio: _bio.text,
      gender: _gender,
      birthDate: _birthDate,
      photoPath: _photoPath,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final showNameError = _submitted && _name.text.trim().isEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.editProfile, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    foregroundImage: _photoPath == null
                        ? null
                        : FileImage(File(_photoPath!)),
                    child: const Icon(Icons.person_outline, size: 32),
                  ),
                  TextButton(
                    onPressed: _pickPhoto,
                    child: Text(t.profileChangePhoto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: t.profileName,
                errorText: showNameError ? t.profileNameRequired : null,
              ),
              onChanged: (_) {
                if (showNameError) setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bio,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: t.profileBio),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: t.profileGender),
              items: [
                DropdownMenuItem(value: null, child: Text(t.profileNotSet)),
                DropdownMenuItem(
                  value: 'male',
                  child: Text(t.profileGenderMale),
                ),
                DropdownMenuItem(
                  value: 'female',
                  child: Text(t.profileGenderFemale),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(t.profileGenderOther),
                ),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t.profileBirthDate,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? t.profileNotSet
                      : DateFormatter.formatDate(_birthDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(t.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
