// make sure to update user_type_collection_mapper.dart when adding user types
// make sure to update changeUserType from admin_page.dart when adding user types
enum UserType {
  parent,
  researcher,
  // ignore: constant_identifier_names
  demo_parent,
  // ignore: constant_identifier_names
  demo_researcher,
  unauthenticated
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.parent:
        return 'Parent';
      case UserType.researcher:
        return 'Researcher';
      case UserType.demo_parent:
        return 'Demo Parent';
      case UserType.demo_researcher:
        return 'Demo Researcher';
      case UserType.unauthenticated:
        return 'Unauthenticated';
    }
  }

  bool get isDemoType {
    return this == UserType.demo_parent || this == UserType.demo_researcher;
  }
}
