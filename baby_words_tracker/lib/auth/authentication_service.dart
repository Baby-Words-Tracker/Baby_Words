
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuthInstance;
  User? _user;

  AuthenticationService(this._firebaseAuthInstance) {
    _firebaseAuthInstance.userChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;

  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;

  bool get isAuthenticated => _user != null;


}