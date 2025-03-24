import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';


class ResearcherHomePage extends StatefulWidget {
  const ResearcherHomePage({super.key});

  @override
  State<ResearcherHomePage> createState() => _ResearcherHomePageState();
}

class _ResearcherHomePageState extends State<ResearcherHomePage> {
  FieldLabel? selectedField;
  String? selectedEntry;
  List<WordInstance> wordInstances = [];

  void updateFilter(FieldLabel? field, String? entry) {
    setState(() {
      selectedField = field;
      selectedEntry = entry;
    });
     debugPrint("Filter updated: Field -> $selectedField, Entry -> $selectedEntry");
  }

  void updateWordInstances(List<WordInstance> instances) {
    setState(() {
      wordInstances = instances; 
    });
  }

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
      body: 
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
                const Text('Hello, Researcher!', style: TextStyle(color: Color(0xFF9E1B32), 
                                                         fontSize: 24,        
                                                         fontWeight: FontWeight.bold,)),
                Expanded(
                  flex: 1,
                  child: FilterMenu(onFilterChanged: updateFilter, dataSource: wordInstances,)
                  ),
                Expanded(
                  flex: 3,
                  child: WordTrackerTable(key: ValueKey('$selectedField-$selectedEntry'),
                                          selectedField: selectedField,  
                                          selectedEntry: selectedEntry,
                                          onDataFetched: updateWordInstances)
                )
                ]),
        ),
    );
  }
}

class WordTrackerTable extends StatefulWidget{

  final FieldLabel? selectedField;
  final String? selectedEntry;
  final void Function(List<WordInstance>) onDataFetched;

  const WordTrackerTable({super.key, this.selectedField, this.selectedEntry, required this.onDataFetched});

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
    widget.onDataFetched(_dataSource._wordInstances);
    _applyFilter();
  }

  void _applyFilter() {
    _dataSource.filterData(widget.selectedField, widget.selectedEntry);
    setState(() {});
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
    final rows = _dataSource.getFilteredData();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
          child: DataTable(
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
            rows: rows.map((wordInstance) => DataRow(
              cells: [
                DataCell(Text(wordInstance.childName)),
                DataCell(Text(wordInstance.childAge.toString())),
                DataCell(Text(wordInstance.id)),
                DataCell(Text(wordInstance.firstUtterance)),
                DataCell(Text(wordInstance.videoID.toString())),
              ],
            )).toList(),
          ),
        ),
    );
  }
}

class FirestoreDataTableSource extends DataTableSource {
  List<WordInstance> _wordInstances = [];
  List<WordInstance> _filteredInstances = [];
  bool _isDataFetched = false;

  Future<void> fetchData() async {

  if(_isDataFetched) return;
  
  try {

    debugPrint('querying');
    List<WordInstance> wordInstances = [];
    
    QuerySnapshot childSnapshot = await FirebaseFirestore.instance.collection('Child').get();
    
    
    for (var childDoc in childSnapshot.docs) {
      try {
        String childName = childDoc['name'];
        DateTime currentTime = DateTime.now();
        DateTime childBirthday = (childDoc['birthday'] as Timestamp).toDate();
        int childAge = currentTime.year - childBirthday.year;
        if((childBirthday.month > currentTime.month) || (childBirthday.month == currentTime.month && childBirthday.day > currentTime.day)){
          childAge--;
        }
        
        QuerySnapshot wordTrackerSnapshot = await childDoc.reference.collection('WordTracker').get();
        
        
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
    _filteredInstances = List.from(_wordInstances);
    _isDataFetched = true;
    notifyListeners();
  } catch (e) {
    debugPrint('Error fetching Child documents: $e');
  }
}

  void filterData(FieldLabel? selectedField, String? selectedEntry) {
    if (selectedField == null || selectedEntry == null || selectedEntry.isEmpty) {
      _filteredInstances = List.from(_wordInstances);
    } else {
      _filteredInstances = _wordInstances.where((word) {
        switch (selectedField) {
          case FieldLabel.child:
            return word.childName == selectedEntry;
          case FieldLabel.word:
            return word.id == selectedEntry;
          case FieldLabel.age:
            return word.childAge.toString() == selectedEntry;
          default:
            return false;
        }
      }).toList();
    }
    notifyListeners();
  }

  void sort<T>(Comparable<T> Function(WordInstance wordTracker) getField, bool ascending) {
    _filteredInstances.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    notifyListeners(); 
  }

  List<WordInstance> getFilteredData() => _filteredInstances;
  List<WordInstance> getAllData() => _wordInstances;

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


class FilterMenu extends StatefulWidget {
  final void Function(FieldLabel? field, String? value) onFilterChanged;
  final List<WordInstance> dataSource;

  const FilterMenu({super.key, required this.onFilterChanged, required this.dataSource});

  @override
  State<FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<FilterMenu> {
  TextEditingController fieldController = TextEditingController();
  TextEditingController entryController = TextEditingController();
  
  FieldLabel? selectedField;
  String selectedEntry = '';
  List<String> suggestions = [];
  String filterMessage = '';

  @override
  void initState() {
    super.initState();
    _updateSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownMenu<FieldLabel>(
                      initialSelection: null,
                      controller: fieldController,
                      requestFocusOnTap: true,
                      label: const Text('Field'),
                      onSelected: (FieldLabel? field) {
                        setState(() {
                          selectedField = field;
                          _updateSuggestions();
                        });
                      },
                      dropdownMenuEntries: FieldLabel.entries,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return suggestions;
                    }
                    return suggestions.where((option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String value) {
                    setState(() {
                      selectedEntry = value;
                      entryController.text = value;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    entryController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Entry',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String value) {
                        selectedEntry = value;
                      },
                    );
                  },
                ),
              ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState((){
                        filterMessage = 'Filtering by ${selectedField?.label} "$selectedEntry"';
                      });
                        widget.onFilterChanged(selectedField, selectedEntry);
                        },
                  child: const Text('Filter'),
                              ),
                  const SizedBox(
                    width: 20
                  ),
                  ElevatedButton(
                onPressed: () {
                    setState((){
                      selectedField = null;
                      fieldController.clear();
                      entryController.clear();
                      filterMessage = '';
                    });
                    widget.onFilterChanged(null, null);
                    },
              child: const Text('Clear Filter'),
            )
                ],
              ),
              if (filterMessage.isNotEmpty)
                Text(filterMessage, style: const TextStyle(fontSize: 16)),
              
            ],
            
          ),
        ),
      );
  }

 void _updateSuggestions() {
  if (selectedField == null) return;

  debugPrint("Updating suggestions for field: ${selectedField?.label}");

  if (widget.dataSource.isEmpty) {
    debugPrint("No data available for suggestions.");
    setState(() => suggestions = []);
    return;
  }

  Set<String> uniqueValues = {};
  switch (selectedField) {
    case FieldLabel.child:
      uniqueValues = widget.dataSource.map((word) => word.childName).where((e) => e.isNotEmpty).toSet();
      break;
    case FieldLabel.word:
      uniqueValues = widget.dataSource.map((word) => word.id).where((e) => e.isNotEmpty).toSet();
      break;
    default:
      uniqueValues = {};
  }

  setState(() {
    suggestions = uniqueValues.toList();
  });

  debugPrint("Suggestions updated: ${suggestions.length} items");
}
}

class WordInstance {
  final String childName;
  final int childAge;
  final String id;
  final String firstUtterance;
  final int videoID;

  WordInstance({required this.childName, required this.childAge, required this.id, required this.firstUtterance, required this.videoID});
}

typedef FieldEntry = DropdownMenuEntry<FieldLabel>;

enum FieldLabel {
  child('Child'),
  age('Age'),
  word('Word');
  //firstUtterance('First Utterance'),
  //videoID('Video ID');

  const FieldLabel(this.label);
  final String label;

  static final List<FieldEntry> entries = UnmodifiableListView<FieldEntry>(
    values.map<FieldEntry>(
      (FieldLabel field) => FieldEntry(value: field, label: field.label,
        style: MenuItemButton.styleFrom(foregroundColor: const Color(0xFF9E1B32)),
      ),
    ),
  );
}


