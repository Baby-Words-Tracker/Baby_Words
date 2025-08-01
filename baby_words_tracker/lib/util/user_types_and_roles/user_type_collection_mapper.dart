import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/util/collection_name.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

// TODO: update any methods that use this to correctly account for demo account
extension UserTypeCollectionMapper on UserType {
  CollectionName? get collectionName {
    switch (this) {
      case UserType.parent_type:
        return Parent.collectionName;
      case UserType.researcher_type:
        return Researcher.collectionName;
      case UserType.unauthenticated_type:
        return null;
    }
  }

  static List<CollectionName> allCollectionNames = [
    Parent.collectionName,
    Researcher.collectionName,
  ];
}

UserType? getUserTypeFromCollectionName(String? collectionName) {
  if (collectionName == Parent.collectionName.name ||
      collectionName == Parent.collectionName.demoName) {
    return UserType.parent_type;
  } else if (collectionName == Researcher.collectionName.name ||
      collectionName == Researcher.collectionName.demoName) {
    return UserType.researcher_type;
  }
  return null;
}
