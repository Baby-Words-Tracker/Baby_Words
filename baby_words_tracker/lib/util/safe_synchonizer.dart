import 'dart:async';

class SafeSynchonizer {
  final Future<void> Function() _syncFunction;
  bool _needSynchronization = false;

  SafeSynchonizer(Future<void> Function() syncFunction)
      : _syncFunction = syncFunction;

// Use a completer to track synchronization state
  Completer<void>? _syncCompleter;

// Safe synchronization method
  Future<void> safeSynchronize(
      [List<dynamic> positionalArgs = const []]) async {
    if (_syncCompleter != null) {
      // Sync already in progress, return existing future
      _needSynchronization = true;
      return _syncCompleter!.future;
    }

    _syncCompleter = Completer<void>();
    try {
      do {
        _needSynchronization = false;
        await Function.apply(
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
