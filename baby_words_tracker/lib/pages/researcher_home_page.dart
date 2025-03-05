import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';


class ResearcherHomePage extends StatelessWidget {

  const ResearcherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Baby Word Tracker', style: TextStyle(color: Color(0xFF9E1B32), 
                                                         fontSize: 24,        
                                                         fontWeight: FontWeight.bold, 
                                                        ),
                          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) =>  ProfileScreen(
                    appBar: AppBar(
                        title: const Text('User Profile'),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      })
                    ],
                  ),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF9E1B32),
        child: Padding(
        padding: EdgeInsets.all(16.0), 
  ),
),
      body: const WordTrackerTable(),
    );
  }
}

class WordTrackerTable extends StatefulWidget{
  const WordTrackerTable({super.key});

  @override
  State<WordTrackerTable> createState() => _WordTrackerTableState();
}

class _WordTrackerTableState extends State<WordTrackerTable> {

  late FirestoreDataTableSource _dataSource;
  bool _isAscending = true;
  int _sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    _dataSource = FirestoreDataTableSource();
    _fetchWordTrackers();
  }

  void _fetchWordTrackers() async {
    await _dataSource.fetchData();
    setState(() {}); // Refresh UI after data is fetched
  }

  void _sort<T>(Comparable<T> Function(WordInstance wordInstance) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _dataSource.sort(getField, ascending);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: PaginatedDataTable(
          header: const Text("Word Utterances", textAlign: TextAlign.center),
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _isAscending,
          columns: [
            DataColumn(
              label: const Text("Child"),
              onSort: (columnIndex, ascending) => _sort((wordInstance) => wordInstance.childName, columnIndex, ascending),
            ),
            DataColumn(
              label: const Text("Age"),
              onSort: (columnIndex, ascending) => _sort((wordInstance) => wordInstance.childAge, columnIndex, ascending),
            ),
            DataColumn(
              label: const Text("Word"),
              onSort: (columnIndex, ascending) => _sort((wordInstance) => wordInstance.id, columnIndex, ascending),
            ),
            DataColumn(
              label: const Text("First Utterance"),
              numeric: true,
              onSort: (columnIndex, ascending) => _sort((wordInstance) => wordInstance.firstUtterance, columnIndex, ascending),
            ),
            DataColumn(
              label: const Text("Video ID"),
              numeric: true,
              onSort: (columnIndex, ascending) => _sort((wordInstance) => wordInstance.videoID, columnIndex, ascending),
            ),
          ],
          source: _dataSource,
          rowsPerPage: 5, // Number of rows per page
        ),
      );
  }
}

class FirestoreDataTableSource extends DataTableSource {
  List<WordInstance> _wordInstances = [];

  Future<void> fetchData() async {
  List<WordInstance> wordInstances = [];

  try {
    // Get all Child documents
    QuerySnapshot childSnapshot = await FirebaseFirestore.instance.collection('Child').get();
    
    // Iterate through each Child document
    for (var childDoc in childSnapshot.docs) {
      try {
        String childName = childDoc['name'];
        DateTime currentTime = DateTime.now();
        DateTime childBirthday = (childDoc['birthday'] as Timestamp).toDate();
        int childAge = currentTime.year - childBirthday.year;
        if((childBirthday.month > currentTime.month) || (childBirthday.month == currentTime.month && childBirthday.day > currentTime.day)){
          childAge--;
        }
        // Get the WordTracker subcollection of the current Child document
        QuerySnapshot wordTrackerSnapshot = await childDoc.reference.collection('WordTracker').get();
        
        // Map the WordTracker documents to WordTracker objects and add to the list
        wordInstances.addAll(wordTrackerSnapshot.docs.map((doc) {
          return WordInstance(
            childName: childName,
            childAge: childAge,
            id: doc.id,
            firstUtterance: doc['firstUtterance'] != null
                            ? (doc['firstUtterance'] as Timestamp).toDate().toString()
                            : 'Unknown',
            videoID: doc['videoID'] ?? 0,
          );
        }).toList());
      } catch (e) {
        debugPrint('Error fetching WordTracker subcollection for Child document ${childDoc.id}: $e');
      }
    }

    _wordInstances = wordInstances;
    notifyListeners(); // Refresh the table
  } catch (e) {
    debugPrint('Error fetching Child documents: $e');
  }
}

  void sort<T>(Comparable<T> Function(WordInstance wordTracker) getField, bool ascending) {
    _wordInstances.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    notifyListeners(); // Refresh table after sorting
  }

  @override
  DataRow getRow(int index) {
    if (index >= _wordInstances.length) return const DataRow(cells: []);
    final wordInstance = _wordInstances[index];
    return DataRow(cells: [
      DataCell(Text(wordInstance.childName)),
      DataCell(Text(wordInstance.childAge.toString())),
      DataCell(Text(wordInstance.id)),
      DataCell(Text(wordInstance.firstUtterance)),
      DataCell(Text(wordInstance.videoID.toString())),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _wordInstances.length;

  @override
  int get selectedRowCount => 0;
}

class WordInstance {
  final String childName;
  final int childAge;
  final String id;
  final String firstUtterance;
  final int videoID;

  WordInstance({required this.childName, required this.childAge, required this.id, required this.firstUtterance, required this.videoID});
}

