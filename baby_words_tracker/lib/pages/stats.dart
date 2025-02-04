import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/word.dart';


class StatsPage extends StatelessWidget {
  @override
  final TextEditingController _controller = TextEditingController(); // Controller
  Widget build(BuildContext context) {
    //FIXME: dependency inject these (obviously)
    ParentDataService parentService = ParentDataService();
    ChildDataService childService = ChildDataService();
    WordDataService wordService = WordDataService();
    WordTrackerDataService trackerService = WordTrackerDataService();
    

    return Scaffold(
      appBar: AppBar(title: Text("Second Page")),
      body: Center(
        child: Column(
          children: [
             FutureBuilder<List<List<dynamic>>>(
              future: processCSV(), // Call async function
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // Show loading
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); // Show error
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No Data Available'));
                }

                final csvData = snapshot.data!;
                print(csvData);
                for (var item in csvData.take(5)) { // Print first 5 elements
                  print("X: ${item[0]} (Type: ${item[0].runtimeType}), Y: ${item[1]} (Type: ${item[1].runtimeType})");
                }
                return Container(
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: [
                      LineSeries<List<dynamic>, String>(
                          dataSource: csvData.take(10).toList(),
                          xValueMapper: (List<dynamic> data, _) => data[0].toString(), //_ indicates an unused parameter in Dart
                          yValueMapper: (List<dynamic> data, _) => int.tryParse(data[1].toString()) ?? 0
                        )
                    ],
                  )
                );
              }
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     print(createExampleParentChild(parentService, childService));
            //   },
            //   child: Text("Add Example Parent and Child (please only press once lmao)"),
            // ),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                //border: OutlineInputBorder(),
                hintText: 'Enter word',
                hintStyle: TextStyle(color: Colors.white),
                filled: true,  
                fillColor: Color(0xFF9E1B32),
              ),
            ),
            Center(
              //submit button currently doesn't do anything
              child: OutlinedButton(
                onPressed: () {
                  addWordToChild(_controller.text, childService, wordService, trackerService);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF828A8F), 
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the previous page
              },
              child: Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}


Future<List<List<dynamic>>> processCSV()
async {
  //handle data, convert into readable list
  // Load the CSV file from assets
  final csvString = await rootBundle.loadString('assets/data.csv');

  // Parse the CSV
  final csvTable = const CsvToListConverter().convert(csvString);

  // Print the content
  print(csvTable);
  return csvTable;
}

// Future<List<List<dynamic>>> getNewWordCount()
// async {
  
// }


Future<String> createExampleParentChild(ParentDataService parentService, ChildDataService childService)
async {
  Parent parent = await parentService.createParent("test2@test.test", "testParent1", []);
  print("Added parent with id" + (parent.id ?? "FAILED"));
  Child kid = await childService.createChild(DateTime(1999, 9, 9), "testChild2", 0, [(parent.id ?? "FAILED")]);
  parentService.addChildToParent(parent.id ?? "", kid.id ?? "");
  print("Added child with id" + (kid.id ?? "FAILED"));
  return (kid.id ?? "FAILED");
}


//testing child id: gz1Qe32xJcF0oRGmhw7f
Future<void> addWordToChild(String word, ChildDataService childService, WordDataService wordService, WordTrackerDataService trackerService, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
  if (childService.getChild(id) == null)
  {
    return;
  }
  //FIXME: implement language, part of speech, defn
  Word wordObject = await wordService.createWord(word, [LanguageCode.en], PartOfSpeech.noun, "testWord");
  //FIXME: numUtterances to be removed
  trackerService.createWordTracker(id, word, DateTime.now(), 1);
}