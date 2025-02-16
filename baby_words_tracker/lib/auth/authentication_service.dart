
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuthInstance;
  User? _user;

  AuthenticationService(this._firebaseAuthInstance) {
    _firebaseAuthInstance.userChanges().listen((User? user) {
      debugPrint("User change detected");

      if ((_user == null && user != null) ||
          (_user != null && user == null) || 
          _user?.displayName != user?.displayName || 
          _user?.email != user?.email || 
          _user?.photoURL != user?.photoURL) {
        _user = user;
        debugPrint('User update -> name:${_user?.displayName ?? 'No name'} email: ${_user?.email ?? 'No email'}');
        notifyListeners(); // Only notify listeners if relevant fields have changed
      }
      else {
        _user = user;
      }
    });
  }

  User? get user => _user;

  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;

  bool get isAuthenticated => _user != null;
}