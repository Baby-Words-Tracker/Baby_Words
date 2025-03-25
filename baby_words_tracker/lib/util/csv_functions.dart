import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

Future<List<List<dynamic>>> processCSV({String assetName = 'data.csv'})
async {
  //handle data, convert into readable list
  // Load the CSV file from assets
  final csvString = await rootBundle.loadString('assets/$assetName');

  // Parse the CSV
  final csvTable = const CsvToListConverter().convert(csvString);
  debugPrint("cosntructed csvtable");
  return csvTable;
}

FutureBuilder<List<List<dynamic>>> textFromCSV({String assetName = 'data.csv'}){
  return FutureBuilder<List<List<dynamic>>>(
    future: processCSV(assetName: assetName), // Call async function
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator()); // Show loading
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}')); // Show error
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No Data Available'));
      }

      final csvData = snapshot.data!;
      String result = "";
      for (var item in csvData.take(5)) { // Print first 5 elements
        result+="X: ${item[0]} (Type: ${item[0].runtimeType}), Y: ${item[1]} (Type: ${item[1].runtimeType})\n";
      }
      return Text(result);
    }
  );
}


FutureBuilder<List<List<dynamic>>> chartFromCSV(){
  return FutureBuilder<List<List<dynamic>>>(
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
      // for (var item in csvData.take(5)) { // Print first 5 elements
      //   print("X: ${item[0]} (Type: ${item[0].runtimeType}), Y: ${item[1]} (Type: ${item[1].runtimeType})");
      // }
      return SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        series: [
          LineSeries<List<dynamic>, String>(
              dataSource: csvData.take(10).toList(),// use the first 10 elements for the chart
              xValueMapper: (List<dynamic> data, _) => data[0].toString(), //_ indicates an unused parameter in Dart
              yValueMapper: (List<dynamic> data, _) => int.tryParse(data[1].toString()) ?? 0
            )
        ],
      );
    }
  );
}