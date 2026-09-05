/// Phase P Group D D2 (P-OD5): opening-balance accounting entry (D2-01 A,
/// D2-03 A, D2-04 C, D2-05 A).
///
/// Append-only record (D2-05 A): corrections are NOT in-place mutations of a
/// posted entry; they are represented through new corrective adjustment entries
/// that reference the original via [correctsEntryId] + [correctionReason].
///
/// Amount is strictly zero or positive (D2-03 A); economic direction is expressed
/// through the account TYPE, never through negative numbers.
class LedgerEntry {
  final int? id;
  final String shopId;
  final int accountId;
  final double amount;
  final String effectiveDate;
  final EntryKind entryKind;
  final int? correctsEntryId;
  final String? correctionReason;
  final String? notes;
  final String? idempotencyKey;
  final String? createdBy;
  final String createdAt;
  final String? cloudUuid;
  final int? serverVersion;

  LedgerEntry({
    this.id,
    required this.shopId,
    required this.accountId,
    required this.amount,
    required this.effectiveDate,
    required this.entryKind,
    this.correctsEntryId,
    this.correctionReason,
    this.notes,
    this.idempotencyKey,
    this.createdBy,
    String? createdAt,
    this.cloudUuid,
    this.serverVersion,
  }) : createdAt = createdAt ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'account_id': accountId,
      'amount': amount,
      'effective_date': effectiveDate,
      'entry_kind': entryKind.value,
      'corrects_entry_id': correctsEntryId,
      'correction_reason': correctionReason,
      'notes': notes,
      'idempotency_key': idempotencyKey,
      'created_by': createdBy,
      'created_at': createdAt,
      'cloud_uuid': cloudUuid,
      'server_version': serverVersion,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      shopId: map['shop_id'] as String? ?? '',
      accountId: (map['account_id'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      effectiveDate: map['effective_date'] as String? ?? '',
      entryKind: EntryKind.fromValue(map['entry_kind'] as String? ?? 'OPENING'),
      correctsEntryId: (map['corrects_entry_id'] as num?)?.toInt(),
      correctionReason: map['correction_reason'] as String?,
      notes: map['notes'] as String?,
      idempotencyKey: map['idempotency_key'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      cloudUuid: map['cloud_uuid'] as String?,
      serverVersion: (map['server_version'] as num?)?.toInt(),
    );
  }

  LedgerEntry copyWith({
    int? id,
    String? shopId,
    int? accountId,
    double? amount,
    String? effectiveDate,
    EntryKind? entryKind,
    int? correctsEntryId,
    String? correctionReason,
    String? notes,
    String? idempotencyKey,
    String? createdBy,
    String? createdAt,
    String? cloudUuid,
    int? serverVersion,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      entryKind: entryKind ?? this.entryKind,
      correctsEntryId: correctsEntryId ?? this.correctsEntryId,
      correctionReason: correctionReason ?? this.correctionReason,
      notes: notes ?? this.notes,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      cloudUuid: cloudUuid ?? this.cloudUuid,
      serverVersion: serverVersion ?? this.serverVersion,
    );
  }
}

/// Entry kinds per D2-05 A: OPENING (initial), ADJUSTMENT (owner correction
/// without referencing a prior entry), CORRECTION (references a prior entry).
enum EntryKind {
  opening('OPENING'),
  adjustment('ADJUSTMENT'),
  correction('CORRECTION');

  const EntryKind(this.value);

  final String value;

  static EntryKind fromValue(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntryKind.opening,
    );
  }

  String get displayName {
    switch (this) {
      case EntryKind.opening:
        return 'رصيد افتتاحي';
      case EntryKind.adjustment:
        return 'تعديل';
      case EntryKind.correction:
        return 'تصحيح';
    }
  }
}
