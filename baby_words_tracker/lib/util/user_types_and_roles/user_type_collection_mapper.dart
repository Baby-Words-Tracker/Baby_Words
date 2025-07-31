import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

extension UserTypeCollectionMapper on UserType {
  String? get collectionName {
    switch (this) {
      case UserType.parent_type:
        return Parent.collectionName;
      case UserType.researcher_type:
        return Researcher.collectionName;
      case UserType.unauthenticated_type:
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
    return UserType.parent_type;
  } else if (collectionName == Researcher.collectionName) {
    return UserType.researcher_type;
  }
  return null;
}
