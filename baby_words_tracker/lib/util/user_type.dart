// make sure to update user_type_collection_mapper.dart when adding user types
enum UserType { parent, researcher, unauthenticated }

extension UserTypeExtension on UserType {
  String get displayName {
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
