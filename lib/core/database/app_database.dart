import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cashbay.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        wallet_id INTEGER NOT NULL,
        to_wallet_id INTEGER,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        description TEXT,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        attachment_path TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (to_wallet_id) REFERENCES wallets (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_tags (
        transaction_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (transaction_id, category_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        wallet_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        note TEXT,
        date TEXT NOT NULL,
        bill_name TEXT,
        due_date TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        attachment_path TEXT,
        open_txn_id INTEGER,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        wallet_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        txn_id INTEGER,
        FOREIGN KEY (debt_id) REFERENCES debts (id),
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'transactions', 'is_deleted', 'INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 4) {
      await _migrateToTransactionTags(db);
    }

    if (oldVersion < 5) {
      await _addColumnIfNotExists(db, 'debts', 'open_txn_id', 'INTEGER');
      await _addColumnIfNotExists(db, 'debt_payments', 'txn_id', 'INTEGER');
    }

    if (oldVersion < 2) {
      await _addColumnIfNotExists(db, 'categories', 'is_default', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfNotExists(db, 'transactions', 'description', 'TEXT');
      await _addColumnIfNotExists(db, 'transactions', 'payment_method', "TEXT NOT NULL DEFAULT 'cash'");
      await _addColumnIfNotExists(db, 'transactions', 'is_recurring', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfNotExists(db, 'transactions', 'attachment_path', 'TEXT');
      await _addColumnIfNotExists(db, 'debts', 'bill_name', 'TEXT');
      await _addColumnIfNotExists(db, 'debts', 'due_date', 'TEXT');
      await _addColumnIfNotExists(db, 'debts', 'reminder_enabled', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfNotExists(db, 'debts', 'payment_method', "TEXT NOT NULL DEFAULT 'cash'");
      await _addColumnIfNotExists(db, 'debts', 'attachment_path', 'TEXT');
    }
  }

  Future<void> _addColumnIfNotExists(Database db, String table, String column, String definition) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    } catch (_) {}
  }

  /// v4: categories become optional multi-tags. Moves each transaction's
  /// single `category_id` into the `transaction_tags` pivot, then rebuilds
  /// `transactions` without the column.
  Future<void> _migrateToTransactionTags(Database db) async {
    await db.execute('ALTER TABLE transactions RENAME TO transactions_old');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        wallet_id INTEGER NOT NULL,
        to_wallet_id INTEGER,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        description TEXT,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        attachment_path TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (to_wallet_id) REFERENCES wallets (id)
      )
    ''');
    await db.execute('''
      INSERT INTO transactions
        (id, type, amount, wallet_id, to_wallet_id, note, date, created_at,
         description, payment_method, attachment_path, is_deleted)
      SELECT id, type, amount, wallet_id, to_wallet_id, note, date, created_at,
         description, payment_method, attachment_path, is_deleted
      FROM transactions_old
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_tags (
        transaction_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (transaction_id, category_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO transaction_tags (transaction_id, category_id)
      SELECT id, category_id FROM transactions_old WHERE category_id IS NOT NULL
    ''');
    await db.execute('DROP TABLE transactions_old');
  }

  Future<void> _seedInitialData(Database db) async {
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
      {'name': 'Gaji', 'type': 'income', 'is_default': 1},
      {'name': 'Freelance/Proyek', 'type': 'income', 'is_default': 1},
      {'name': 'Bonus', 'type': 'income', 'is_default': 1},
      {'name': 'Investasi', 'type': 'income', 'is_default': 1},
      {'name': 'Hadiah', 'type': 'income', 'is_default': 1},
    ];

    final expenseCategories = [
      {'name': 'Makanan & Minuman', 'type': 'expense', 'is_default': 1},
      {'name': 'Transportasi', 'type': 'expense', 'is_default': 1},
      {'name': 'Belanja', 'type': 'expense', 'is_default': 1},
      {'name': 'Hiburan', 'type': 'expense', 'is_default': 1},
      {'name': 'Kesehatan', 'type': 'expense', 'is_default': 1},
      {'name': 'Pendidikan', 'type': 'expense', 'is_default': 1},
      {'name': 'Tagihan', 'type': 'expense', 'is_default': 1},
    ];

    for (var cat in incomeCategories) {
      await db.insert('categories', cat);
    }

    for (var cat in expenseCategories) {
      await db.insert('categories', cat);
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
