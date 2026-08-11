enum UserRole {
  owner,
  employee,
  salesOnly;

  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.employee:
        return 'employee';
      case UserRole.salesOnly:
        return 'salesOnly';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'مالك';
      case UserRole.employee:
        return 'موظف';
      case UserRole.salesOnly:
        return 'موظف مبيعات فقط';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'employee':
        return UserRole.employee;
      case 'salesOnly':
        return UserRole.salesOnly;
      default:
        throw InvalidUserRoleException(value);
    }
  }

  static UserRole? fromStringOrNull(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

class InvalidUserRoleException implements Exception {
  final String role;
  InvalidUserRoleException(this.role);

  @override
  String toString() => 'InvalidUserRoleException: Unknown role "$role"';
}
