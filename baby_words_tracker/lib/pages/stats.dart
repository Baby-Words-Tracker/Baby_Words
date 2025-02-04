import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';

class StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //FIXME: dependency inject these (obviously)
    ParentDataService parentService = ParentDataService();
    ChildDataService childService = ChildDataService();

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
                // return ListView.builder(
                //   itemCount: csvData.length,
                //   itemBuilder: (context, index) {
                //     return ListTile(
                //       title: Text(csvData[index].join(", ")), // Show CSV row as text
                //     );
                //   },
                // );
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

Future<List<List<dynamic>>> getNewWordCount()
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

//1
Future<String> createExampleParentChild(ParentDataService parentService, ChildDataService childService)
async {
  String pid = await parentService.createParent("test1@test.test", "testParent1", []);
  String cid = await childService.createChild(DateTime(1999, 9, 9), "testChild1", 0, [pid]);
  return cid;
}

