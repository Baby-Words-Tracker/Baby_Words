class DocumentCreationFailedException implements Exception {
  final String message;

  DocumentCreationFailedException([this.message = "Document creation failed"]);

  @override
  String toString() {
    return "DocumentCreationFailedException: $message";
  }
}
