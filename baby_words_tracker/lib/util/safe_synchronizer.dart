import 'dart:async';

class SafeSynchronizer {
  final Function _syncFunction;
  bool _needSynchronization = false;
  final bool _queueFunctionCalls;

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
