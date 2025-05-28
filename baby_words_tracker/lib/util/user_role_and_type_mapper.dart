import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:baby_words_tracker/util/user_type.dart';

extension UserRoleToUserTypeMapper on UserRole {
  UserType get userType {
    switch (this) {
      case UserRole.admin:
        return UserType.researcher;
      case UserRole.researcher:
        return UserType.researcher;
      case UserRole.parent:
        return UserType.parent;
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
      case UserType.unauthenticated:
        return UserRole.unauthenticated;
    }
  }
}
