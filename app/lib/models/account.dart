/// Phase P Group D D2 (P-OD5): per-shop accounting account (D2-01 A).
///
/// The catalog is additive and seeded EMPTY for every shop. The [accountType]
/// determines balance direction (D2-02 C — type-aware sign convention).
class Account {
  final int? id;
  final String shopId;
  final String name;
  final AccountType accountType;
  final String? createdBy;
  final String? cloudUuid;
  final int? serverVersion;

  Account({
    this.id,
    required this.shopId,
    required this.name,
    required this.accountType,
    this.createdBy,
    this.cloudUuid,
    this.serverVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'account_type': accountType.value,
      'created_by': createdBy,
      'cloud_uuid': cloudUuid,
      'server_version': serverVersion,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      shopId: map['shop_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      accountType: AccountType.fromValue(map['account_type'] as String? ?? 'CASH'),
      createdBy: map['created_by'] as String?,
      cloudUuid: map['cloud_uuid'] as String?,
      serverVersion: (map['server_version'] as num?)?.toInt(),
    );
  }

  Account copyWith({
    int? id,
    String? shopId,
    String? name,
    AccountType? accountType,
    String? createdBy,
    String? cloudUuid,
    int? serverVersion,
  }) {
    return Account(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      createdBy: createdBy ?? this.createdBy,
      cloudUuid: cloudUuid ?? this.cloudUuid,
      serverVersion: serverVersion ?? this.serverVersion,
    );
  }
}

/// Account types per D2-02 C: type-aware balance direction.
/// - CASH / BANK / RECEIVABLE_SUMMARY: positive = asset (owned/owed to shop)
/// - PAYABLE_SUMMARY / CAPITAL: positive = obligation (owed by shop)
enum AccountType {
  cash('CASH'),
  bank('BANK'),
  receivableSummary('RECEIVABLE_SUMMARY'),
  payableSummary('PAYABLE_SUMMARY'),
  capital('CAPITAL');

  const AccountType(this.value);

  final String value;

  static AccountType fromValue(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => AccountType.cash,
    );
  }

  bool get isAsset =>
      this == AccountType.cash ||
      this == AccountType.bank ||
      this == AccountType.receivableSummary;

  bool get isLiability =>
      this == AccountType.payableSummary || this == AccountType.capital;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'نقداً';
      case AccountType.bank:
        return 'بنك';
      case AccountType.receivableSummary:
        return 'مدينون عامين';
      case AccountType.payableSummary:
        return 'دائنون عامين';
      case AccountType.capital:
        return 'رأس مال';
    }
  }
}
