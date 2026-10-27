import 'dart:async'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';

import 'package:baby_words_tracker/src/home_widget/greeting.home_widget.dart';

class WidgetSyncService {
  StreamSubscription? _subscription;
  String? _lastTrackedId;

  void startGlobalSync(String childId, String childName) {
    if (_lastTrackedId == childId) return; 
    _lastTrackedId = childId;
    
    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .snapshots()
        .listen((snapshot) async {

      int totalWords = snapshot.docs.length;

      await GreetingHomeWidget.saveData(
        name: childName,
        wordsCount: totalWords.toString(),
      );
      
      await GreetingHomeWidget.updateWidget();
    });
  }

  void setPlaceholderState() async {
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