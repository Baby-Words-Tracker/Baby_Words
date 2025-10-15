import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> callAddChildToOtherParentCloudFunction(
    BuildContext context, String childID, String otherParentEmail) async {
  debugPrint('Getting callable for addChildToOtherParent');
  final LocalizationService localizationService =
      context.read<LocalizationService>();
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("addChildToOtherParent");
  try {
    debugPrint(
        'Calling function addChildToOtherParent with childID $childID and otherParentEmail $otherParentEmail');
    final response = await function
        .call({'childUid': childID, 'targetEmail': otherParentEmail});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizationService.translate(
          response.data['message'],
        ))),
      );
    } else {
      debugPrint(
        'Context not mounted, showing debug message instead: ${localizationService.translate(response.data['message'])}',
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizationService.translate(
                'callAddChildToOtherParentCloudFunction() Error: $error'))),
      );
    } else {
      debugPrint(
        'Context not mounted, showing debug message instead: callAddChildToOtherParentCloudFunction() Error: $error',
      );
    }
  }
}

Future<void> addCurrentChildToOtherParent(
    BuildContext context, String otherParentEmail) async {
  // Use new user model service
  final userProfileModelService = context.read<UserProfileModelService>();
  final userId = userProfileModelService.userProfile?.id;
  
  if (userId == null || !userProfileModelService.isParent) {
    showAlertMessage(
        context, "Child Add Failed", "You're somehow not a parent?????");
    return;
  }
  Child? currChild = context.read<CurrentChildrenService>().getCurrChild();
  String? currChildID;
  String? currChildName;
  if (currChild != null) {
    currChildID = currChild.id;
    currChildName = currChild.name;
  }
  if (currChildID == null) {
    showAlertMessage(context, "Child Add Failed",
        "Child selection invalid, please try again.");
    return;
  }
  if (currChildName == null) {
    showAlertMessage(context, "Child Add Failed",
        "Failed to find your child's name, please try again.");
    return;
  }
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            return AlertDialog(
              title: Text(localizationService.translate("Confirm Action")),
              content: Text(localizationService.translate("grant_permission") +
                  otherParentEmail +
                  localizationService.translate("access_child") +
                  currChildName!),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User pressed No
                  },
                  child: Text(localizationService.translate("No")),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // User pressed Yes
                  },
                  child: Text(localizationService.translate("Yes")),
                ),
              ],
            );
          },
        );
      }).then(
    (confirmed) {
      if (confirmed != null && confirmed) {
        // Check if context is still mounted before using it after async operation
        if (context.mounted) {
          callAddChildToOtherParentCloudFunction(
              context, currChildID!, otherParentEmail);
        }
      } else {
        return;
      }
    },
  );
  return;
}

Consumer addCurrentChildToOtherParentFeature(
    BuildContext context, TextEditingController otherParentEmailController) {
  return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizationService.translate("child_to_new_parent"),
          style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700) ??
              TextStyle(
                  fontSize: 27,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20.0),
        TextField(
          controller: otherParentEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: localizationService.translate("choose_email"),
            hintText: localizationService.translate("choose_email"),
            suffixIcon: Icon(
              Icons.alternate_email,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (otherParentEmailController.text.isNotEmpty) {
                addCurrentChildToOtherParent(
                    context, otherParentEmailController.text);
              } else {
                showAlertMessage(
                    context,
                    localizationService.translate("child_not_added"),
                    localizationService.translate("no_email"));
              }
              otherParentEmailController.clear();
            },
            child: Text(localizationService.translate("submit")),
          ),
        ),
      ],
    );
  });
}

Future<void> addChildToCurrParent(BuildContext context, String name,
    DateTime bday, List<LanguageCode> langauges) async {
  // Use new user model service and user profile service
  final userProfileModelService = context.read<UserProfileModelService>();
  final userProfileService = context.read<UserProfileService>();
  final userId = userProfileModelService.userProfile?.id;
  
  if (userId != null && userProfileModelService.isParent) {
    // Create child
    Child? child = await context
        .read<ChildDataService>()
        .createChild(DateTime.now(), name, langauges, 0, [userId]);
    
    // Add child ID to UserProfile instead of old Parent collection
    final childId = child?.id;
    if (childId != null) {
      try {
        await userProfileService.addChild(userId, childId);
        debugPrint('Child $childId added to UserProfile $userId');

        // Proactively refresh current children list for immediate UI update
        final currentChildrenService = context.read<CurrentChildrenService>();
        final updatedIds = List<String>.from(
          userProfileModelService.userProfile?.childIDs ?? const <String>[],
        )..add(childId);
        await currentChildrenService.updateChildrenFromIds(updatedIds);
      } catch (e) {
        debugPrint('Error adding child to UserProfile: $e');
        // Fallback to old system if new one fails
        try {
          final parentDataService = context.read<ParentDataService>();
          await parentDataService.addChildToParent(userId, childId);
        } catch (e2) {
          debugPrint('Fallback also failed: $e2');
        }
      }
    }
  }
}

Consumer childAddingFeature(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController dateController) {
  return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //const Text("Add a Child:"), //FIXME: ugly
        Text(localizationService.translate("add_child"),
            style: const TextStyle(
                fontSize: 22.0,
                color: Color(0xFF9E1B32),
                fontWeight: FontWeight.bold)),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: localizationService.translate("choose_name"),
            hintText: localizationService.translate("choose_name"),
          ),
        ),
        TextField(
          controller: dateController,
          onTap: () => selectDate(context, dateController),
          readOnly: true,
          decoration: InputDecoration(
            //border: OutlineInputBorder(),
            hintText: localizationService
                .translate("choose_birthday"), //'Tap to Choose Birthday..',
            hintStyle: const TextStyle(color: Colors.white),
            filled: true,
            fillColor: const Color(0xFF9E1B32),
          ),
        ),
        Center(
            child: OutlinedButton(
          onPressed: () {
            if (nameController.text != "" &&
                dateController.text !=
                    "") //add the word to the child with the id, or the default testing child if no input
            {
              //add child
              addChildToCurrParent(context, nameController.text,
                  DateTime.parse(dateController.text), [LanguageCode.en]);
              //added indicator
              showAlertMessage(
                  context,
                  localizationService.translate("child_added"),
                  localizationService.translate(
                      "add_child_success")); //"Child Added!", "Successfully added your child!");
            } else {
              //failed to add indicator //FIXME: better error checking
              showAlertMessage(
                  context,
                  localizationService
                      .translate("child_not_added"), //"Child Add Failed",
                  localizationService.translate(
                      "add_child_failed")); //"Failed to add yoour child, please try again.");
            }
            nameController.clear();
            dateController.clear();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF828A8F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
          ),
          child: Text(localizationService.translate("submit"),
              style: const TextStyle(fontSize: 18)),
        )),
      ],
    );
  });
}

Future<bool> addWordToChild(
  String childId,
  String word,
  WordTrackerDataService trackerService,
) async {
  return trackerService.addOrUpdateWordTracker(
    childId,
    word,
    WordTracker(
      id: word,
      firstUtterance: DateTime.now(),
    ),
  );
}

Column wordAddingFeature(
    BuildContext context,
    TextEditingController wordTextController,
    TextEditingController idController,
    WordTrackerDataService trackerService) {
  return Column(
    children: [
      TextField(
        controller: wordTextController,
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'Add this word to..',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Color(0xFF9E1B32),
        ),
      ),
      TextField(
        controller: idController,
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'child with id.. [or leave empty for testing child]',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Color(0xFF9E1B32),
        ),
      ),
      Center(
          child: OutlinedButton(
        onPressed: () {
          if (idController.text !=
              "") //add the word to the child with the id, or the default testing child if no input
          {
            addWordToChild(
              idController.text,
              wordTextController.text,
              trackerService,
            );
          } else {
            debugPrint("No child ID provided, so word cannot be added.");
            showAlertMessage(context, "Word Add Failed",
                "No child ID provided, so word cannot be added.");
          }
          wordTextController.clear();
          idController.clear();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF828A8F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
        ),
        child: const Text('Submit', style: TextStyle(fontSize: 18)),
      )),
    ],
  );
}
