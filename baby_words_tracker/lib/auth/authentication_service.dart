
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuthInstance;
  User? _user;

  AuthenticationService(this._firebaseAuthInstance) {
    _firebaseAuthInstance.userChanges().listen((User? user) {
      debugPrint("AuthenticationService: User change detected");

      if ((_user == null && user != null) ||
          (_user != null && user == null) ||
          _user?.uid != user?.uid ||
          _user?.displayName != user?.displayName || 
          _user?.email != user?.email || 
          _user?.photoURL != user?.photoURL) {
        _user = user;
        debugPrint('AuthenticationService: User update -> uid:${_user?.uid} email: ${_user?.email} displayName: ${_user?.displayName}');
        notifyListeners(); // Only notify listeners if relevant fields have changed
      }
      else {
        _user = user;
      }
    });
  }

  User? get user => _user;

  String? get userId => _user?.uid;
  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;

  bool get isAuthenticated => _user != null;
}