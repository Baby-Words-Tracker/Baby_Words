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

List<UserRole> getUserRolesFromClaims(Map<String, dynamic> claims) {
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

  return roles;
}
