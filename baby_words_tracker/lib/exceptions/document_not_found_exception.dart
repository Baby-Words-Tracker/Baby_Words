class DocumentNotFoundException implements Exception {
  final String message;

  DocumentNotFoundException([this.message = "Document not found"]);

  @override
  String toString() {
    return "DocumentNotFoundException: $message";
  }
}
