// note: lower numbers are higher authority roles
enum UserRole {
  admin,
  researcher,
  parent,
  // ignore: constant_identifier_names
  demo_admin,
  // ignore: constant_identifier_names
  demo_researcher,
  // ignore: constant_identifier_names
  demo_parent,
  unauthenticated
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.researcher:
        return 'researcher';
      case UserRole.parent:
        return 'parent';
      case UserRole.demo_admin:
        return 'demo_admin';
      case UserRole.demo_researcher:
        return 'demo_researcher';
      case UserRole.demo_parent:
        return 'demo_parent';
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
      case UserRole.demo_admin:
        return 50;
      case UserRole.demo_researcher:
        return 53;
      case UserRole.demo_parent:
        return 56;
      case UserRole.unauthenticated:
        return 100;
    }
  }
}

bool isDemoRole(UserRole role) {
  return role.index >= UserRole.demo_admin.index &&
      role.index < UserRole.unauthenticated.index;
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
  if (claims[UserRole.demo_admin.name] == true) {
    roles.add(UserRole.demo_admin);
  }
  if (claims[UserRole.demo_researcher.name] == true) {
    roles.add(UserRole.demo_researcher);
  }
  if (claims[UserRole.demo_parent.name] == true) {
    roles.add(UserRole.demo_parent);
  }
  if (claims[UserRole.unauthenticated.name] == true) {
    roles.add(UserRole.unauthenticated);
  }

  return roles;
}
