import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

extension UserTypeCollectionMapper on UserType {
  String? get collectionName {
    switch (this) {
      case UserType.parent:
        return Parent.collectionName;
      case UserType.researcher:
        return Researcher.collectionName;
      case UserType.demo_parent:
        return "demo_${Parent.collectionName}";
      case UserType.demo_researcher:
        return "demo_${Researcher.collectionName}";
      case UserType.unauthenticated:
        return null;
    }
  }

  // TODO: add demo collection names if needed
  static List<String> allCollectionNames = [
    Parent.collectionName,
    Researcher.collectionName,
  ];
}

UserType? getUserTypeFromCollectionName(String? collectionName) {
  if (collectionName == Parent.collectionName) {
    return UserType.parent;
  } else if (collectionName == Researcher.collectionName) {
    return UserType.researcher;
  } else if (collectionName == "demo_${Parent.collectionName}") {
    return UserType.demo_parent;
  } else if (collectionName == "demo_${Researcher.collectionName}") {
    return UserType.demo_researcher;
  }
  return null;
}
