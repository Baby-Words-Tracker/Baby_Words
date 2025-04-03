import 'dart:async';

import 'package:synchronized/synchronized.dart';

import 'package:flutter/foundation.dart';

class SafeSynchronizer {
  final Future<void> Function() _syncFunction;

  Duration? _debounceDuration;
  Timer? _debounceTimer;

  SafeSynchronizer(Future<void> Function() syncFunction,
      {Duration? debounceDuration})
      : _syncFunction = syncFunction,
        _debounceDuration = debounceDuration;

// Use a completer to track synchronization state
  final List<Completer<void>> _syncCompleters = [];
  final _completersLock = Lock();

  final _syncLock = Lock();

// Safe synchronization method
  Future<void> safeSynchronize(
      [List<dynamic> positionalArgs = const []]) async {
    debugPrint(
        "SafeSynchronizer: safeSynchronize() called with state $_syncCompleters");

    Future<void>? future = await _completersLock.synchronized(() {
      if (_syncCompleters.length < 2) {
        _syncCompleters.add(Completer<void>());
        return null;
      } else {
        return _syncCompleters.last.future;
      }
    });

    if (future != null) {
      return future;
    }

    await _syncLock.synchronized(() async {
      await _doSynchronize(positionalArgs);
      await _completersLock.synchronized(() {
        _syncCompleters.first.complete();
        _syncCompleters.removeAt(0);
        debugPrint(
            "SafeSynchronizer: Synchronization completed, remaining: $_syncCompleters");
      });
    });
  }

  Future<void> _doSynchronize([List<dynamic> positionalArgs = const []]) async {
    try {
      debugPrint("SafeSynchronizer: Synchronizing");
      await Function.apply(
        _syncFunction,
        positionalArgs,
      );
    } catch (e, stackTrace) {
      debugPrint("SafeSynchronizer: Synchronization error: $e /n $stackTrace");
    } finally {
      debugPrint(
          "SafeSynchronizer: Synchronization completed with state $_syncCompleters");
    }
  }
}
