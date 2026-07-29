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
}

class InvalidUserRoleException implements Exception {
  final String role;
  InvalidUserRoleException(this.role);

  @override
  String toString() => 'InvalidUserRoleException: Unknown role "$role"';
}
