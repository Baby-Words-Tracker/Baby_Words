import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

abstract class ITypeAwareDataService {
  final UserModelService _userModelService;

  ITypeAwareDataService({
    required UserModelService userModelService,
  }) : _userModelService = userModelService;

  bool get isDemoType => _userModelService.userType.isDemoType;
}
