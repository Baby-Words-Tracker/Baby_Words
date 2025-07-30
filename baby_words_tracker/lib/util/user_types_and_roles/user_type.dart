// make sure to update user_type_collection_mapper.dart when adding user types
// make sure to update changeUserType from admin_page.dart when adding user types
/// An enum to represent the different user types in the app.
/// Each user should only have one type at a time in their claims
enum UserType {
  // ignore: constant_identifier_names
  parent_type,
  // ignore: constant_identifier_names
  researcher_type,
  // ignore: constant_identifier_names
  unauthenticated_type
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.parent_type:
        return 'Parent';
      case UserType.researcher_type:
        return 'Researcher';
      case UserType.unauthenticated_type:
        return 'Unauthenticated';
    }
  }
}

/// Returns the UserType based on the provided claims.
/// [claims] is the map containing user types as keys with boolean values.
/// Returns UserType The UserType based on the claims or unauthenticated_type
///    if no types are matched.
/// Returns unauthenticated_type if [claims] is null.
UserType getUserTypeFromClaims(Map<String, dynamic>? claims) {
  if (claims == null) return UserType.unauthenticated_type;

  if (claims[UserType.parent_type.name] == true) {
    return UserType.parent_type;
  }
  if (claims[UserType.researcher_type.name] == true) {
    return UserType.researcher_type;
  }
  if (claims[UserType.unauthenticated_type.name] == true) {
    return UserType.unauthenticated_type;
  }

  return UserType.unauthenticated_type;
}
