import 'package:baby_words_tracker/util/user_types_and_roles/user_roles.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

extension UserRoleToUserTypeMapper on UserRole {
  UserType get userType {
    switch (this) {
      case UserRole.admin:
        return UserType.researcher;
      case UserRole.researcher:
        return UserType.researcher;
      case UserRole.parent:
        return UserType.parent;
      case UserRole.demo_admin:
        return UserType.demo_researcher;
      case UserRole.demo_researcher:
        return UserType.demo_researcher;
      case UserRole.demo_parent:
        return UserType.demo_parent;
      case UserRole.unauthenticated:
        return UserType.unauthenticated;
    }
  }
}

extension UserTypeToUserRoleMapper on UserType {
  UserRole get userRole {
    switch (this) {
      case UserType.researcher:
        return UserRole.researcher;
      case UserType.parent:
        return UserRole.parent;
      case UserType.demo_parent:
        return UserRole.demo_parent;
      case UserType.demo_researcher:
        return UserRole.demo_researcher;
      case UserType.unauthenticated:
        return UserRole.unauthenticated;
    }
  }
}
