import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:baby_words_tracker/util/graph_type.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

final List<GraphType> graphsWithLength = [
  GraphType.newWordsPerDay
]; // List of GraphTypes that have a length parameter, to be expanded when more graph types are added

class StatsPage extends StatefulWidget {
  // Using a stateful widget to allow for changing the graph length and type
  static const routeName = '/stats'; // Route name for navigation

  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  //Default graph setup
  int graphLength = 7;
  GraphType graphType = GraphType
      .newWordsPerDay; // Use the enum GraphType to determine what graph should be displayed

  // Declared as a function to allow child widgets to update the state of the parent widget
  void updateLength(int length) {
    setState(() {
      graphLength = length;
    });
  }

  void updateType(GraphType type) {
    setState(() {
      graphType = type;
    });
  }

  //Initialize Graph Cache
  // If we get a request for a graph with a repeat type, length, and childID, use the one from the cache
  // Saves time and database calls
  Map<(GraphType, int, String), dynamic> graphCache = {};

  //controller for an editable text box, allowing for reading of user input
  final TextEditingController textcontroller1 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Parent? currParent = getCurrentParent(
        context); //This function used to be useful, could be removed now
    if (currParent == null) {
      return const Text("Invalid User Type");
    }

    Child? currChild = context
        .watch<CurrentChildrenService>()
        .getCurrChild(); //Live update the current child based on the one selected in TopBar
    String? currChildId;
    if (currChild != null) {
      currChildId = currChild
          .id; //ChildId is used for database queries for graphs and stats
    }

    if (currChildId == null) {
      return Scaffold(
        // Small error handling page, could be beautified
        appBar: TopBar(
            pageName: context
                .read<LocalizationService>()
                .translate("learning_summary")),
        body: const Text("Please create a child before viewing stats"),
        bottomNavigationBar: CustomBottomBar(StatsPage.routeName),
      );
    }
    return Scaffold(
      appBar: TopBar(
          pageName: context
              .read<LocalizationService>()
              .translate("learning_summary")),
      bottomNavigationBar: CustomBottomBar(StatsPage.routeName),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Consumer2<LocalizationService, WordTrackerDataService>(
                // Using a consumer allows the graphs to update if values are changed, this may be removed at some point, as nothing on this screen currently changes the database, therefore this is not necessary rn
                builder: (context, localizationService, trackerService, child) {
              return Column(
                children: [
                  const SizedBox(height: 25.0),

                  //wordsKnownFeature(context, currChildId!), //Displays text to show how many words the child knows, FIXME: ugly

                  Text(localizationService.translate(graphType.displayName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          // Displays the name of the current graph type as text above the graph
                          fontSize: 30.0,
                          color: Color(0xFF9E1B32),
                          fontWeight: FontWeight.bold)),

                  // Displays the correct graph depending on the current graphType and graphLength, all the other parameters are for the graph constructors within.
                  graphSwitcher(
                      graphType,
                      context.read<ChildDataService>(),
                      context.read<WordDataService>(),
                      context.read<WordTrackerDataService>(),
                      graphLength,
                      graphCache,
                      id: currChildId!),

                  //Allows the user to change the length of those graphs with a time horizon. If graphType is one that does not need length adjustment, does not display.
                  lengthChangeFeature(
                      context, graphType, textcontroller1, updateLength),

                  const SizedBox(
                    height: 5.0,
                  ),

                  //Text(localizationService.translate("learning_summary")),

                  graphTypeSelectDropdown(graphType, updateType),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

//Queries the database and returns the words learned over the past `days` days as time series data
Future<List<List<WordTracker>>> getTimeSeriesNewWords(
    ChildDataService childService,
    WordTrackerDataService trackerService,
    int days,
    {String id = "gz1Qe32xJcF0oRGmhw7f"}) async {
  //for the number of days, grab the amount of words learned
  DateTime now = DateTime.now();
  List<List<WordTracker>> data = List.empty(growable: true);
  ;
  for (var i = 0; i < days; i++) {
    DateTime targetDay = DateTime(now.year, now.month, now.day - i);
    data.add(await trackerService.getWordsFromDate(id, targetDay));
  }
  return data;
}

//Simple switch statement to allow for differen graphs in 1 widget
// Returns: Widget, the graph to be displayed
Widget graphSwitcher(
    GraphType type,
    ChildDataService childService,
    WordDataService wordService,
    WordTrackerDataService trackerService,
    int days,
    Map<(GraphType, int, String), dynamic> cache,
    {String id =
        "gz1Qe32xJcF0oRGmhw7f"}) // switch statement to decide what graph to display
{
  switch (type) {
    case GraphType.newWordsPerDay:
      return newWordsPerDayGraph(childService, trackerService, days, cache,
          id: id);
    case GraphType.wordsByPartOfSpeech:
      return wordsByPartOfSpeechGraph(childService, wordService, cache, id: id);
    default:
      return const Text("Graph Switch Failed.");
  }
}

//Get the number of words of each part of a speech a child has learned
//Integrates with cache to prevent over querying. Data will only update upon reloading the page
//Returns: List<(int, PartOfSpeech)>, a list of tuples containing the number of words and the part of speech
Future<List<(int, PartOfSpeech)>> getPartOfSpeechNumWords(
    ChildDataService childService,
    WordDataService wordService,
    Map<(GraphType, int, String), dynamic> cache,
    {String id = "gz1Qe32xJcF0oRGmhw7f"}) async {
  if (cache.containsKey((GraphType.wordsByPartOfSpeech, -1, id)))
    return cache[(GraphType.wordsByPartOfSpeech, -1, id)];
  Map<PartOfSpeech, int> data = <PartOfSpeech, int>{};
  //for the number of days, grab the amount of words learned
  List<WordTracker> allWordsFromChild = await childService.getAllKnownWords(id);
  for (var tracker in allWordsFromChild) {
    Word currWord = await wordService.getWord(tracker.id ?? "invalid id") ??
        Word(
            word: "Invalid Word",
            languageCodes: List<LanguageCode>.empty(),
            partOfSpeech: {LanguageCode.en: PartOfSpeech.noun},
            definition: {LanguageCode.en: null});

    List<LanguageCode> languages = [
      LanguageCode.en,
      LanguageCode.es
    ]; //possible language for a word to be

    for (LanguageCode language in languages) {
      if (currWord.partOfSpeech[language] != null) {
        data[currWord.partOfSpeech[language]!] =
            (data[currWord.partOfSpeech[language]] ?? 0) + 1;
      } //increment or set to 1 depending on if it already existed
    }
    //data[currWord.partOfSpeech[LanguageCode.en]!] = (data[currWord.partOfSpeech[LanguageCode.en]] ?? 0) + 1; //increment or set to 1 depending on if it already existed
  }
  List<MapEntry<PartOfSpeech, int>> entries = data.entries.toList();
  List<(int, PartOfSpeech)> listData = List.empty(growable: true);
  for (var entry in entries) {
    listData.add((entry.value, entry.key));
  }
  listData.sort((a, b) => a.$2.displayName.compareTo(b.$2.displayName));
  cache[(GraphType.wordsByPartOfSpeech, -1, id)] = listData;
  return listData;
}

//Turns the info about the number of words learned by part of speech into a chart
//Returns: Widget, the graph to be displayed
FutureBuilder<List<(int, PartOfSpeech)>> wordsByPartOfSpeechGraph(
    ChildDataService childService,
    WordDataService wordService,
    Map<(GraphType, int, String), dynamic> cache,
    {String id = "gz1Qe32xJcF0oRGmhw7f"}) {
  return FutureBuilder<List<(int, PartOfSpeech)>>(
      future: getPartOfSpeechNumWords(childService, wordService, cache,
          id: id), // Call async function
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Show loading
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Show error
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Data Available'));
        }

        final partOfSpeechCounts = snapshot.data!;

        return Consumer<LocalizationService>(
            builder: (context, localizationService, child) {
          return Container(
              child: SfCartesianChart(
            backgroundColor: Colors.white,
            plotAreaBackgroundColor: Colors.white,
            palette: const [
              Color(0xFF9E1B32), // Crimson Flame
              Color(0xFF828A8F), // Capstone Gray
              Colors.white, // Victory White
            ],
            primaryXAxis: const CategoryAxis(),
            series: [
              ColumnSeries<(int, PartOfSpeech), String>(
                dataSource: partOfSpeechCounts,
                xValueMapper: ((int, PartOfSpeech) data, _) =>
                    localizationService.translate(data.$2.displayName),
                yValueMapper: ((int, PartOfSpeech) data, _) => data.$1,
                // borderColor: const Color.fromARGB(255, 0, 0, 0),
                // borderWidth: 2, // Capstone Gray
              )
            ],
          ));
        });
      });
}

//Queries the database and returns the number of new words learned over the past `days` days as time series data
//Integrates with cache to prevent over querying. Data will only update upon reloading the page
//Returns: List<(int, DateTime)>, a list of tuples containing the number of words and their associated date
Future<List<(int, DateTime)>> getTimeSeriesNumNewWordsDateRange(
    ChildDataService childService,
    WordTrackerDataService trackerService,
    int days,
    Map<(GraphType, int, String), dynamic> cache,
    {String id = "gz1Qe32xJcF0oRGmhw7f"}) async {
  if (cache.containsKey((GraphType.newWordsPerDay, days, id)))
    return cache[(GraphType.newWordsPerDay, days, id)];
  DateTime now = DateTime.now();
  //for the number of days, grab the amount of words learned
  DateTime startDay = DateTime(now.year, now.month,
      now.day - (days - 1)); //get the day i days before today
  List<WordTracker> wordsFromTargetDateRange =
      await trackerService.getWordsFromDateRange(id, startDay, days);
  var groupedByDay = groupBy(
      wordsFromTargetDateRange,
      (tracker) => DateTime(tracker.firstUtterance.year,
          tracker.firstUtterance.month, tracker.firstUtterance.day));
  Map<DateTime, int> countByDay = groupedByDay.map((day, list) => MapEntry(
      day, list.length)); //count the amount of words learned on each day

  List<(int, DateTime)> data = [];
  // Set<DateTime> existingDates = countByDay.keys.toSet();

  for (DateTime date = startDay;
      date.isBefore(now);
      date = date.add(Duration(days: 1))) {
    date = DateTime(date.year, date.month, date.day, 0);
    data.add((countByDay[date] ?? 0, date));
  }

  cache[(GraphType.newWordsPerDay, days, id)] = data;
  return data;
}

//Turns the info from the past `days` days into a chart showing the amount of words learned per day
//Returns: Widget, the graph to be displayed
FutureBuilder<List<(int, DateTime)>> newWordsPerDayGraph(
    ChildDataService childService,
    WordTrackerDataService trackerService,
    int days,
    Map<(GraphType, int, String), dynamic> cache,
    {String id = "gz1Qe32xJcF0oRGmhw7f"}) {
  return FutureBuilder<List<(int, DateTime)>>(
      future: getTimeSeriesNumNewWordsDateRange(
          childService, trackerService, days, cache,
          id: id), // Call async function
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Show loading
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Show error
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Data Available'));
        }

        final timeSeriesData = snapshot.data!;

        return Container(
            child: SfCartesianChart(
          backgroundColor: Colors.white,
          plotAreaBackgroundColor: Colors.white,
          palette: const [
            Color(0xFF9E1B32), // Crimson Flame
            Color(0xFF828A8F), // Capstone Gray
            Colors.white, // Victory White
          ],
          primaryXAxis: const CategoryAxis(),
          series: [
            ColumnSeries<(int, DateTime), String>(
              dataSource: timeSeriesData
                  .toList(), // use the first 10 elements for the chart
              //TODO: change this to use DD/MM when locale is es
              xValueMapper: ((int, DateTime) data, _) =>
                  "${data.$2.month.toString().padLeft(2, '0')}/${data.$2.day.toString().padLeft(2, '0')}", //messed up one liner to convert to MM/DD format
              yValueMapper: ((int, DateTime) data, _) => data.$1,
              // borderColor: const Color.fromARGB(255, 0, 0, 0),
              // borderWidth: 2, // Capstone Gray
            )
          ],
        ));
      });
}

//Allows the user to change the length of the graph, if the graph type allows for it. If not, does not display anything
//Uses function passed in from parent to update the length of the graph
//Returns: Widget, the text field and button to change the length of the graph
Widget lengthChangeFeature(
    BuildContext context,
    GraphType type,
    TextEditingController inputController,
    void Function(int length) changeParentLength) {
  if (!graphsWithLength.contains(type)) return const SizedBox();
  return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
    return Column(
      children: [
        TextField(
          controller: inputController,
          keyboardType: TextInputType.number, // Numeric keyboard
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly // Only allows digits (0-9)
          ],
          decoration: InputDecoration(
            //border: OutlineInputBorder(),
            hintText: localizationService
                .translate("over_num_days"), //'Over how many days...',
            hintStyle: const TextStyle(color: Colors.white),
            filled: true,
            fillColor: const Color(0xFF9E1B32),
          ),
        ),
        const SizedBox(
          height: 5.0,
        ),
        Center(
            child: OutlinedButton(
          onPressed: () {
            if (inputController.text != "") //update the length of time
            {
              changeParentLength(int.parse(inputController.text));
            }
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
              style: TextStyle(fontSize: 18)),
        )),
      ],
    );
  });
}

//Drop down menu to select the type of graph to display
// Uses the GraphType enum to determine the type of graph to display
// Returns: Widget, the dropdown menu to select the graph type
// Uses function passed in from parent to update the graph type
Consumer graphTypeSelectDropdown(
    GraphType currType, void Function(GraphType type) changeParentGraphType) {
  List<String> options = List.empty(growable: true);
  for (var graphType in GraphType.values) {
    //generate a list of all the string names of the graph types
    options.add(graphType.optionName);
  }
  return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
    return DropdownButton<String>(
      value: currType.optionName,
      hint: Text(localizationService.translate("select_option")),
      icon: const Icon(Icons.arrow_downward),
      onChanged: (String? newValue) {
        changeParentGraphType(
            GraphTypeExtension.fromOptionName(newValue ?? ""));
      },
      items: options.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(localizationService.translate(value),
              style: const TextStyle(
                  fontSize: 18.0,
                  color: Color(0xFF9E1B32),
                  fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  });
}

//Displays the number of words the child knows, using the ChildDataService to query the database
// Returns a FutureBuilder that builds a text widget declaring the number of words
FutureBuilder<int> wordsKnownFeature(BuildContext context, String currChildId) {
  return FutureBuilder<int>(
      future: context.read<ChildDataService>().getNumWords(currChildId),
      builder: (context, numWords) {
        return Text("Your child knows ${numWords.data} words!");
      });
}

// ---------------------
// -- TESTING SECTION --
// ---------------------

Future<void>
    addThisManyDaysWorthOfExampleDataToTestChildInALinearIncreasingFormat(int n,
        WordTrackerDataService trackerService) //testing function FIXME:remove
async {
  DateTime now = DateTime.now();
  for (var i = 0; i < n; i++) {
    DateTime targetDay = DateTime(now.year, now.month,
        now.day - (n - i - 1)); //get the day i days before today
    for (var j = 0; j < i + 1; j++) {
      trackerService.createWordTracker("gz1Qe32xJcF0oRGmhw7f",
          "test${i.toString()}${j.toString()}", targetDay);
    }
  }
}


// below this is the testing word adding functionality


