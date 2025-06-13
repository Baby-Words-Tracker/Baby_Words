class NetworkFailureException implements Exception {
  final int statusCode;
  final String message;

  NetworkFailureException(this.statusCode, [this.message = ""]);

  @override
  String toString() {
    if (message.isEmpty) {
      return 'NetworkFailureException: API returned status code $statusCode';
    }
    return 'NetworkFailureException: $message (Status code: $statusCode)';
  }
}
