import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:baby_words_tracker/util/graph_type.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/util/time_utils.dart';

import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';

import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

final List<GraphType> graphsWithLength = [GraphType.newWordsPerDay]; // List of GraphTypes that have a length parameter

class StatsPage extends StatefulWidget {

  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  //Default graph setup
  int graphLength = 7;
  GraphType graphType = GraphType.newWordsPerDay; // Use the enum GraphType to determine what graph should be displayed
  
  

  //Allow children to change graph state
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

  //Somehow determine this via child switcher, also should be reset upon switching user


  //Initialize Graph Cache
  // If we get a request for a graph with a repeat type, length, and childID, use the one from the cache
  Map<(GraphType, int, String), dynamic> graphCache = {};

  //controllers for two editable text boxes, allowing for reading of user inputs
  final TextEditingController textcontroller1 = TextEditingController(); 
  final TextEditingController textcontroller2 = TextEditingController(); 

  @override
  Widget build(BuildContext context) { 
    //Get the current Parent
    Parent? currParent = getCurrentParent(context);
    if (currParent == null)
    {
      return const Text("Invalid User Type");
    }

    Child? currChild = context.watch<CurrentChildrenService>().getCurrChild();
    String? currChildId;
    if (currChild != null) {
      currChildId = currChild.id;
    }

    if (currChildId == null)
    {
      return Scaffold(
        appBar: TopBar(pageName: context.read<LocalizationService>().translate("learning_summary")),
        body: const Text("Please create a child before viewing stats"),
        bottomNavigationBar: bottomBar(context, "stats"),
      );
    } 
    return Scaffold(
      appBar: TopBar(pageName: context.read<LocalizationService>().translate("learning_summary")),
      bottomNavigationBar: bottomBar(context, "stats"),
      body: Center(
        child: Consumer2<LocalizationService, WordTrackerDataService>( // Using a consumer allows the graphs to update if values are changed, this may be removed at some point, as nothing on this screen currently changes the database, therefore this is not necessary rn
          builder: (context, localizationService, trackerService, child) {
            return Column(
              children: [
                
                Text(localizationService.translate(graphHeader(graphType, graphLength)), style: const TextStyle(
                      fontSize: 30.0,
                      color: Color(0xFF9E1B32),
                      fontWeight: FontWeight.bold)),
                
                //Displays the correct graph depending on the current graphType and graphLength, all the other parameters are for the graph constructors within.
                graphSwitcher(graphType, context.read<ChildDataService>(), context.read<WordDataService>(), context.read<WordTrackerDataService>(), graphLength, graphCache, id: currChildId!),

                //Allows the user to change the length of those graphs with a time horizon. If graphType is one that does not need length adjustment, does not display.
                lengthChangeFeature(context, graphType, textcontroller1, updateLength),

                Text(localizationService.translate("learning_summary")),

                graphTypeSelectDropdown(graphType, updateType),
              ],
            );
          }
        ),
      ),
    );
  }
}

//Queries the database and returns the words learned over the past `days` days as time series data
Future<List<List<WordTracker>>> getTimeSeriesNewWords(ChildDataService childService, WordTrackerDataService trackerService, int days, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
  //for the number of days, grab the amount of words learned
  DateTime now = DateTime.now();
  List<List<WordTracker>> data = List.empty(growable: true);;
  for (var i = 0; i < days; i++) {
    DateTime targetDay = DateTime(now.year, now.month, now.day - i);
    data.add(await trackerService.getWordsFromDate(id, targetDay));
  }
  return data;
}

//Displays the correct graph title based on the graph parameters
String graphHeader(GraphType type, int days)
{
  /* if (graphsWithLength.contains(type))
  {
    return "${type.displayName} for the Past ${numDaysToAmountOfTimeName(days)}:"; //how do we feel about removing this???
  }
  else {
    return type.displayName;
  } */
 return type.displayName;
}

//Simple switch statement to allow for differen graphs in 1 widget
Widget graphSwitcher(GraphType type, ChildDataService childService, WordDataService wordService, WordTrackerDataService trackerService, int days,   Map<(GraphType, int, String), dynamic> cache, {String id = "gz1Qe32xJcF0oRGmhw7f"}) // switch statement to decide what graph to display
{
  switch (type) {
    case GraphType.newWordsPerDay:
      return newWordsPerDayGraph(childService, trackerService, days, cache, id: id);
    case GraphType.wordsByPartOfSpeech:
      return wordsByPartOfSpeechGraph(childService, wordService, cache, id: id);
    default:
      return const Text("Graph Switch Failed.");
  }
}

//Get the number of words of each part of a speech a child has learned
//Integrates with cache to prevent over querying. Data will only update upon reloading the page
Future<List<(int, PartOfSpeech)>> getPartOfSpeechNumWords(ChildDataService childService, WordDataService wordService,  Map<(GraphType, int, String), dynamic> cache, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
  if (cache.containsKey((GraphType.wordsByPartOfSpeech, -1, id))) return cache[(GraphType.wordsByPartOfSpeech, -1, id)];
  Map<PartOfSpeech, int> data = <PartOfSpeech,int>{};
  //for the number of days, grab the amount of words learned
  List<WordTracker> allWordsFromChild = await childService.getAllKnownWords(id);
  for (var tracker in allWordsFromChild)
  {
    Word currWord = await wordService.getWord(tracker.id ?? "invalid id") ?? Word(word: "Invalid Word", languageCodes: List<LanguageCode>.empty(), partOfSpeech: {LanguageCode.en: PartOfSpeech.noun},  definition: {LanguageCode.en : null});
    
    List<LanguageCode> languages = [LanguageCode.en, LanguageCode.es]; //possible language for a word to be

    for (LanguageCode language in  languages) {
      if (currWord.partOfSpeech[language] != null) {
        data[currWord.partOfSpeech[language]!] = (data[currWord.partOfSpeech[language]] ?? 0) + 1;
      } //increment or set to 1 depending on if it already existed
    }
    //data[currWord.partOfSpeech[LanguageCode.en]!] = (data[currWord.partOfSpeech[LanguageCode.en]] ?? 0) + 1; //increment or set to 1 depending on if it already existed
  }
  List<MapEntry<PartOfSpeech, int>> entries = data.entries.toList();
  List<(int, PartOfSpeech)> listData = List.empty(growable: true);
  for (var entry in entries)
  {
    listData.add((entry.value, entry.key));
  }
  listData.sort((a, b) => a.$2.displayName.compareTo(b.$2.displayName));
  cache[(GraphType.wordsByPartOfSpeech, -1, id)] = listData;
  return listData;
}

//Turns the info from the past `days` days into a chart showing the amount of words learned per day
FutureBuilder<List<(int, PartOfSpeech)>> wordsByPartOfSpeechGraph(ChildDataService childService, WordDataService wordService,   Map<(GraphType, int, String), dynamic> cache, {String id = "gz1Qe32xJcF0oRGmhw7f"}){
  return FutureBuilder<List<(int, PartOfSpeech)>>(
    future: getPartOfSpeechNumWords(childService, wordService, cache, id: id), // Call async function
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator()); // Show loading
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
            Colors.white,      // Victory White
          ],
          primaryXAxis: const CategoryAxis(),
          series: [
            ColumnSeries<(int,PartOfSpeech), String>(
                dataSource: partOfSpeechCounts,
                xValueMapper: ((int,PartOfSpeech) data, _) => localizationService.translate(data.$2.displayName),
                yValueMapper: ((int,PartOfSpeech) data, _) => data.$1,
                // borderColor: const Color.fromARGB(255, 0, 0, 0),
                // borderWidth: 2, // Capstone Gray
              )
          ],
        )
      );
    }
  );
}
);
}

//Queries the database and returns the number of new words learned over the past `days` days as time series data
Future<List<(int, DateTime)>> getTimeSeriesNumNewWordsDateRange(ChildDataService childService, WordTrackerDataService trackerService, int days,   Map<(GraphType, int, String), dynamic> cache, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
    if (cache.containsKey((GraphType.newWordsPerDay, days, id))) return cache[(GraphType.newWordsPerDay, days, id)];
  DateTime now = DateTime.now();
  //for the number of days, grab the amount of words learned
  DateTime startDay = DateTime(now.year, now.month, now.day - (days - 1)); //get the day i days before today
  List<WordTracker> wordsFromTargetDateRange = await trackerService.getWordsFromDateRange(id, startDay, days);
  var groupedByDay = groupBy(wordsFromTargetDateRange, (tracker) => DateTime(tracker.firstUtterance.year, tracker.firstUtterance.month, tracker.firstUtterance.day));
  Map<DateTime, int> countByDay = groupedByDay.map((day, list) => MapEntry(day, list.length)); //count the amount of words learned on each day
  
  List<(int, DateTime)> data = [];
    // Set<DateTime> existingDates = countByDay.keys.toSet();

  for (DateTime date = startDay; date.isBefore(now); date = date.add(Duration(days: 1))) {
    date = DateTime(date.year, date.month, date.day, 0);
    data.add((countByDay[date] ?? 0, date));
  }

  cache[(GraphType.newWordsPerDay, days, id)] = data;
  return data;
}

//Turns the info from the past `days` days into a chart showing the amount of words learned per day
FutureBuilder<List<(int, DateTime)>> newWordsPerDayGraph(ChildDataService childService, WordTrackerDataService trackerService, int days,   Map<(GraphType, int, String), dynamic> cache, {String id = "gz1Qe32xJcF0oRGmhw7f"}){
  return FutureBuilder<List<(int, DateTime)>>(
    future: getTimeSeriesNumNewWordsDateRange(childService, trackerService, days, cache, id: id), // Call async function
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator()); // Show loading
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
            Colors.white,      // Victory White
          ],
          primaryXAxis: const CategoryAxis(),
          series: [
            ColumnSeries<(int,DateTime), String>(
                dataSource: timeSeriesData.toList(),// use the first 10 elements for the chart
                //TODO: change this to use DD/MM when locale is es
                xValueMapper: ((int,DateTime) data, _) => "${data.$2.month.toString().padLeft(2, '0')}/${data.$2.day.toString().padLeft(2, '0')}", //messed up one liner to convert to MM/DD format
                yValueMapper: ((int,DateTime) data, _) => data.$1,
                // borderColor: const Color.fromARGB(255, 0, 0, 0),
                // borderWidth: 2, // Capstone Gray
              )
          ],
        )
      );
    }
  );
}


Widget lengthChangeFeature(BuildContext context, GraphType type, TextEditingController inputController, void Function(int length) changeParentLength){
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
          hintText: localizationService.translate("over_num_days"),//'Over how many days...',
          hintStyle: const TextStyle(color: Colors.white),
          filled: true,  
          fillColor: const Color(0xFF9E1B32),
        ),
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
          child: Text(localizationService.translate("submit"), style: TextStyle(fontSize: 18)),
        )
      ),
    ],
  );}
  );
}


Consumer graphTypeSelectDropdown(GraphType currType, void Function(GraphType type) changeParentGraphType)
{
  List<String> options = List.empty(growable: true);
  for (var graphType in GraphType.values) { //generate a list of all the string names of the graph types
    options.add(graphType.optionName);
  }
  return Consumer<LocalizationService>(
    builder: (context, localizationService, child) {
    return DropdownButton<String>(
    value: currType.optionName,
    hint: Text(localizationService.translate("select_option")),
    icon: const Icon(Icons.arrow_downward),
    onChanged: (String? newValue) {
        changeParentGraphType(GraphTypeExtension.fromOptionName(newValue ?? ""));
    },
    items: options.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(localizationService.translate(value)),
      );
    }).toList(),
  );
  }
  );
}




// ---------------------
// -- TESTING SECTION --
// ---------------------




Future<void> addThisManyDaysWorthOfExampleDataToTestChildInALinearIncreasingFormat(int n, WordTrackerDataService trackerService) //testing function FIXME:remove
async {
  DateTime now = DateTime.now();
  for (var i = 0; i < n; i++) {
    DateTime targetDay = DateTime(now.year, now.month, now.day - (n - i - 1)); //get the day i days before today
    for (var j = 0; j < i + 1; j++) {
      trackerService.createWordTracker("gz1Qe32xJcF0oRGmhw7f", "test${i.toString()}${j.toString()}", targetDay);
    }
  }
}


// below this is the testing word adding functionality


