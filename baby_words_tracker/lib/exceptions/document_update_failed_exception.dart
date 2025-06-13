class DocumentUpdateFailedException implements Exception {
  final String message;

  DocumentUpdateFailedException([this.message = "Document update failed"]);

  @override
  String toString() {
    return "DocumentUpdateFailedException: $message";
  }
}
