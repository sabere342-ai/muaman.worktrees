import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/ledger_entry.dart';
import '../../models/account.dart';

/// Cloud repository for D2 opening-balances accounting entities.
/// Mirrors the [CloudCustomerRepository] / [CloudProductRepository] RPC pattern.
class CloudAccountingRepository {
  final SupabaseClient _client;

  CloudAccountingRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ---- Accounts ----

  Future<List<Account>> getAccounts(String shopId) async {
    try {
      final data = await _client
          .rpc('list_cloud_accounts', params: {'p_shop_id': shopId});
      return (data as List)
          .map((e) => Account(
                shopId: e['shop_id'] as String? ?? shopId,
                name: e['name'] as String? ?? '',
                accountType: AccountType.fromValue(
                    e['account_type'] as String? ?? 'CASH'),
                cloudUuid: e['id'] as String?,
                serverVersion: (e['server_version'] as num?)?.toInt(),
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<Account> createAccount(
    String shopId, {
    required String name,
    required AccountType accountType,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_account', params: {
        'p_shop_id': shopId,
        'p_name': name,
        'p_account_type': accountType.value,
      });
      final uuid = data as String;
      return Account(
        shopId: shopId,
        name: name,
        accountType: accountType,
        cloudUuid: uuid,
      );
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> updateAccount(
    String shopId,
    String accountId, {
    String? name,
    AccountType? accountType,
    bool? deleted,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_shop_id': shopId,
        'p_account_id': accountId,
        if (name != null) 'p_name': name,
        if (accountType != null) 'p_account_type': accountType.value,
        if (deleted != null) 'p_deleted': deleted,
      };
      final data = await _client.rpc('update_cloud_account', params: params);
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  // ---- Opening Balance Entries ----

  Future<List<LedgerEntry>> getOpeningBalances(
    String shopId, {
    String? accountId,
  }) async {
    try {
      final data = await _client.rpc('list_cloud_opening_balances', params: {
        'p_shop_id': shopId,
        if (accountId != null) 'p_account_id': accountId,
      });
      return (data as List).map((e) {
        return LedgerEntry(
          shopId: e['shop_id'] as String? ?? shopId,
          accountId: 0,
          amount: (e['amount'] as num?)?.toDouble() ?? 0,
          effectiveDate: e['effective_date'] as String? ?? '',
          entryKind: EntryKind.fromValue(e['entry_kind'] as String? ?? 'OPENING'),
          correctsEntryId: (e['corrects_entry_id'] as num?)?.toInt(),
          correctionReason: e['correction_reason'] as String?,
          notes: e['notes'] as String?,
          idempotencyKey: e['idempotency_key'] as String?,
          createdBy: e['created_by'] as String?,
          createdAt: e['created_at'] as String? ?? '',
          cloudUuid: e['id'] as String?,
          serverVersion: (e['server_version'] as num?)?.toInt(),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<LedgerEntry> createOpeningBalance(
    String shopId, {
    required String accountId,
    required double amount,
    required String effectiveDate,
    required EntryKind entryKind,
    String? correctsEntryId,
    String? correctionReason,
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_shop_id': shopId,
        'p_account_id': accountId,
        'p_amount': amount,
        'p_effective_date': effectiveDate,
        'p_entry_kind': entryKind.value,
        if (correctsEntryId != null) 'p_corrects_entry_id': correctsEntryId,
        if (correctionReason != null) 'p_correction_reason': correctionReason,
        if (notes != null) 'p_notes': notes,
        if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
      };
      final data =
          await _client.rpc('create_cloud_opening_balance', params: params);
      final uuid = data as String;
      return LedgerEntry(
        shopId: shopId,
        accountId: 0,
        amount: amount,
        effectiveDate: effectiveDate,
        entryKind: entryKind,
        correctsEntryId: correctsEntryId != null ? int.tryParse(correctsEntryId) : null,
        correctionReason: correctionReason,
        notes: notes,
        idempotencyKey: idempotencyKey,
        cloudUuid: uuid,
      );
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
