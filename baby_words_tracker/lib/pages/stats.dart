import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/util/graph_type.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:flutter/src/widgets/framework.dart';


class StatsPage extends StatefulWidget {
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  //Default graph setup
  int graphLength = 7;
  GraphType graphType = GraphType.newWordsPerDay;

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

  @override
  final TextEditingController textcontroller1 = TextEditingController(); 
 // Controller
  final TextEditingController textcontroller2 = TextEditingController(); 
 // Controller
  Widget build(BuildContext context) {   
    return Scaffold(
      appBar: AppBar(title: const Text("Learning Summary")),
      body: Center(
        child: Consumer<WordTrackerDataService>(
          builder: (context, trackerService, child) {
            return Column(
              children: [
                Text("Words Learned Per Day for the Past ${numDaysToAmountOfTimeName(graphLength)}:"),

                chartFromTimeSeriesNumNewWords(context.read<ChildDataService>(), trackerService, graphLength),

                lengthChangeFeature(context, textcontroller1, updateLength),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to the previous page
                  },
                  child: const Text("Go Back"),
                ),
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

//Queries the database and returns the number of new words learned over the past `days` days as time series data
Future<List<(int, DateTime)>> getTimeSeriesNumNewWords(ChildDataService childService, WordTrackerDataService trackerService, int days, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
  
  DateTime now = DateTime.now();
  List<(int, DateTime)> data = List.empty(growable: true);
  //for the number of days, grab the amount of words learned
  for (var i = 0; i < days; i++) {
    DateTime targetDay = DateTime(now.year, now.month, now.day - (days - i - 1)); //get the day i days before today
    List<WordTracker> wordsFromTargetDay = await trackerService.getWordsFromDate(id, targetDay);
    int numOnTargetDay = wordsFromTargetDay.length; //count the amount of words learned that day
    data.add((numOnTargetDay, targetDay)); //add the tuple of that info to the list
  }
  return data;
}

//Turns the info from the past `days` days into a chart showing the amount of words learned per day
FutureBuilder<List<(int, DateTime)>> chartFromTimeSeriesNumNewWords(ChildDataService childService, WordTrackerDataService trackerService, int days, {String id = "gz1Qe32xJcF0oRGmhw7f"}){
  return FutureBuilder<List<(int, DateTime)>>(
    future: getTimeSeriesNumNewWords(childService, trackerService, days, id: id), // Call async function
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

//testing child id: gz1Qe32xJcF0oRGmhw7f
Future<void> addWordToChild(String word, ChildDataService childService, WordDataService wordService, WordTrackerDataService trackerService, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
  if (await childService.getChild(id) == null)
  {
    return;
  }
  //FIXME: implement language, part of speech, defn, spellcheck
  /*Word wordObject =*/ await wordService.createWord(word, [LanguageCode.en], PartOfSpeech.noun, "testWord");
  trackerService.createWordTracker(id, word, DateTime.now());
}


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
Column wordAddingFeature(BuildContext context, TextEditingController wordTextController, TextEditingController idController, WordTrackerDataService trackerService){
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
            if (idController.text != "") //add the word to the child with the id, or the default testing child if no input
            {
              addWordToChild(wordTextController.text, context.read<ChildDataService>(), context.read<WordDataService>(),  trackerService, id: idController.text);
            } else {
              addWordToChild(wordTextController.text, context.read<ChildDataService>(), context.read<WordDataService>(),  trackerService);
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
        )
      ),
    ],
  );
}

Column lengthChangeFeature(BuildContext context, TextEditingController inputController, void Function(int length) changeParentLength){
  return Column(
    children: [
      TextField(
        controller: inputController,
        keyboardType: TextInputType.number, // Numeric keyboard
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly // Only allows digits (0-9)
        ],
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'Over how many days...',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,  
          fillColor: Color(0xFF9E1B32),
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
          child: const Text('Submit', style: TextStyle(fontSize: 18)),
        )
      ),
    ],
  );
}


DropdownButton<String> graphTypeSelectDropdown(GraphType currType, void Function(GraphType type) changeParentGraphType)
{
  List<String> options = List.empty(growable: true);
  for (var graphType in GraphType.values) { //generate a list of all the string names of the graph types
    options.add(graphType.displayName);
  }
  return DropdownButton<String>(
    value: currType.displayName,
    hint: const Text('Select an option'),
    icon: Icon(Icons.arrow_downward),
    onChanged: (String? newValue) {
        changeParentGraphType(GraphTypeExtension.fromString(newValue ?? ""));
    },
    items: options.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList(),
  );
}
