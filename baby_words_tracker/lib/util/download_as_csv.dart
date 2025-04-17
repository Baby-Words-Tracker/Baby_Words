import 'package:to_csv/to_csv.dart' as export_csv;

void downloadAsCSV(List<String> header, List<List<String>> dataList,
    [String fileName = "wordUtteranceData-"]) {
  export_csv.myCSV(header, dataList,
      setHeadersInFirstRow: true, fileName: fileName);
}
