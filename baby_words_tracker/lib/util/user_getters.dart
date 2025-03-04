//Function to get current parent, returns null if the userType is not parent
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/config.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Returns the ID of the current user if they are a parent, else returns null
Parent? getCurrentParent (BuildContext context) {
    if (context.read<UserModelService>().userType == UserType.parent)
    {
      return context.read<UserModelService>().parent!; 
    } else {
      return null;
    }
}

//Returns the current child, or null if the currently selected index is invalid
//Listens for future updates to childID, and has the tree rebuild
String? getCurrentChildIDListening (BuildContext context, Parent currParent) {
  int childIndex = context.watch<Config>().childIndex;
  if (childIndex >= 0 && currParent.childIDs.length > childIndex)
  {
    return currParent.childIDs[childIndex];
  } else {
    return null;
  }
}

//Returns the current child, or null if the currently selected index is invalid
String? getCurrentChildIDSingleInstance (BuildContext context, Parent currParent) {
  int childIndex = context.read<Config>().childIndex;
  if (childIndex >= 0 && currParent.childIDs.length > childIndex)
  {
    return currParent.childIDs[childIndex];
  } else {
    return null;
  }
}


    