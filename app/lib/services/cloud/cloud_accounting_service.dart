import '../../errors/cloud_data_exception.dart';
import '../../models/ledger_entry.dart';
import '../../models/account.dart';
import '../../repositories/cloud/cloud_accounting_repository.dart';

/// Service layer for D2 opening-balances accounting entities.
/// Mirrors the [CloudProductService] pattern: input validation + delegation
/// to the repository.
class CloudAccountingService {
  final CloudAccountingRepository _repository;

  CloudAccountingService({CloudAccountingRepository? repository})
      : _repository = repository ?? CloudAccountingRepository();

  // ---- Accounts ----

  Future<List<Account>> getAccounts(String shopId) =>
      _repository.getAccounts(shopId);

  Future<Account> createAccount(
    String shopId, {
    required String name,
    required AccountType accountType,
  }) {
    if (name.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Account name is required',
      );
    }
    return _repository.createAccount(
      shopId,
      name: name,
      accountType: accountType,
    );
  }

  Future<bool> updateAccount(
    String shopId,
    String accountId, {
    String? name,
    AccountType? accountType,
    bool? deleted,
  }) {
    if (name != null && name.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Account name is required',
      );
    }
    return _repository.updateAccount(
      shopId,
      accountId,
      name: name,
      accountType: accountType,
      deleted: deleted,
    );
  }

  // ---- Opening Balance Entries ----

  Future<List<LedgerEntry>> getOpeningBalances(
    String shopId, {
    String? accountId,
  }) =>
      _repository.getOpeningBalances(shopId, accountId: accountId);

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
  }) {
    if (amount < 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Opening balance amount must be zero or positive',
      );
    }
    if (correctsEntryId == null && entryKind == EntryKind.correction) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Correction entries must reference the entry being corrected',
      );
    }
    return _repository.createOpeningBalance(
      shopId,
      accountId: accountId,
      amount: amount,
      effectiveDate: effectiveDate,
      entryKind: entryKind,
      correctsEntryId: correctsEntryId,
      correctionReason: correctionReason,
      notes: notes,
      idempotencyKey: idempotencyKey,
    );
  }
}
