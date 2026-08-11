import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/shop_profile.dart';

/// Persists the [ShopProfile] in the application database.
///
/// Storage strategy is the existing `app_settings` key-value table — the same
/// storage the application already uses for its settings (see
/// [services/app_settings.dart]). Adding shop identity keys is purely additive:
/// no schema change, no data rewrite, and an upgraded database that predates
/// this feature simply loads the safe [ShopProfile.defaultProfile].
class ShopProfileRepository {
  ShopProfileRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper;

  final DatabaseHelper? _dbHelper;

  DatabaseHelper get _helper => _dbHelper ?? DatabaseHelper.instance;

  static const String keyShopName = 'shopProfile.shopName';
  static const String keyOwnerOrManagerName = 'shopProfile.ownerOrManagerName';
  static const String keyPhone = 'shopProfile.phone';
  static const String keyAddress = 'shopProfile.address';
  static const String keyLogoPath = 'shopProfile.logoPath';

  /// Loads the persisted profile. A missing row for any field falls back to
  /// the safe default so an upgraded database without shop identity settings
  /// keeps working with the current identity.
  Future<ShopProfile> load() async {
    final db = await _helper.database;
    final String shopName;
    final String ownerOrManagerName;
    final String phone;
    final String address;
    final String logoPath;
    try {
      shopName = (await _getValue(db, keyShopName)).trim();
      ownerOrManagerName = await _getValue(db, keyOwnerOrManagerName);
      phone = await _getValue(db, keyPhone);
      address = await _getValue(db, keyAddress);
      logoPath = await _getValue(db, keyLogoPath);
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        // A database without the settings table has no persisted identity.
        return ShopProfile.defaultProfile();
      }
      rethrow;
    }
    return ShopProfile(
      shopName: shopName.isEmpty ? ShopProfile.defaultShopName : shopName,
      ownerOrManagerName: ownerOrManagerName,
      phone: phone,
      address: address,
      logoPath: logoPath,
    );
  }

  /// Persists the profile. All values are trimmed before storage.
  Future<void> save(ShopProfile profile) async {
    final db = await _helper.database;
    await _setValue(db, keyShopName, profile.shopName.trim());
    await _setValue(
        db, keyOwnerOrManagerName, profile.ownerOrManagerName.trim());
    await _setValue(db, keyPhone, profile.phone.trim());
    await _setValue(db, keyAddress, profile.address.trim());
    await _setValue(db, keyLogoPath, profile.logoPath);
  }

  Future<String> _getValue(Database db, String key) async {
    final rows = await db.query('app_settings',
        columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return '';
    return rows.first['value'] as String;
  }

  Future<void> _setValue(Database db, String key, String value) async {
    final rows = await db.query('app_settings',
        columns: ['key'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) {
      await db.insert('app_settings', {'key': key, 'value': value});
    } else {
      await db.update('app_settings', {'value': value},
          where: 'key = ?', whereArgs: [key]);
    }
  }
}
