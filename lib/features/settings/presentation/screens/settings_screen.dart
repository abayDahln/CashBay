import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text('Semua data transaksi, dompet, kategori, dan tagihan akan dihapus. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.black),
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

      await db.insert('wallets', {'name': 'Cash', 'type': 'cash', 'balance': 0.0});
      await db.insert('wallets', {'name': 'E-Wallet', 'type': 'ewallet', 'balance': 0.0});

      final incomeCategories = ['Gaji', 'Freelance/Proyek', 'Bonus', 'Investasi', 'Hadiah'];
      for (final name in incomeCategories) {
        await db.insert('categories', {'name': name, 'type': 'income', 'is_default': 1});
      }
      final expenseCategories = ['Makanan & Minuman', 'Transportasi', 'Belanja', 'Hiburan', 'Kesehatan', 'Pendidikan', 'Tagihan'];
      for (final name in expenseCategories) {
        await db.insert('categories', {'name': name, 'type': 'expense', 'is_default': 1});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
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
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data berhasil diexport ke ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diimport')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CashBayAppBar(title: 'Pengaturan'),
      body: AppCard(
        radius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('Data'),
            AppCard(
              radius: const BorderRadius.all(Radius.circular(16)),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppTheme.black),
                    title: const Text('Hapus Semua Data'),
                    subtitle: const Text('Reset aplikasi ke awal'),
                    onTap: _deleteAllData,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text('Export Data'),
                    subtitle: const Text('Simpan backup ke file'),
                    trailing: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    onTap: _isExporting ? null : _exportData,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Import Data'),
                    subtitle: const Text('Restore dari file backup'),
                    trailing: _isImporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    onTap: _isImporting ? null : _importData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Tentang'),
            AppCard(
              radius: const BorderRadius.all(Radius.circular(16)),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('CashBay'),
                    subtitle: const Text('v1.0.0 — Personal Finance App'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
