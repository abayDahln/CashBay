import '../models/category.dart';
import '../../../../core/database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db = AppDatabase();

  Future<List<Category>> getAllCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await _db.database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await _db.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await _db.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isCategoryInUse(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
