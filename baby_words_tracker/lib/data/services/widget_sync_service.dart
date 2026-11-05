import 'dart:async'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/src/home_widget/greeting.home_widget.dart';

class WidgetSyncService {
  StreamSubscription? _subscription;
  String? _lastTrackedId;

  void startGlobalSync(String childId, String childName) {
    if (childId.isEmpty) {
      debugPrint("WidgetSyncService: Cancelled. Target childId is empty.");
      setPlaceholderState();
      return;
    }

    if (_lastTrackedId == childId) return; 
    _lastTrackedId = childId;
    
    _subscription?.cancel();
    debugPrint("WidgetSyncService: Starting live database stream for child: $childName ($childId)");

    _subscription = FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .snapshots()
        .listen((snapshot) async {

      // Grab the direct size of the array documents
      int totalWords = snapshot.docs.length;
      debugPrint("WidgetSyncService: Firestore update caught! Total words found: $totalWords");

      try {
        // Push the values directly to the code-generated home widget wrapper
        await GreetingHomeWidget.saveData(
          name: childName,
          wordsCount: totalWords.toString(),
        );
        
        // Signal the operating system to force a visual redraw on screen
        await GreetingHomeWidget.updateWidget();
        debugPrint("WidgetSyncService: Native screen widget updated successfully.");
      } catch (e) {
        debugPrint("WidgetSyncService: Error saving data to home layout: $e");
      }
    }, onError: (error) {
      debugPrint("WidgetSyncService: Firestore stream hit an error: $error");
    });
  }

  void setPlaceholderState() async {
    debugPrint("WidgetSyncService: Setting safe layout fallback placeholder state.");
    _lastTrackedId = null;
    _subscription?.cancel();

    await GreetingHomeWidget.saveData(
      name: 'Baby',
      wordsCount: '0',
    );
    await GreetingHomeWidget.updateWidget();
  }

  void dispose() {
    _subscription?.cancel();
  }
}