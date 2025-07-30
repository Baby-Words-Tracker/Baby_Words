enum DemoRole { demo }

extension DemoRoleExtension on DemoRole {
  String get name => 'demo';

  /// This function determines the authority of the demo role.
  /// It is always higher than any demo roles and lower than unauthenticated.
  int get index => 50;

  bool get isDemoRole => true;
}

/// Returns a list of UserRole based on the provided claims map.
/// [claims] is the map containing user roles as keys with boolean values.
/// Returns List\<UserRole\> A list of UserRole objects based on the claims
///   or an empty list if no roles are matched.
/// Returns unauthenticated if [claims] is null.
bool isDemoRoleFromClaims(Map<String, dynamic>? claims) {
  if (claims == null) return false;

  if (claims[DemoRole.demo.name] == true) {
    return true;
  }

  return false;
}
