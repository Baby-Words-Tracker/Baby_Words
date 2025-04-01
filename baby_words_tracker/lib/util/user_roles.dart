// note: lower numbers are higher authority roles
enum UserRole { admin, researcher, parent, unauthenticated }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.parent:
        return 'Parent';
      case UserRole.unauthenticated:
        return 'Unauthenticated';
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

  if (claims['admin'] == true) {
    roles.add(UserRole.admin);
  }
  if (claims['researcher'] == true) {
    roles.add(UserRole.researcher);
  }
  if (claims['parent'] == true) {
    roles.add(UserRole.parent);
  }

  return roles;
}
