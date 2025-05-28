class ActionFailedException implements Exception {
  final String message;

  ActionFailedException([this.message = "Action failed"]);

  @override
  String toString() {
    return "ActionFailedException: $message";
  }
}
