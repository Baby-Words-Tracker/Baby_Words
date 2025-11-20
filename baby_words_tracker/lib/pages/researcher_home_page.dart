import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/admin_page.dart';
import 'package:baby_words_tracker/util/download_as_csv.dart' as download_csv;
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

// final FirebaseFirestore testDb = FirebaseFirestore.instance;
// void connectEmulator() {
//   testDb.useFirestoreEmulator('localhost', 8080);
// }

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

    final theme = Theme.of(context);
    final localizationService = context.watch<LocalizationService>();
    final Color barColor = theme.colorScheme.secondaryContainer;
    final Color onBarColor = theme.colorScheme.onSecondaryContainer;
    final brandTranslation = localizationService.translate('word_buds').trim();
    final String brandLabel =
        brandTranslation.isEmpty ? 'WordBuds' : brandTranslation;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: barColor,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brandLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onBarColor.withOpacity(0.85),
                        ) ??
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onBarColor.withOpacity(0.85),
                        ),
                  ),
                ],
              ),
            ),
            // CircleAvatar(
            //   radius: 24,
            //   child: Image.asset(
            //     'assets/lecs_mascot_64x64.png',
            //     fit: BoxFit.contain,
            //     width: 38,
            //     height: 38,
            //   ),
            // ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/lecs_mascot_64x64.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),           
            //const SizedBox(width: 8),
            //const Expanded(child: Text("WordBuds"))
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
              )
              )
          ],
        )),
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
                      Navigator.pushNamed(context, AdminPage.routeName);
                    });
              } else {
                return const SizedBox(
                  width: 5,
                );
              }
            },
          ),
        ],
        //automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: screenHeight,
              child: Column(children: [
                 Text('Hello, Researcher!',
                    // style: TextStyle(
                    //   color: Color(0xFF9E1B32),
                    //   fontSize: 24,
                    //   fontWeight: FontWeight.bold,
                    style: theme.textTheme.titleLarge?.copyWith(
                      //fontWeight: FontWeight.w700,
                    ),
                    ),
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

class WordDataSource extends DataTableSource {
 
  final List<WordInstance> filteredInstances;
  final BuildContext context;

  WordDataSource(this.filteredInstances, this.context);
  

  @override
  DataRow getRow(int index) {
    final theme = Theme.of(context);
    if (index >= filteredInstances.length) return null!;
    final wordInstance = filteredInstances[index];
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>(
            (_) => index.isEven ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHigh,
          ),
      cells: [
      DataCell(Text(wordInstance.childName)),
      DataCell(Text(wordInstance.childAge.toString())),
      DataCell(Text(wordInstance.id)),
      DataCell(Text(wordInstance.partOfSpeech)),
      DataCell(Text(wordInstance.firstUtterance)),
      DataCell(Text(wordInstance.ageOfUtterance.toString())),
    ]);
  }

  @override
  int get rowCount => filteredInstances.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
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
    final theme = Theme.of(context);
    final dataTable = PaginatedDataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _isAscending,
      columns: [
        DataColumn(
          label: Text("Child", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.childName, columnIndex, ascending),
        ),
        DataColumn(
          label: Text("Current Age", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.childAge, columnIndex, ascending),
        ),
        DataColumn(
          label: Text("Word", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) =>
              _sort((wordInstance) => wordInstance.id, columnIndex, ascending),
        ),
        DataColumn(
          label: Text("Part of Speech", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.partOfSpeech,
              columnIndex,
              ascending),
        ),
        DataColumn(
          label: Text("First Utterance", style: theme.textTheme.titleMedium),
          numeric: true,
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.firstUtterance,
              columnIndex,
              ascending),
        ),
         DataColumn(
          label: Text("Age At First Utterance", style: theme.textTheme.titleMedium),
          numeric: true,
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.ageOfUtterance,
              columnIndex,
              ascending),
        ),
      ],
      source: WordDataSource(rows, context),
      rowsPerPage: 10,
      columnSpacing: 20,
      showCheckboxColumn: false,
      );

    final dataTable2 = DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _isAscending,
      columns: [
        DataColumn(
          label: Text("Child", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.childName, columnIndex, ascending),
        ),
        DataColumn(
          label: Text("Current Age", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.childAge, columnIndex, ascending),
        ),
        DataColumn(
          label: Text("Word", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) =>
              _sort((wordInstance) => wordInstance.id, columnIndex, ascending),
        ),
        DataColumn(
          label: Text("Part of Speech", style: theme.textTheme.titleMedium),
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.partOfSpeech,
              columnIndex,
              ascending),
        ),
        DataColumn(
          label: Text("First Utterance", style: theme.textTheme.titleMedium),
          numeric: true,
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.firstUtterance,
              columnIndex,
              ascending),
        ),
         DataColumn(
          label: Text("Age At First Utterance", style: theme.textTheme.titleMedium),
          numeric: true,
          onSort: (columnIndex, ascending) => _sort(
              (wordInstance) => wordInstance.ageOfUtterance,
              columnIndex,
              ascending),
        ),
      ],
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;

        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>(
            (_) => index.isEven ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHigh,
          ),
          cells: [
            DataCell(Text(row.childName, style: theme.textTheme.titleSmall)),
            DataCell(Text(row.childAge.toString(), style: theme.textTheme.titleSmall)),
            DataCell(Text(row.id, style: theme.textTheme.titleSmall)),
            DataCell(Text(row.partOfSpeech, style: theme.textTheme.titleSmall)),
            DataCell(Text(row.firstUtterance, style: theme.textTheme.titleSmall)),
            DataCell(Text(row.ageOfUtterance.toString(), style: theme.textTheme.titleSmall)),
          ],
        );
      }).toList(),
          // .map((wordInstance) => DataRow(
          //       cells: [
          //         DataCell(Text(wordInstance.childName)),
          //         DataCell(Text(wordInstance.childAge.toString())),
          //         DataCell(Text(wordInstance.id)),
          //         DataCell(Text(wordInstance.partOfSpeech)),
          //         DataCell(Text(wordInstance.firstUtterance)),
          //       ],
          //     ))
          // .toList(),
    );



    List<List<String>> dataList = dataTable2.rows.map((dataRow) {
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

    return Center(
      child: Column(
        children: [
          Card(child:
          SizedBox(
            width: 1100,
            height: 350,
            child:
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(child: dataTable)
            )
          )
          ),
          SizedBox(
          height: 10,
        ),
         SizedBox(
              child: FilledButton(
            onPressed: () {
              download_csv.downloadAsCSV(header, dataList);
            },
            child: Text('Download as CSV',
          )))
        ]
      ),
    );

    // return Center(
    //   child: Column(
    //   children: [
    //     Card( 
    //       child:
    //     SizedBox(
    //       height: 350,
    //       width: 1500,
    //       child: dataTable,
    //       // child: SingleChildScrollView(
    //       //   scrollDirection: Axis.horizontal,
    //       //   child: SingleChildScrollView(
    //       //     child: dataTable2,
    //       //   ),
    //       // ),
    //     ),),
    //     const SizedBox(
    //       height: 10,
    //     ),
    //      SizedBox(
    //           child: FilledButton(
    //         onPressed: () {
    //           download_csv.downloadAsCSV(header, dataList);
    //         },
    //         child: Text('Download as CSV',
    //       )))
    //   ],
    // ));
  }
}


enum Filter {
  child,
  word,
  age,
  partofspeech,
}

Filter? getFilterFromField(FieldLabel ? field){
        if (field == null) return null;
        switch (field){
          case FieldLabel.child:
            return Filter.child;
          case FieldLabel.word:
            return Filter.word;
          case FieldLabel.age:
            return Filter.age;
          case FieldLabel.partofspeech:
            return Filter.partofspeech;
        }
      }

Query baseQueryBuilder({
  required Filter? activeFilter,
  String? filterValue,
}){
  if (activeFilter == null || filterValue == null || filterValue.isEmpty) {
      return FirebaseFirestore.instance.collection('Child');
  }

  return FirebaseFirestore.instance.collection("Child");
}
class FirestoreDataTableSource extends DataTableSource {
  List<WordInstance> _wordInstances = [];
  List<WordInstance> _filteredInstances = [];

  Future<void> fetchData({Filter? activeFilter, String? filterValue}) async {
    try {
      debugPrint('Querying Firestore...');

      // QuerySnapshot childSnapshot =
      //     await FirebaseFirestore.instance.collection('Child').get();
      QuerySnapshot childSnapshot =
        await baseQueryBuilder(
          activeFilter: activeFilter, 
          filterValue: filterValue
        ).get();
      List<Future<void>> fetchTasks = [];

      List<WordInstance> tempInstances = [];
      for (var childDoc in childSnapshot.docs) {
        fetchTasks.add(() async {
          try {
            String childID = childDoc.id;
            List<dynamic> childLangs = childDoc['language'];
            DateTime childBirthday =
                (childDoc['birthday'] as Timestamp).toDate();
            //int childAgeYear = DateTime.now().year - childBirthday.year;
            int years = DateTime.now().year - childBirthday.year;
            int months = DateTime.now().month - childBirthday.month;

            if (childBirthday.isAfter(
                DateTime.now().subtract(Duration(days: 365 * years)))) {
              years--;
            }
            if (DateTime.now().day < childBirthday.day){
              months = months - 1;
            }
            
            int childAgeMonths = years * 12 + months;

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

                  var posData = posDoc['languageDetails']; 
                  Map<String, Map<String, dynamic>> posMap = Map<String, Map<String, dynamic>>.from(posData);

                  Map<String, String> partOfSpeechTracker = {};

                  if (childLangs.isEmpty) {
                    posMap.forEach((langCode, nestedMap) {
                      partOfSpeechTracker[langCode] = nestedMap['primaryPartOfSpeech']; 
                    });
                  } else {
                    posMap.forEach((langCode, nestedMap) {
                      if (childLangs.contains(langCode)) {
                        partOfSpeechTracker[langCode] = nestedMap['primaryPartOfSpeech'];
                      }
                    });
                  }

                DateTime utteranceAge = (wordDoc['firstUtterance'] as Timestamp).toDate();
                int utteranceDif = (utteranceAge.year - childBirthday.year) * 12 + (utteranceAge.month - childBirthday.month);
                if (utteranceAge.day < childBirthday.day){
                  utteranceDif -= 1;
                }

                  tempInstances.add(WordInstance(
                    childName: childID,
                    childAge: childAgeMonths,
                    id: wordDoc.id,
                    firstUtterance: wordDoc['firstUtterance'] != null
                        ? (wordDoc['firstUtterance'] as Timestamp)
                            .toDate()
                            .toString()
                        : 'Unknown',
                    ageOfUtterance: utteranceDif,
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
    final activeFilter = getFilterFromField(selectedField);
    if (selectedField == null ||
        selectedEntry == null ||
        selectedEntry.isEmpty ||
        activeFilter == null) {
      _filteredInstances = List.from(_wordInstances);
    } else {
      _filteredInstances = _wordInstances.where((word) {
        switch (activeFilter) {
          case Filter.child:
            return word.childName == selectedEntry;
          case Filter.word:
            return word.id == selectedEntry;
          case Filter.age:
            return word.childAge.toString() == selectedEntry;
          case Filter.partofspeech:
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
      DataCell(Text(wordInstance.ageOfUtterance.toString())),
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
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outlineVariant.withOpacity(0.6);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: outlineColor),
    );
        final focusedBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                ),
                child:
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
                  ),),
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
                      decoration:  InputDecoration(
                        labelText: 'Entry',
                        border: baseBorder,
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
            SizedBox(
              child: FilledButton(
              onPressed: () {
                setState(() {
                  filterMessage =
                      'Filtering by ${selectedField?.label} "$selectedEntry"';
                });
                widget.onFilterChanged(selectedField, selectedEntry);
              },
              child: const Text('Filter'),
            )),
            const SizedBox(width: 20),
             SizedBox(
              child: FilledButton(
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
            ))
          ],
        ),
        const SizedBox(height: 20),
        if (filterMessage.isNotEmpty)
          Text(filterMessage,
              style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF9E1B32),
                  fontWeight: FontWeight.bold)),
      SizedBox(child: Text("(Ages are displayed in months)")),
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
  final int ageOfUtterance;

  WordInstance(
      {required this.childName,
      required this.childAge,
      required this.id,
      required this.partOfSpeech,
      required this.firstUtterance,
      required this.ageOfUtterance});
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
