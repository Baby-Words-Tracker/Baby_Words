import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/util/user_type.dart';

extension UserTypeCollectionMapper on UserType {
  String? get collectionName {
    switch (this) {
      case UserType.parent:
        return Parent.collectionName;
      case UserType.researcher:
        return Researcher.collectionName;
      case UserType.unauthenticated:
        return null;
    }
  }

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
  }
  return null;
}
