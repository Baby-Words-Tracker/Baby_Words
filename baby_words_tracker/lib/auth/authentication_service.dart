import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/demo_role.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_roles.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuthInstance;
  late final SafeSynchronizer _safeSynchronizer;

  User? _user;
  Map<String, dynamic>? _customClaims;
  List<UserRole> _userRoles = [UserRole.unauthenticated];
  UserType _userType = UserType.unauthenticated_type;
  bool _isDemoUser = false;

  AuthenticationService(this._firebaseAuthInstance) {
    _safeSynchronizer =
        SafeSynchronizer(_fetchCustomClaims, queueFunctionCalls: true);

    _firebaseAuthInstance.userChanges().listen((User? user) {
      debugPrint("AuthenticationService: User change detected");

      if ((_user == null && user != null) ||
              (_user != null && user == null) ||
              _user?.uid != user?.uid ||
              _user?.email != user?.email ||
              _user?.toString() !=
                  user?.toString() // This line should check for nay changes to the user. It may need to be modified/verified, but notifications here are not extremeley important
          ) {
        debugPrint(
            'AuthenticationService: User update -> uid:${user?.uid} email: ${user?.email} displayName: ${user?.displayName}');

        _user = user;
        _safeSynchronizer.safeSynchronize().then((_) {
          debugPrint(
              'AuthenticationService: User update processed, notifying listeners');
          debugPrint(
              'AuthenticationService: User type: ${_userType.displayName}, roles: ${_userRoles.map((role) => role.name).join(', ')}, isDemoUser: $_isDemoUser');
          notifyListeners(); // Only notify listeners if relevant fields have changed
        });
      }
      // in this case, the user has not changed in some measurable way even though the listener was triggered, so we don't notiy by default.
      else {
        debugPrint(
            'AuthenticationService: No Change -> uid:${_user?.uid} email: ${_user?.email} displayName: ${_user?.displayName}');
        _user = user;
        _safeSynchronizer.safeSynchronize();
      }
    });
  }

  Future<void> _fetchCustomClaims([bool forceRefresh = false]) async {
    if (_user != null) {
      try {
        final idTokenResult = await _user!.getIdTokenResult(forceRefresh);
        var oldClaims = _customClaims;
        _customClaims = idTokenResult.claims;
        if (!(const DeepCollectionEquality())
            .equals(oldClaims, _customClaims)) {
          debugPrint(
              'AuthenticationService: Custom claims updated with new values');
          _userRoles = getUserRolesFromClaims(_customClaims);
          _userType = getUserTypeFromClaims(_customClaims);
          _isDemoUser = isDemoRoleFromClaims(_customClaims);

          notifyListeners();
        } else {
          debugPrint(
              'AuthenticationService: Custom claims unchanged, no need to notify listeners');
        }
      } catch (e) {
        debugPrint('Error fetching custom claims: $e');
        _customClaims = null;
        _userRoles = [UserRole.unauthenticated];
        _userType = UserType.unauthenticated_type;
        _isDemoUser = false;
        notifyListeners();
      }
    } else {
      _customClaims = null;
      _userRoles = [UserRole.unauthenticated];
      _userType = UserType.unauthenticated_type;
      _isDemoUser = false;
      notifyListeners();
      debugPrint('User is null, cannot fetch custom claims');
    }
  }

  // forces a refresh of the user's custom claims
  Future<void> refreshUserToken() async {
    await _fetchCustomClaims(true);
  }

  Future<void> signOut() async {
    try {
      _user = null;
      _customClaims = null;
      _userRoles = [UserRole.unauthenticated];
      _userType = UserType.unauthenticated_type;
      _isDemoUser = false;
      await _firebaseAuthInstance.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  User? get user => _user;

  /// Returns the custom claims of the authenticated user as a raw map.
  /// Use getUserRolesFromClaims from the UserRoles enum to get the roles from the claims.
  Map<String, dynamic>? get customClaims => _customClaims;

  List<UserRole> get roles => _userRoles;

  String? get userId => _user?.uid;
  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;

  UserType get userType => _userType;

  bool get isAuthenticated => _user != null;

  bool get isDemoUser => _isDemoUser;
}
