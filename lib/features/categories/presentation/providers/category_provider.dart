import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  bool _isLoading = false;

  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get expenseCategories => _expenseCategories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;

    _incomeCategories = await _repository.getCategoriesByType('income');
    _expenseCategories = await _repository.getCategoriesByType('expense');

    _isLoading = false;
    notifyListeners();
  }

  Future<int?> addCategory({
    required String name,
    required String type,
    String? icon,
  }) async {
    final category = Category(name: name, type: type, icon: icon);
    final id = await _repository.insertCategory(category);
    if (id > 0) {
      final newCategory = category.copyWith(id: id);
      if (type == 'income') {
        _incomeCategories.add(newCategory);
      } else {
        _expenseCategories.add(newCategory);
      }
      notifyListeners();
      return id;
    }
    return null;
  }

  Future<bool> updateCategory(Category category) async {
    final result = await _repository.updateCategory(category);
    if (result > 0) {
      if (category.type == 'income') {
        final index = _incomeCategories.indexWhere((c) => c.id == category.id);
        if (index != -1) _incomeCategories[index] = category;
      } else {
        final index = _expenseCategories.indexWhere((c) => c.id == category.id);
        if (index != -1) _expenseCategories[index] = category;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    final result = await _repository.deleteCategory(id);
    if (result > 0) {
      _incomeCategories.removeWhere((c) => c.id == id);
      _expenseCategories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> isCategoryInUse(int id) async {
    return await _repository.isCategoryInUse(id);
  }

  /// Duplicate-name message for a new category, or null when it is unique.
  String? hasCategoryNamed(String name, String type) {
    final lower = name.trim().toLowerCase();
    final sameType = type == 'income' ? _incomeCategories : _expenseCategories;
    final duplicate = sameType.any(
      (c) => c.name.trim().toLowerCase() == lower,
    );
    return duplicate ? 'Tag dengan nama ini sudah ada' : null;
  }
}
