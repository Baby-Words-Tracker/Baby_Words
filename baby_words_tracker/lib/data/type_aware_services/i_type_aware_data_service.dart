import 'package:baby_words_tracker/auth/authentication_service.dart';

abstract class ITypeAwareDataService {
  final AuthenticationService _authenticationService;

  ITypeAwareDataService({
    required AuthenticationService authenticationService,
  }) : _authenticationService = authenticationService;

  // a helper function to quickly check if the user is a
  //    demo user in all child classes using the authentication
  //    service (allows easy updates in the future)
  bool get isDemoUser => _authenticationService.isDemoUser;
}
