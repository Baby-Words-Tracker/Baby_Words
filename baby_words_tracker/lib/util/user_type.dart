enum UserType { parent, researcher, admin, unauthenticated }

extension UserTypeExtension on UserType {
  String get name {
    switch (this) {
      case UserType.parent:
        return 'Parent';
      case UserType.researcher:
        return 'Researcher';
      case UserType.admin:
        return 'Admin';
      case UserType.unauthenticated:
        return 'Unauthenticated';
    }
  }
}