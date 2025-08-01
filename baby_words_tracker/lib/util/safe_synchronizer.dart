import 'dart:async';

/// This class allows for an asynchronous function to be safely
///   run without awaiting if it is not meant to be run concurrently.
///   The primary use case is for asynchronous functions in listeners.
/// In its default mode, it runs the function on the first call to
/// safeSynchronize then ignores all aubsequent calls until the function
/// completes.
/// If queueFunctionCalls is set to true at construction, the class will run the
/// function again on completion if a call was recieved while it was already running.
class SafeSynchronizer {
  final Function _syncFunction;
  bool _needSynchronization = false;
  final bool _queueFunctionCalls;

  /// Creates a SafeSynchronizer object.
  /// The [syncFunction] must be a Future\<void\> function or return Future\<void\>
  /// [queueFunctionCalls] will queue subsequenct function calls instead of ignoring them if set to true
  SafeSynchronizer(Function syncFunction, {bool queueFunctionCalls = false})
      : _syncFunction = syncFunction,
        _queueFunctionCalls = queueFunctionCalls;

// Use a completer to track synchronization state
  Completer<void>? _syncCompleter;

// Safe synchronization method
  Future<void> safeSynchronize(
      [List<dynamic> positionalArgs = const []]) async {
    if (_syncCompleter != null) {
      // Sync already in progress, return existing future
      _needSynchronization = _queueFunctionCalls;
      return _syncCompleter!.future;
    }

    _syncCompleter = Completer<void>();
    try {
      do {
        _needSynchronization = false;
        await Function.apply(
          // This might be a problem if a synchronous function is used?
          _syncFunction,
          positionalArgs,
        );
      } while (_needSynchronization);
    } finally {
      _syncCompleter!.complete();
      _syncCompleter = null;
    }
  }
}
