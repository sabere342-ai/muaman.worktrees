import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_expense.dart';
import '../../models/cloud/cloud_expense_category.dart';
import '../../repositories/cloud/cloud_expense_repository.dart';

class CloudExpenseService {
  final CloudExpenseRepository _repository;

  CloudExpenseService({CloudExpenseRepository? repository})
      : _repository = repository ?? CloudExpenseRepository();

  Future<List<CloudExpense>> getExpenses(String shopId) =>
      _repository.getExpenses(shopId);

  Future<CloudExpense> createExpense(
    String shopId, {
    required DateTime date,
    required String description,
    required double amount,
    String? categoryId,
  }) {
    if (description.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Description is required',
      );
    }
    if (amount < 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Cannot be negative',
      );
    }
    return _repository.createExpense(
      shopId,
      date: date,
      description: description,
      amount: amount,
      categoryId: categoryId,
    );
  }

  Future<bool> updateExpense(
    String shopId,
    String expenseId, {
    DateTime? date,
    String? description,
    double? amount,
    String? categoryId,
  }) {
    if (description != null && description.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Description is required',
      );
    }
    return _repository.updateExpense(
      shopId,
      expenseId,
      date: date,
      description: description,
      amount: amount,
      categoryId: categoryId,
    );
  }

  Future<bool> deleteExpense(String shopId, String expenseId) =>
      _repository.deleteExpense(shopId, expenseId);

  Future<List<CloudExpenseCategory>> getCategories(String shopId) =>
      _repository.getCategories(shopId);

  Future<CloudExpenseCategory> createCategory(
    String shopId, {
    required String name,
  }) {
    if (name.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Category name is required',
      );
    }
    return _repository.createCategory(shopId, name: name);
  }

  Future<bool> deleteCategory(String shopId, String categoryId) =>
      _repository.deleteCategory(shopId, categoryId);
}
