import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuthInstance;
  late final SafeSynchronizer _safeSynchronizer;

  User? _user;
  Map<String, dynamic>? _customClaims;

  AuthenticationService(this._firebaseAuthInstance) {
    _safeSynchronizer = SafeSynchronizer(_fetchCustomClaims);

    _firebaseAuthInstance.userChanges().listen((User? user) {
      debugPrint("AuthenticationService: User change detected");

      if ((_user == null && user != null) ||
          (_user != null && user == null) ||
          _user?.uid != user?.uid ||
          _user?.email != user?.email) {
        debugPrint(
            'AuthenticationService: User update -> uid:${_user?.uid} email: ${_user?.email} displayName: ${_user?.displayName}');

        _user = user;
        notifyListeners(); // Only notify listeners if relevant fields have changed
      } else {
        debugPrint(
            'AuthenticationService: No Change -> uid:${_user?.uid} email: ${_user?.email} displayName: ${_user?.displayName}');
        _user = user;
      }

      _safeSynchronizer.safeSynchronize();
    });
  }

  Future<void> _fetchCustomClaims([bool forceRefresh = false]) async {
    if (_user != null) {
      try {
        final idTokenResult = await _user!.getIdTokenResult(forceRefresh);
        _customClaims = idTokenResult.claims;
        notifyListeners();
      } catch (e) {
        debugPrint('Error fetching custom claims: $e');
        _customClaims = null;
        notifyListeners();
      }
    } else {
      _customClaims = null;
      notifyListeners();
      debugPrint('User is null, cannot fetch custom claims');
    }
  }

  // forces a refresh of the user's custom claims
  Future<void> refreshUserClaims() async {
    await _fetchCustomClaims(true);
  }

  User? get user => _user;
  Map<String, dynamic>? get customClaims => _customClaims;

  List<UserRole> get roles {
    return getUserRolesFromClaims(_customClaims ?? {});
  }

  String? get userId => _user?.uid;
  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;

  bool get isAuthenticated => _user != null;
}
