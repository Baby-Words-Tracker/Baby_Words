import 'package:baby_words_tracker/pages/testing/role_testing.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:baby_words_tracker/util/download_as_csv.dart' as download_csv;

class ResearcherHomePage extends StatefulWidget {
  const ResearcherHomePage({super.key});

  @override
  State<ResearcherHomePage> createState() => _ResearcherHomePageState();
}

class _ResearcherHomePageState extends State<ResearcherHomePage> {
  FieldLabel? selectedField;
  String? selectedEntry;
  List<WordInstance> wordInstances = [];
  final FirestoreDataTableSource _dataSource = FirestoreDataTableSource();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWordTrackers();
  }

  void _fetchWordTrackers() async {
    setState(() => _isLoading = true);
    await _dataSource.fetchData();
    if (!mounted) return;
    final newData = _dataSource.getAllData();

    setState(() {
      wordInstances = newData;
      _isLoading = false;
    });
  }

  void updateFilter(FieldLabel? field, String? entry) {
    setState(() {
      selectedField = field;
      selectedEntry = entry;
      _dataSource.filterData(field, entry);
    });
    debugPrint(
        "Filter updated: Field -> $selectedField, Entry -> $selectedEntry");
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (Provider.of<LocalizationService>(context, listen: false)
            .getLocaleCode() !=
        LanguageCode.en) {
      Provider.of<LocalizationService>(context, listen: false)
          .changeLocale(LanguageCode.en);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage('assets/LECS_mascot.png'),
            ),
            SizedBox(width: 8),
            Expanded(child: Text("WordBuds"))
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
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
          ),
          Consumer<AuthenticationService>(
            builder: (context, authenticationService, config) {
              if (authenticationService.roles.contains(UserRole.admin)) {
                return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () {
                      Navigator.pushNamed(context, RoleTesting.routeName);
                    });
              } else {
                return const SizedBox(
                  width: 5,
                );
              }
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: screenHeight,
              child: Column(children: [
                const Text('Hello, Researcher!',
                    style: TextStyle(
                      color: Color(0xFF9E1B32),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    )),
                FilterMenu(
                    onFilterChanged: updateFilter, dataSource: wordInstances),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : WordTrackerTable(dataSource: _dataSource),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class WordTrackerTable extends StatefulWidget {
  final FirestoreDataTableSource dataSource;

  const WordTrackerTable({super.key, required this.dataSource});

  @override
  State<WordTrackerTable> createState() => _WordTrackerTableState();
}

class _WordTrackerTableState extends State<WordTrackerTable> {
  bool _isAscending = true;
  int _sortColumnIndex = 0;

  void _sort<T>(Comparable<T> Function(WordInstance wordInstance) getField,
      int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      widget.dataSource.sort(getField, ascending);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.dataSource.getFilteredData();
    final dataTable = DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _isAscending,
      columns: [
        DataColumn(
          label: const Text("Child"),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.childName, columnIndex, ascending),
        ),
        DataColumn(
          label: const Text("Age"),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.childAge, columnIndex, ascending),
        ),
        DataColumn(
          label: const Text("Word"),
          onSort: (columnIndex, ascending) =>
              _sort((wordInstance) => wordInstance.id, columnIndex, ascending),
        ),
        DataColumn(
          label: const Text("Part of Speech"),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.partOfSpeech,
              columnIndex,
              ascending),
        ),
        DataColumn(
          label: const Text("First Utterance"),
          numeric: true,
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.firstUtterance,
              columnIndex,
              ascending),
        ),
      ],
      rows: rows
          .map((wordInstance) => DataRow(
                cells: [
                  DataCell(Text(wordInstance.childName)),
                  DataCell(Text(wordInstance.childAge.toString())),
                  DataCell(Text(wordInstance.id)),
                  DataCell(Text(wordInstance.partOfSpeech)),
                  DataCell(Text(wordInstance.firstUtterance)),
                ],
              ))
          .toList(),
    );

    List<List<String>> dataList = dataTable.rows.map((dataRow) {
      return dataRow.cells.map((dataCell) {
        if (dataCell.child is Text) {
          return (dataCell.child as Text).data ?? "";
        } else {
          return "";
        }
      }).toList();
    }).toList();

    List<String> header = [
      'Child',
      'Age',
      'Word',
      'Part of Speech',
      'First Utterance'
    ];

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: dataTable,
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () {
              download_csv.downloadAsCSV(header, dataList);
            },
            child: const Text('Download as CSV'))
      ],
    );
  }
}

class FirestoreDataTableSource extends DataTableSource {
  List<WordInstance> _wordInstances = [];
  List<WordInstance> _filteredInstances = [];

  Future<void> fetchData() async {
    try {
      debugPrint('Querying Firestore...');

      QuerySnapshot childSnapshot =
          await FirebaseFirestore.instance.collection('Child').get();
      List<Future<void>> fetchTasks = [];

      List<WordInstance> tempInstances = [];

      for (var childDoc in childSnapshot.docs) {
        fetchTasks.add(() async {
          try {
            String childID = childDoc.id;
            List<dynamic> childLangs = childDoc['language'];
            DateTime childBirthday =
                (childDoc['birthday'] as Timestamp).toDate();
            int childAge = DateTime.now().year - childBirthday.year;

            if (childBirthday.isAfter(
                DateTime.now().subtract(Duration(days: 365 * childAge)))) {
              childAge--;
            }

            QuerySnapshot wordTrackerSnapshot =
                await childDoc.reference.collection('WordTracker').get();
            List<Future<void>> wordFetchTasks = [];

            for (var wordDoc in wordTrackerSnapshot.docs) {
              wordFetchTasks.add(() async {
                try {
                  DocumentSnapshot posDoc = await FirebaseFirestore.instance
                      .collection('Word')
                      .doc(wordDoc.id)
                      .get();
                  var posData = posDoc['partOfSpeech'];
                  Map<String, String> posMap = Map.from(posData);
                  Map<String, String> partOfSpeechTracker = {};
                  if (childLangs.isEmpty) {
                    partOfSpeechTracker = posMap;
                  }
                  posMap.forEach((langCode, partSpeech) {
                    if (childLangs.contains(langCode)) {
                      partOfSpeechTracker[langCode] = partSpeech;
                    }
                  });
                  tempInstances.add(WordInstance(
                    childName: childID,
                    childAge: childAge,
                    id: wordDoc.id,
                    firstUtterance: wordDoc['firstUtterance'] != null
                        ? (wordDoc['firstUtterance'] as Timestamp)
                            .toDate()
                            .toString()
                        : 'Unknown',
                    partOfSpeech: partOfSpeechTracker.toString(),
                  ));
                } catch (e) {
                  debugPrint('Error fetching Word document ${wordDoc.id}: $e');
                }
              }());
            }
            await Future.wait(wordFetchTasks);
          } catch (e) {
            debugPrint('Error processing Child ${childDoc.id}: $e');
          }
        }());
      }

      await Future.wait(fetchTasks);
      _wordInstances = tempInstances;
      _filteredInstances = List.from(_wordInstances);
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void filterData(FieldLabel? selectedField, String? selectedEntry) {
    if (selectedField == null ||
        selectedEntry == null ||
        selectedEntry.isEmpty) {
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
          case FieldLabel.partofspeech:
            return word.partOfSpeech == selectedEntry;
        }
      }).toList();
    }
  }

  void sort<T>(Comparable<T> Function(WordInstance wordTracker) getField,
      bool ascending) {
    _filteredInstances.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
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

  const FilterMenu(
      {super.key, required this.onFilterChanged, required this.dataSource});

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownMenu<FieldLabel>(
                initialSelection: null,
                controller: fieldController,
                requestFocusOnTap: true,
                label: const Text('Field'),
                onSelected: (FieldLabel? field) {
                  setState(() {
                    selectedField = field;
                    entryController.clear();
                    _updateSuggestions();
                  });
                },
                dropdownMenuEntries: FieldLabel.entries,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Autocomplete<String>(
                  key: ValueKey(selectedField),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return suggestions;
                    }
                    return suggestions.where((option) => option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String value) {
                    setState(() {
                      selectedEntry = value;
                      entryController.text = value;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
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
                setState(() {
                  filterMessage =
                      'Filtering by ${selectedField?.label} "$selectedEntry"';
                });
                widget.onFilterChanged(selectedField, selectedEntry);
              },
              child: const Text('Filter'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
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
        const SizedBox(height: 20),
        if (filterMessage.isNotEmpty)
          Text(filterMessage,
              style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF9E1B32),
                  fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _updateSuggestions() {
    if (selectedField == null) return;

    debugPrint("Updating suggestions for field: ${selectedField?.label}");

    if (widget.dataSource.isEmpty) {
      debugPrint("No data available for suggestions.");
      if (!mounted) return;
      setState(() => suggestions = []);
      return;
    }

    Set<String> uniqueValues = {};
    switch (selectedField) {
      case FieldLabel.child:
        uniqueValues = widget.dataSource
            .map((word) => word.childName)
            .where((e) => e.isNotEmpty)
            .toSet();
        break;
      case FieldLabel.word:
        uniqueValues = widget.dataSource
            .map((word) => word.id)
            .where((e) => e.isNotEmpty)
            .toSet();
      case FieldLabel.partofspeech:
        uniqueValues = widget.dataSource
            .map((word) => word.partOfSpeech)
            .where((e) => e.isNotEmpty)
            .toSet();
        break;
      default:
        uniqueValues = {};
    }

    if (!mounted) return;
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
  final String partOfSpeech;
  final String firstUtterance;

  WordInstance(
      {required this.childName,
      required this.childAge,
      required this.id,
      required this.partOfSpeech,
      required this.firstUtterance});
}

typedef FieldEntry = DropdownMenuEntry<FieldLabel>;

enum FieldLabel {
  child('Child'),
  age('Age'),
  word('Word'),
  partofspeech('Part of Speech');

  const FieldLabel(this.label);
  final String label;

  static final List<FieldEntry> entries = UnmodifiableListView<FieldEntry>(
    values.map<FieldEntry>(
      (FieldLabel field) => FieldEntry(
        value: field,
        label: field.label,
        style:
            MenuItemButton.styleFrom(foregroundColor: const Color(0xFF9E1B32)),
      ),
    ),
  );
}
