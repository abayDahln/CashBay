import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_preferences_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';
import '../../../debts/presentation/providers/debt_provider.dart';
import '../../../report/presentation/providers/report_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

/// Fixed list of accent seed colours offered in the swatch row.
const _seedSwatches = <({Color color, String label})>[
  (color: Color(0xFF2196F3), label: 'Biru'),
  (color: Color(0xFF2E7D32), label: 'Hijau'),
  (color: Color(0xFFD32F2F), label: 'Merah'),
  (color: Color(0xFF6750A4), label: 'Ungu'),
  (color: Color(0xFFEF6C00), label: 'Oranye'),
  (color: Color(0xFF00897B), label: 'Teal'),
];

const _backupTables = [
  'wallets',
  'categories',
  'transactions',
  'debts',
  'debt_payments',
];

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
  bool _isDeleting = false;

  bool get _isBusy => _isExporting || _isImporting || _isDeleting;

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

  /// Providers don't observe the database, so reload everything after a
  /// bulk change (delete-all / import).
  Future<void> _reloadProviders() async {
    final wallets = context.read<WalletProvider>();
    final transactions = context.read<TransactionProvider>();
    final debts = context.read<DebtProvider>();
    final categories = context.read<CategoryProvider>();
    final report = context.read<ReportProvider>();
    await Future.wait([
      wallets.loadWallets(),
      transactions.loadTransactions(),
      debts.loadAllDebts(),
      debts.loadActiveDebts(),
      categories.loadCategories(),
      report.loadChartData(),
    ]);
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DeleteAllDialog(),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final db = await AppDatabase().database;
      await db.transaction((txn) async {
        await txn.delete('debt_payments');
        await txn.delete('debts');
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('wallets');

        await txn.insert('wallets', {
          'name': 'Cash',
          'type': 'cash',
          'balance': 0.0,
        });
        await txn.insert('wallets', {
          'name': 'E-Wallet',
          'type': 'ewallet',
          'balance': 0.0,
        });

        const incomeCategories = [
          'Gaji',
          'Freelance/Proyek',
          'Bonus',
          'Investasi',
          'Hadiah',
        ];
        for (final name in incomeCategories) {
          await txn.insert('categories', {
            'name': name,
            'type': 'income',
            'is_default': 1,
          });
        }
        const expenseCategories = [
          'Makanan & Minuman',
          'Transportasi',
          'Belanja',
          'Hiburan',
          'Kesehatan',
          'Pendidikan',
          'Tagihan',
        ];
        for (final name in expenseCategories) {
          await txn.insert('categories', {
            'name': name,
            'type': 'expense',
            'is_default': 1,
          });
        }
      });

      if (!mounted) return;
      await _reloadProviders();
      if (mounted) ToastWidget.success(context, 'Semua data berhasil dihapus');
    } catch (e) {
      if (mounted) ToastWidget.error(context, 'Gagal menghapus data: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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
        ToastWidget.success(context, 'Data berhasil diexport ke ${file.path}');
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, 'Gagal export: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cashbay_backup.json');
      if (!await file.exists()) {
        if (mounted) ToastWidget.error(context, 'File backup tidak ditemukan');
        return;
      }

      final jsonStr = await file.readAsString();
      final Map<String, dynamic> data;
      try {
        data = json.decode(jsonStr) as Map<String, dynamic>;
        for (final table in _backupTables) {
          if (data[table] is! List) throw const FormatException();
        }
      } catch (_) {
        if (mounted) {
          ToastWidget.error(context, 'Format file backup tidak valid');
        }
        return;
      }

      if (!mounted) return;
      final exportedAt = DateTime.tryParse('${data['exported_at']}');
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => _ImportConfirmDialog(exportedAt: exportedAt),
      );
      if (confirm != true || !mounted) return;

      setState(() => _isImporting = true);
      final db = await AppDatabase().database;
      await db.transaction((txn) async {
        await txn.delete('debt_payments');
        await txn.delete('debts');
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('wallets');

        for (final table in _backupTables) {
          for (final row in data[table] as List) {
            await txn.insert(table, row as Map<String, dynamic>);
          }
        }
      });

      if (!mounted) return;
      await _reloadProviders();
      if (mounted) ToastWidget.success(context, 'Data berhasil diimport');
    } catch (e) {
      if (mounted) ToastWidget.error(context, 'Gagal import: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _openCategories() {
    Navigator.of(context).push(fadeSlideRoute(const CategoriesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prefs = context.watch<ThemePreferencesProvider>();
    final seed = prefs.seedColor.toARGB32();
    final isCustomSeed = !_seedSwatches.any(
      (s) => s.color.toARGB32() == seed,
    );

    final body = ListView(
      padding: EdgeInsets.only(top: widget.embedded ? 8 : 0, bottom: 24),
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Pengaturan',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
        const _SectionHeader('Tampilan & Tema'),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Mode Tema'),
          subtitle: Text(_modeLabel(prefs.themeMode)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('Sistem'),
                ),
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
              ],
              selected: {prefs.themeMode},
              onSelectionChanged: (value) => _setMode(value.first),
              showSelectedIcon: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Warna Aksen'),
          subtitle: Text(
            isCustomSeed
                ? 'Warna khusus'
                : _seedSwatches
                      .firstWhere((s) => s.color.toARGB32() == seed)
                      .label,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final s in _seedSwatches)
                _ColorSwatch(
                  color: s.color,
                  label: s.label,
                  selected: s.color.toARGB32() == seed,
                  onTap: () => _setSeed(s.color),
                ),
              _ColorSwatch(
                color: isCustomSeed ? prefs.seedColor : null,
                label: 'Pilih warna khusus',
                selected: isCustomSeed,
                onTap: _showColorPicker,
              ),
            ],
          ),
        ),
        const Divider(),
        const _SectionHeader('Manajemen Data'),
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text('Kelola Kategori'),
          subtitle: const Text('Tambah, ubah, atau hapus kategori'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openCategories,
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Export Data'),
          subtitle: const Text('Simpan backup ke file JSON'),
          trailing: _isExporting
              ? const _BusyIndicator()
              : const Icon(Icons.chevron_right),
          enabled: !_isBusy,
          onTap: _exportData,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Import Data'),
          subtitle: const Text('Pulihkan dari file backup'),
          trailing: _isImporting
              ? const _BusyIndicator()
              : const Icon(Icons.chevron_right),
          enabled: !_isBusy,
          onTap: _importData,
        ),
        ListTile(
          iconColor: scheme.error,
          textColor: scheme.error,
          leading: const Icon(Icons.delete_forever_outlined),
          title: const Text('Hapus Semua Data'),
          subtitle: Text(
            'Reset aplikasi ke kondisi awal',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          trailing: _isDeleting ? const _BusyIndicator() : null,
          enabled: !_isBusy,
          onTap: _deleteAllData,
        ),
        if (_isBusy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(),
          ),
        const Divider(),
        const _SectionHeader('Tentang'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('CashBay'),
          subtitle: Text('v1.0.0 — Personal Finance App'),
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

  String _modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
    ThemeMode.system => 'Ikuti sistem',
  };
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(strokeWidth: 3),
  );
}

/// Circular seed swatch with a 48dp touch target. A null [color] renders the
/// "custom colour" entry (palette icon on a neutral container).
class _ColorSwatch extends StatelessWidget {
  final Color? color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? scheme.surfaceContainerHighest;
    final onFill = color == null
        ? scheme.onSurfaceVariant
        : (ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
              ? Colors.white
              : Colors.black);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: Durations.short4,
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                  child: selected
                      ? Icon(Icons.check, size: 18, color: onFill)
                      : color == null
                      ? Icon(Icons.colorize, size: 18, color: onFill)
                      : null,
                ),
              ),
            ),
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
  late HSVColor _hsv;

  Color get _color => _hsv.toColor();

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hsv = hsv.value < 0.2 ? hsv.withValue(0.2) : hsv;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Pilih Warna Aksen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorPickerPreview(_color),
            const SizedBox(height: 8),
            Text(
              '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Rona', style: textTheme.labelLarge),
            Slider(
              value: _hsv.hue,
              max: 360,
              label: _hsv.hue.round().toString(),
              onChanged: (hue) => setState(() => _hsv = _hsv.withHue(hue)),
            ),
            Text('Saturasi', style: textTheme.labelLarge),
            Slider(
              value: _hsv.saturation,
              onChanged: (s) => setState(() => _hsv = _hsv.withSaturation(s)),
            ),
            Text('Kecerahan', style: textTheme.labelLarge),
            Slider(
              value: _hsv.value,
              min: 0.2,
              onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color.withValues(alpha: 1)),
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
    height: 80,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

/// Destructive confirmation: the delete button only enables once the user
/// types "HAPUS".
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  static const _keyword = 'HAPUS';
  final _controller = TextEditingController();

  bool get _confirmed => _controller.text.trim().toUpperCase() == _keyword;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: const Text('Hapus Semua Data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Semua data transaksi, dompet, kategori, dan tagihan akan dihapus. '
              'Tindakan ini tidak dapat dibatalkan.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Ketik HAPUS untuk konfirmasi',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_confirmed) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _confirmed ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: const Text('Hapus Semua'),
        ),
      ],
    );
  }
}

class _ImportConfirmDialog extends StatelessWidget {
  final DateTime? exportedAt;
  const _ImportConfirmDialog({this.exportedAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = exportedAt == null
        ? ''
        : ' (backup ${MaterialLocalizations.of(context).formatMediumDate(exportedAt!)})';
    return AlertDialog(
      icon: const Icon(Icons.restore),
      title: const Text('Import Data?'),
      content: Text(
        'Data saat ini akan diganti dengan isi file backup$when. '
        'Tindakan ini tidak dapat dibatalkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: const Text('Ganti Data'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
