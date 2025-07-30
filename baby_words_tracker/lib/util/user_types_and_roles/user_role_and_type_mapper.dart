import 'package:baby_words_tracker/util/user_types_and_roles/user_roles.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

/// This extension maps UserRole to UserType.
extension UserRoleToUserTypeMapper on UserRole {
  /// Returns the UserType corresponding to the UserRole.
  /// Some roles to not have a corresponding UserType, in which case it returns null.
  UserType? get userType {
    switch (this) {
      case UserRole.researcher:
        return UserType.researcher_type;
      case UserRole.parent:
        return UserType.parent_type;
      case UserRole.unauthenticated:
        return UserType.unauthenticated_type;
      default:
        return null;
    }
  }
}

extension UserTypeToUserRoleMapper on UserType {
  UserRole get userRole {
    switch (this) {
      case UserType.researcher_type:
        return UserRole.researcher;
      case UserType.parent_type:
        return UserRole.parent;
      case UserType.unauthenticated_type:
        return UserRole.unauthenticated;
    }
  }
}
