import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_preferences_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  /// When true the screen renders as a tab body (no Scaffold / AppBar).
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _setMode(ThemeMode mode) =>
      context.read<ThemePreferencesProvider>().setThemeMode(mode);

  Future<void> _setSeed(Color color) =>
      context.read<ThemePreferencesProvider>().setSeedColor(color);

  Future<void> _showColorPicker() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        initialColor: context.read<ThemePreferencesProvider>().seedColor,
      ),
    );
    if (color != null) await _setSeed(color);
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text(
          'Semua data transaksi, dompet, kategori, dan tagihan akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = await AppDatabase().database;
      await db.delete('debt_payments');
      await db.delete('debts');
      await db.delete('transactions');
      await db.delete('categories');
      await db.delete('wallets');

      await db.insert('wallets', {
        'name': 'Cash',
        'type': 'cash',
        'balance': 0.0,
      });
      await db.insert('wallets', {
        'name': 'E-Wallet',
        'type': 'ewallet',
        'balance': 0.0,
      });

      final incomeCategories = [
        'Gaji',
        'Freelance/Proyek',
        'Bonus',
        'Investasi',
        'Hadiah',
      ];
      for (final name in incomeCategories) {
        await db.insert('categories', {
          'name': name,
          'type': 'income',
          'is_default': 1,
        });
      }
      final expenseCategories = [
        'Makanan & Minuman',
        'Transportasi',
        'Belanja',
        'Hiburan',
        'Kesehatan',
        'Pendidikan',
        'Tagihan',
      ];
      for (final name in expenseCategories) {
        await db.insert('categories', {
          'name': name,
          'type': 'expense',
          'is_default': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final db = await AppDatabase().database;
      final wallets = await db.query('wallets');
      final categories = await db.query('categories');
      final transactions = await db.query('transactions');
      final debts = await db.query('debts');
      final debtPayments = await db.query('debt_payments');

      final exportData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'wallets': wallets,
        'categories': categories,
        'transactions': transactions,
        'debts': debts,
        'debt_payments': debtPayments,
      };

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cashbay_backup.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data berhasil diexport ke ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cashbay_backup.json');
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File backup tidak ditemukan')),
          );
        }
        return;
      }

      final jsonStr = await file.readAsString();
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      final db = await AppDatabase().database;

      await db.delete('debt_payments');
      await db.delete('debts');
      await db.delete('transactions');
      await db.delete('categories');
      await db.delete('wallets');

      for (final w in data['wallets'] as List) {
        await db.insert('wallets', w as Map<String, dynamic>);
      }
      for (final c in data['categories'] as List) {
        await db.insert('categories', c as Map<String, dynamic>);
      }
      for (final t in data['transactions'] as List) {
        await db.insert('transactions', t as Map<String, dynamic>);
      }
      for (final d in data['debts'] as List) {
        await db.insert('debts', d as Map<String, dynamic>);
      }
      for (final p in data['debt_payments'] as List) {
        await db.insert('debt_payments', p as Map<String, dynamic>);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data berhasil diimport')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal import: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text(
          'Pengaturan',
          style: AppTypography.largeTitle.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 24),
        const _SectionHeader('TAMPILAN & TEMA'),
        _iosGroup(
          scheme,
          children: [
            _settingRow(
              scheme,
              icon: Icons.palette_outlined,
              iconColor: scheme.primary,
              title: 'Mode Tema',
              subtitle: _modeLabel(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Terang'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Gelap'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('Sistem'),
                  ),
                ],
                selected: {
                  context.watch<ThemePreferencesProvider>().themeMode,
                },
                onSelectionChanged: (value) => _setMode(value.first),
                showSelectedIcon: false,
              ),
            ),
            _divider(scheme),
            _settingRow(
              scheme,
              icon: Icons.color_lens_outlined,
              iconColor: scheme.primary,
              title: 'Warna Aksen',
              subtitle: 'Biru, hijau, merah, atau warna khusus',
              trailing: Wrap(
                spacing: 8,
                children: [
                  _ColorSwatch(
                    color: const Color(0xFF2196F3),
                    onTap: () => _setSeed(const Color(0xFF2196F3)),
                  ),
                  _ColorSwatch(
                    color: const Color(0xFF2E7D32),
                    onTap: () => _setSeed(const Color(0xFF2E7D32)),
                  ),
                  _ColorSwatch(
                    color: const Color(0xFFD32F2F),
                    onTap: () => _setSeed(const Color(0xFFD32F2F)),
                  ),
                  IconButton(
                    tooltip: 'Pilih warna khusus',
                    onPressed: _showColorPicker,
                    icon: const Icon(Icons.palette_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionHeader('MANAJEMEN DATA'),
        _iosGroup(
          scheme,
          children: [
            _settingRow(
              scheme,
              icon: Icons.upload_outlined,
              iconColor: scheme.primary,
              title: 'Export Data',
              subtitle: 'Simpan backup ke file JSON',
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _chevron(scheme),
              onTap: _isExporting ? null : _exportData,
            ),
            _divider(scheme),
            _settingRow(
              scheme,
              icon: Icons.download_outlined,
              iconColor: scheme.primary,
              title: 'Import Data',
              subtitle: 'Restore dari file backup',
              trailing: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _chevron(scheme),
              onTap: _isImporting ? null : _importData,
            ),
            _divider(scheme),
            _settingRow(
              scheme,
              icon: Icons.delete_forever_outlined,
              iconColor: scheme.error,
              title: 'Hapus Semua Data',
              titleColor: scheme.error,
              subtitle: 'Reset aplikasi ke kondisi awal',
              trailing: Icon(Icons.warning_amber_rounded, color: scheme.error),
              onTap: _deleteAllData,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionHeader('TENTANG'),
        _iosGroup(
          scheme,
          children: [
            _settingRow(
              scheme,
              icon: Icons.info_outline,
              iconColor: scheme.primary,
              title: 'CashBay',
              subtitle: 'v1.0.0 — Personal Finance App',
            ),
          ],
        ),
      ],
    );

    if (widget.embedded) {
      return SafeArea(bottom: false, child: body);
    }
    return Scaffold(
      appBar: const CashBayAppBar(title: 'Pengaturan'),
      body: body,
    );
  }

  String _modeLabel(BuildContext context) {
    final mode = context.watch<ThemePreferencesProvider>().themeMode;
    return switch (mode) {
      ThemeMode.light => 'Terang',
      ThemeMode.dark => 'Gelap',
      ThemeMode.system => 'System (Otomatis)',
    };
  }
}

Widget _iosGroup(ColorScheme scheme, {required List<Widget> children}) {
  return Container(
    decoration: BoxDecoration(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

Widget _divider(ColorScheme scheme) => Divider(
  height: 0.5,
  thickness: 0.5,
  indent: 56,
  color: scheme.outlineVariant.withValues(alpha: 0.35),
);

Widget _chevron(ColorScheme scheme) =>
    Icon(Icons.chevron_right, size: 20, color: scheme.outline);

Widget _settingRow(
  ColorScheme scheme, {
  required IconData icon,
  required Color iconColor,
  required String title,
  String? subtitle,
  Color? titleColor,
  Widget? trailing,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? scheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.caption1.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _ColorSwatch({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected =
        context.watch<ThemePreferencesProvider>().seedColor.toARGB32() ==
        color.toARGB32();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color color = widget.initialColor;

  HSVColor get hsv => HSVColor.fromColor(color);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Warna Aksen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPickerPreview(color),
          const SizedBox(height: 12),
          Slider(
            value: hsv.hue,
            onChanged: (hue) => setState(
              () => color = HSVColor.fromAHSV(
                1,
                hue,
                hsv.saturation,
                hsv.value,
              ).toColor(),
            ),
          ),
          Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class ColorPickerPreview extends StatelessWidget {
  final Color color;
  const ColorPickerPreview(this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    height: 80,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.caption1.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
