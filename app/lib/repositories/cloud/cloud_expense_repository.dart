import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_expense.dart';
import '../../models/cloud/cloud_expense_category.dart';

class CloudExpenseRepository {
  final SupabaseClient _client;

  CloudExpenseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CloudExpense>> getExpenses(String shopId) async {
    try {
      final data = await _client
          .from('cloud_expenses')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudExpense.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudExpense> createExpense(
    String shopId, {
    required DateTime date,
    required String description,
    required double amount,
    String? categoryId,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_expense', params: {
        'p_shop_id': shopId,
        'p_date': date.toIso8601String(),
        'p_description': description,
        'p_amount': amount,
        'p_category_id': categoryId,
      });
      final result = await _client
          .from('cloud_expenses')
          .select()
          .eq('id', data as String)
          .single();
      return CloudExpense.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> updateExpense(
    String shopId,
    String expenseId, {
    DateTime? date,
    String? description,
    double? amount,
    String? categoryId,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_shop_id': shopId,
        'p_expense_id': expenseId,
      };
      if (date != null) params['p_date'] = date.toIso8601String();
      if (description != null) params['p_description'] = description;
      if (amount != null) params['p_amount'] = amount;
      if (categoryId != null) params['p_category_id'] = categoryId;
      final data = await _client.rpc('update_cloud_expense', params: params);
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteExpense(String shopId, String expenseId) async {
    try {
      final data = await _client.rpc('delete_cloud_expense', params: {
        'p_shop_id': shopId,
        'p_expense_id': expenseId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<List<CloudExpenseCategory>> getCategories(String shopId) async {
    try {
      final data = await _client
          .from('cloud_expense_categories')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('name');
      return (data as List)
          .map((e) => CloudExpenseCategory.fromJson(e))
          .toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudExpenseCategory> createCategory(
    String shopId, {
    required String name,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_expense_category', params: {
        'p_shop_id': shopId,
        'p_name': name,
      });
      final result = await _client
          .from('cloud_expense_categories')
          .select()
          .eq('id', data as String)
          .single();
      return CloudExpenseCategory.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteCategory(String shopId, String categoryId) async {
    try {
      final data = await _client.rpc('delete_cloud_expense_category', params: {
        'p_shop_id': shopId,
        'p_category_id': categoryId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
