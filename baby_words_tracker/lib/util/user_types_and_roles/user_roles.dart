// note: lower numbers are higher authority roles
enum UserRole { admin, researcher, parent, unauthenticated }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.researcher:
        return 'researcher';
      case UserRole.parent:
        return 'parent';
      case UserRole.unauthenticated:
        return 'unauthenticated';
    }
  }

  /// This function determines the authority of the role.
  /// Lower index means higher authority.
  /// Admin should always be 0 and demo roles should always
  /// be higher than demo_admin and lower than unauthenticated.
  /// Returns int The index of the role.
  int get index {
    switch (this) {
      case UserRole.admin:
        return 0;
      case UserRole.researcher:
        return 3;
      case UserRole.parent:
        return 6;
      case UserRole.unauthenticated:
        return 100;
    }
  }
}

bool isAtLeast(UserRole role, UserRole targetRole) {
  return role.index <= targetRole.index;
}

/// Returns a list of UserRole based on the provided claims map.
/// [claims] is the map containing user roles as keys with boolean values.
/// Returns List\<UserRole\> A list of UserRole objects based on the claims
///   or an empty list if no roles are matched.
/// Returns unauthenticated if [claims] is null.
List<UserRole> getUserRolesFromClaims(Map<String, dynamic>? claims) {
  if (claims == null) return [UserRole.unauthenticated];

  List<UserRole> roles = [];

  if (claims[UserRole.admin.name] == true) {
    roles.add(UserRole.admin);
  }
  if (claims[UserRole.researcher.name] == true) {
    roles.add(UserRole.researcher);
  }
  if (claims[UserRole.parent.name] == true) {
    roles.add(UserRole.parent);
  }
  if (claims[UserRole.unauthenticated.name] == true) {
    roles.add(UserRole.unauthenticated);
  }

  return roles;
}
