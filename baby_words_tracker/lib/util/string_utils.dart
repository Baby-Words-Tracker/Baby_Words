extension StringExtensions on String? {
  String capitalizeOrNA() {
    if (this == null || this!.isEmpty) return "N/A";
    if (this!.length == 1) return this!.toUpperCase();
    return "${this![0].toUpperCase()}${this!.substring(1)}";
  }
}
