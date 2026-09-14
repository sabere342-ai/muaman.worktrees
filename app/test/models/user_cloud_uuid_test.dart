import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';

void main() {
  User makeUser({String? cloudUuid}) {
    return User(
      id: 1,
      displayName: 'المالك',
      username: 'owner',
      passwordHash: 'salt:hash',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      cloudUuid: cloudUuid,
    );
  }

  Map<String, dynamic> makeMap({String? cloudUuid}) {
    return {
      'id': 1,
      'displayName': 'المالك',
      'username': 'owner',
      'passwordHash': 'salt:hash',
      'role': 'owner',
      'isActive': 1,
      'createdAt': '2024-01-01T00:00:00.000',
      'updatedAt': '2024-01-01T00:00:00.000',
      'lastLoginAt': null,
      'cloud_uuid': cloudUuid,
    };
  }

  group('User cloudUuid model contract', () {
    test('1. fromMap reads non-null cloud_uuid', () {
      final user = User.fromMap(makeMap(cloudUuid: 'abc-123'));
      expect(user.cloudUuid, 'abc-123');
    });

    test('2. fromMap accepts null cloud_uuid', () {
      final user = User.fromMap(makeMap(cloudUuid: null));
      expect(user.cloudUuid, isNull);
    });

    test('3. fromMap accepts map without cloud_uuid key', () {
      final map = makeMap();
      map.remove('cloud_uuid');
      final user = User.fromMap(map);
      expect(user.cloudUuid, isNull);
    });

    test('4. toMap includes cloud_uuid', () {
      final user = makeUser(cloudUuid: 'uuid-1');
      final map = user.toMap();
      expect(map['cloud_uuid'], 'uuid-1');
    });

    test('5. toMap sets cloud_uuid to null when unset', () {
      final user = makeUser();
      final map = user.toMap();
      expect(map.containsKey('cloud_uuid'), isTrue);
      expect(map['cloud_uuid'], isNull);
    });

    test('6. toMap/fromMap round-trip preserves cloud_uuid', () {
      final user = makeUser(cloudUuid: 'round-trip-uuid');
      final map = user.toMap();
      final restored = User.fromMap(map);
      expect(restored.cloudUuid, 'round-trip-uuid');
    });

    test('7. toMap/fromMap round-trip with null cloud_uuid', () {
      final user = makeUser(cloudUuid: null);
      final map = user.toMap();
      final restored = User.fromMap(map);
      expect(restored.cloudUuid, isNull);
    });

    test('8. copyWith preserves cloudUuid when unrelated fields change', () {
      final user = makeUser(cloudUuid: 'keep-this');
      final updated = user.copyWith(displayName: '新しい名前');
      expect(updated.cloudUuid, 'keep-this');
      expect(updated.displayName, '新しい名前');
    });

    test('9. copyWith can update cloudUuid', () {
      final user = makeUser(cloudUuid: 'old-uuid');
      final updated = user.copyWith(cloudUuid: 'new-uuid');
      expect(updated.cloudUuid, 'new-uuid');
    });

    test('10. copyWith null cloudUuid does not clear existing value', () {
      final user = makeUser(cloudUuid: 'existing');
      final updated = user.copyWith();
      expect(updated.cloudUuid, 'existing');
    });

    test('11. dynamic getter access matches named getter (root cause check)',
        () {
      final dynamic dyn = makeUser(cloudUuid: 'dynamic-test');
      expect(dyn.cloudUuid, 'dynamic-test');

      final dynamic dynNull = makeUser();
      expect(dynNull.cloudUuid, isNull);
    });

    test('12. constructor default cloudUuid is null', () {
      final user = User(
        displayName: 'Test',
        username: 'test',
        passwordHash: 'h',
        role: UserRole.owner,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user.cloudUuid, isNull);
    });
  });
}
