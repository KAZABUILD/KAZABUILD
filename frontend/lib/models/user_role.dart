/// UserRole enum matching backend UserRole enum
enum UserRole {
  banned(0),
  guest(1),
  unverified(2),
  user(3),
  vip(4),
  moderator(5),
  administrator(6),
  owner(7),
  system(8);

  final int value;
  const UserRole(this.value);

  /// Creates UserRole from string (case-insensitive)
  /// Handles both enum names (e.g., "ADMINISTRATOR") and integer values
  static UserRole fromString(String? roleStr) {
    if (roleStr == null || roleStr.isEmpty) {
      return UserRole.guest;
    }
    
    // Try parsing as integer first (backend might send numeric value)
    final intValue = int.tryParse(roleStr);
    if (intValue != null) {
      return UserRole.values.firstWhere(
        (role) => role.value == intValue,
        orElse: () => UserRole.guest,
      );
    }
    
    // Try matching by name (case-insensitive)
    final normalized = roleStr.trim().toUpperCase();
    return UserRole.values.firstWhere(
      (role) => role.name.toUpperCase() == normalized,
      orElse: () {
        // If no match found, try common variations
        switch (normalized) {
          case 'ADMIN':
          case 'ADMINISTRATOR':
            return UserRole.administrator;
          case 'MOD':
          case 'MODERATOR':
            return UserRole.moderator;
          case 'USER':
            return UserRole.user;
          case 'BANNED':
            return UserRole.banned;
          case 'GUEST':
            return UserRole.guest;
          case 'UNVERIFIED':
            return UserRole.unverified;
          default:
            return UserRole.guest;
        }
      },
    );
  }

  /// Checks if user has administrator privileges
  /// Includes ADMINISTRATOR, OWNER, and SYSTEM roles
  bool get isAdministrator => 
      this == UserRole.administrator || 
      this == UserRole.owner || 
      this == UserRole.system;

  /// Checks if user has moderator or higher privileges
  bool get isModeratorOrHigher => value >= UserRole.moderator.value;

  /// Checks if user has staff privileges (moderator or administrator)
  bool get isStaff => isModeratorOrHigher;
}

