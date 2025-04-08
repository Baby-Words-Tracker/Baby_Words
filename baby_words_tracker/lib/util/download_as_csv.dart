import 'package:to_csv/to_csv.dart' as exportCSV;

void downloadAsCSV(List<String> header, List<List<String>> dataList){
   exportCSV.myCSV(header, dataList, setHeadersInFirstRow: true, fileName: "wordUtteranceData-");
}