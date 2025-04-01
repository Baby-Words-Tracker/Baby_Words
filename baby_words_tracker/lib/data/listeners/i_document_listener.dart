import 'package:flutter/material.dart';

/// A listener for a document in Firestore.
/// provides an up to date document in the data field.
/// overrrides must fill the data field with information and call notifyListeners to update the listeners.
abstract class IDocumentListener<T> extends ChangeNotifier {
  T? _data;
  bool _documentExists = true;
  Object? _error;

  Future<void> waitForFirstDocument();

  @protected
  set data(T? data) => _data = data;

  @protected
  set documentExists(bool documentExists) => _documentExists = documentExists;

  @protected
  set error(Object? error) => _error = error;

  T? get data => _data;
  bool get documentExists => _documentExists;
  Object? get error => _error;
}
