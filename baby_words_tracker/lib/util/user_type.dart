enum UserType { parent, researcher, unauthenticated }

extension UserTypeExtension on UserType {
  String get name {
    switch (this) {
      case UserType.parent:
        return 'Parent';
      case UserType.researcher:
        return 'Researcher';
      case UserType.unauthenticated:
        return 'Unauthenticated';
    }
  }
}