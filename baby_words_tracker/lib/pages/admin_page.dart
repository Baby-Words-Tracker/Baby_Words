import "package:baby_words_tracker/util/cloud_function_utils.dart";
import 'package:baby_words_tracker/data/services/general_user_service.dart';
import 'package:baby_words_tracker/exceptions/action_failed_exception.dart';
import 'package:baby_words_tracker/util/download_as_csv.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_roles.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  static const routeName = '/admin';

  const AdminPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _searchController = TextEditingController();

  UserType? _selectedUserType;

  String _selectedUserEmail = '';

  Map<String, dynamic>? _userRoles;
  List<Map<String, dynamic>> _userData = [];

  late final GeneralUserService _generalUserService;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _generalUserService =
          Provider.of<GeneralUserService>(context, listen: false);
      // debugPrint("AdminPage didChangeDependencies called");
      // debugPrint("GeneralUserService: $_generalUserService");
      _initialized = true;
    }
  }

  Future<void> _callRoleFunction(String functionName) async {
    if (_selectedUserEmail.isEmpty) return;
    // debugPrint('Getting callable for function $functionName with uid $_selectedUserEmail');
    HttpsCallable function =
        FirebaseFunctions.instance.httpsCallable(functionName);
    try {
      // debugPrint('Calling function $functionName with uid $_selectedUserEmail');
      final response = await function.call({'targetEmail': _selectedUserEmail});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response.data['message'])));
      } else {
        debugPrint(
            "Context not mounted. Function returned message: ${response.data['message']}");
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $error')));
      } else {
        debugPrint("Context not mounted. Error: $error");
      }
    }
  }

  List<List<String>> _convertUserDataToLineList(
      List<Map<String, dynamic>> userData) {
    return userData.map((row) {
      final roles = row['roles'] as List<UserRole>? ?? [];
      final type = row['type'] as UserType? ?? UserType.unauthenticated_type;
      return List<String>.from([
        row['email'] ?? '',
        row['uid'] ?? '',
        row['disabled']?.toString() ?? '',
        ...UserRole.values
            .map((role) => roles.contains(role) ? 'true' : 'false'),
        ...UserType.values.map((type_) => type == type_ ? 'true' : 'false'),
      ]);
    }).toList();
  }

  Map<String, dynamic> convertToMapStringDynamic(Map<Object?, Object?> input) {
    return input.map((key, value) {
      return MapEntry(
        key.toString(),
        value is Map<Object?, Object?>
            ? convertToMapStringDynamic(value)
            : value,
      );
    });
  }

  List<String> header = [
    'email',
    'uid',
    'disabled',
    for (var role in UserRole.values) role.name,
    for (var type in UserType.values) type.name,
  ];

  Widget _buildPadded(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }

  // TODO: change this to use a cloud function instead of multiple calls
  Future<void> changeUserType(UserType newType) async {
    Map<String, dynamic>? data;
    if (newType == UserType.unauthenticated_type) {
      throw ArgumentError(
          'Invalid user type: $newType. Unauthenticated is not allowed.');
    }
    try {
      data = await callFunctionWithThrow(
        // ignore: use_build_context_synchronously
        context,
        'getUserIdByEmail',
        {'targetEmail': _selectedUserEmail},
      );

      if (data == null || data['userId'] == null) {
        data = null;
        if (mounted) {
          showAlertMessage(
            context,
            'Error',
            'No user found with email $_selectedUserEmail',
          );
        } else {
          debugPrint("No user found with email $_selectedUserEmail");
        }
      }
    } catch (e) {
      if (mounted) {
        showAlertMessage(
          context,
          'Error',
          'No user found with email $_selectedUserEmail',
        );
      } else {
        debugPrint("No user found with email $_selectedUserEmail");
      }
    }

    if (data == null) {
      return;
    }

    final String userId = data['userId'] as String;
    try {
      if (mounted) {
        // TODO: update this
        switch (newType) {
          case UserType.parent_type:
            await _callRoleFunction('giveParentClaim');
            await _callRoleFunction('removeResearcherClaim');
            await _generalUserService.changeUserStorageType(userId, newType);
            break;
          case UserType.researcher_type:
            await _callRoleFunction('giveResearcherClaim');
            await _callRoleFunction('removeParentClaim');
            await _generalUserService.changeUserStorageType(userId, newType);
            break;
          default:
            throw ArgumentError('Invalid user type: $newType.');
        }
        await callFunction(
          // ignore: use_build_context_synchronously
          context, // this function checks for mounted so it is safe
          'setTypeClaim',
          {'newType': newType.name, 'targetEmail': _selectedUserEmail},
        );
      } else {
        debugPrint(
            "Change user type action not performed in admin page because context is not mounted.");
      }
    } on ActionFailedException catch (e) {
      if (mounted) {
        showAlertMessage(
          context,
          'Error',
          'Failed to change user type: ${e.message}',
        );
      } else {
        debugPrint("Failed to change user type: ${e.message}");
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User type changed to ${newType.displayName} for $_selectedUserEmail'),
        ),
      );
    } else {
      debugPrint(
          "User type changed to ${newType.displayName} for $_selectedUserEmail");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search User by Email',
              ),
              onChanged: (String value) async {
                // debugPrint("Setting value for $value");
                setState(() {
                  _selectedUserEmail = value;
                  _userRoles = null;
                  _selectedUserType = null;
                  // debugPrint("_selectedUserEmail set to $value");
                });
              },
            ),
            // ),
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected User Email: $_selectedUserEmail'),
                        // TODO: make this wrap
                        if (_userRoles != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(" User Roles: ["),
                              ..._userRoles!.entries.map(
                                (entry) {
                                  return Text(
                                      "(${entry.key}: ${entry.value}), ");
                                },
                              ),
                              const Text("]"),
                            ],
                          ),
                        _buildPadded(
                          ElevatedButton(
                            child: const Text("Get Custom Claims"),
                            onPressed: () async {
                              late final Map<String, dynamic>? customClaims;
                              bool failure = false;
                              try {
                                customClaims = await callFunctionWithThrow(
                                  context,
                                  'getUserCustomClaims',
                                  {'targetEmail': _selectedUserEmail},
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to get custom claims: $e'),
                                    ),
                                  );
                                } else {
                                  debugPrint("Failed to get custom claims: $e");
                                }
                                failure = true;
                              }

                              if (failure) {
                                setState(() {
                                  _userRoles = null;
                                });
                                return;
                              } else if (customClaims == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'No custom claims found for this user.'),
                                    ),
                                  );
                                } else {
                                  debugPrint(
                                      "No custom claims found for this user.");
                                }
                                setState(() {
                                  _userRoles = {};
                                });
                              } else {
                                setState(() {
                                  _userRoles = customClaims!;
                                });
                              }
                            },
                          ),
                        ),
                        _buildPadded(Text("User Roles Controls:")),
                        _buildPadded(
                          Padding(
                            padding: EdgeInsetsGeometry.only(left: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text("Assign Parent Role"),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to assign the Parent role to $_selectedUserEmail?')) {
                                        await _callRoleFunction(
                                            'giveParentClaim');
                                      }
                                    },
                                  ),
                                ),
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text("Remove Parent Role"),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to remove the Parent role from $_selectedUserEmail?')) {
                                        await _callRoleFunction(
                                            'removeParentClaim');
                                      }
                                    },
                                  ),
                                ),
                                _buildPadded(
                                  ElevatedButton(
                                      child:
                                          const Text('Assign Researcher Role'),
                                      onPressed: () async {
                                        if (await showConfirmationDialog(
                                            context,
                                            'Are your sure you want to give the Researcher role to $_selectedUserEmail?')) {
                                          _callRoleFunction(
                                              'giveResearcherClaim');
                                        }
                                      }),
                                ),
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text('Remove Researcher Role'),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to remove the Researcher role from $_selectedUserEmail?')) {
                                        _callRoleFunction(
                                            'removeResearcherClaim');
                                      }
                                    },
                                  ),
                                ),
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text('Assign Admin Role'),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to give the Admin role to $_selectedUserEmail?')) {
                                        _callRoleFunction('giveAdminClaim');
                                      }
                                    },
                                  ),
                                ),
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text('Remove Admin Role'),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to remove the Admin role from $_selectedUserEmail?')) {
                                        _callRoleFunction('removeAdminClaim');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildPadded(
                          Text('User Type Controls:'),
                        ),
                        _buildPadded(
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text(
                                        "Change user type to Researcher"),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to make $_selectedUserEmail a Researcher?')) {
                                        await changeUserType(
                                            UserType.researcher_type);
                                      }
                                    },
                                  ),
                                ),
                                _buildPadded(
                                  ElevatedButton(
                                    child: const Text(
                                        "Change user type to Parent"),
                                    onPressed: () async {
                                      if (await showConfirmationDialog(context,
                                          'Are your sure you want to make $_selectedUserEmail a Parent?')) {
                                        await changeUserType(
                                            UserType.parent_type);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildPadded(Text("Email UID Data Controls:")),
                        _buildPadded(
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  child: const Text('Get Email-UID Data'),
                                  onPressed: () async {
                                    if (await showConfirmationDialog(context,
                                        'This will query all email and uid data and return it as a csv. Continue?')) {
                                      // TODO: do I need to check this context here?
                                      var userData = await callFunction(
                                          context, 'getEmailUIDTable', {});
                                      if (userData != null) {
                                        // List<Map<String, dynamic>>
                                        // debugPrint(
                                        //     "userData received: ${userData['users']}");
                                        // debugPrint("");
                                        // // print the type of users
                                        // debugPrint(
                                        //     "users type: ${userData['users'].runtimeType}");
                                        // // print the type of users['users'].first
                                        // debugPrint(
                                        //     "users[0] type: ${userData['users'][0].runtimeType}");

                                        // // print the type of the objects in userDats.first
                                        // debugPrint("");
                                        // userData['users'].forEach((key, value) {
                                        //   debugPrint(
                                        //       "userData.first key: $key value: $value");
                                        //   debugPrint(
                                        //       "\t\tuserData.first valuetype: ${value.runtimeType} ");
                                        // });

                                        List<Map<String, dynamic>> users =
                                            (userData['users'] as List)
                                                .map<Map<String, dynamic>>(
                                                    (user) {
                                          final rawMap =
                                              user as Map<Object?, Object?>;
                                          final userMap =
                                              convertToMapStringDynamic(rawMap);

                                          // add roles and type to the user map
                                          if (userMap['customClaims'] != null) {
                                            userMap['roles'] =
                                                getUserRolesFromClaims(
                                                    userMap['customClaims']);
                                            userMap['type'] =
                                                getUserTypeFromClaims(
                                                    userMap['customClaims']);
                                          }

                                          return userMap;
                                        }).toList();

                                        // debugPrint("userData received: $users");
                                        // debugPrint("");
                                        // // print the type of users
                                        // debugPrint("users type: ${users.runtimeType}");
                                        // // print the type of users['users'].first
                                        // debugPrint(
                                        //     "users[0] type: ${users[0].runtimeType}");

                                        // // print the type of the objects in userDats.first
                                        // debugPrint("");
                                        // users.first.forEach((key, value) {
                                        //   debugPrint(
                                        //       "userData.first key: $key value: $value");
                                        //   debugPrint(
                                        //       "\t\tuserData.first valuetype: ${value.runtimeType} ");
                                        // });
                                        // debugPrint("");

                                        setState(() {
                                          _userData = users;
                                        });

                                        final dataList =
                                            _convertUserDataToLineList(users);

                                        // debugPrint("userData received: $dataList");
                                        // debugPrint("");
                                        // // print the type of dataList
                                        // debugPrint(
                                        //     "dataList type: ${dataList.runtimeType}");
                                        // // print the type of dataList['dataList'].first
                                        // debugPrint(
                                        //     "dataList[0] type: ${dataList[0].runtimeType}");

                                        // // print the type of the objects in userDats.first
                                        // debugPrint("");
                                        // for (var value in dataList.first) {
                                        //   debugPrint("userData value: $value");
                                        //   debugPrint(
                                        //       "\t\tuserData valuetype: ${value.runtimeType} ");
                                        // }
                                        // debugPrint("");

                                        downloadAsCSV(
                                            header, dataList, "UserUIDData");
                                      } else {
                                        debugPrint("No user data received");
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // TODO: allow this view for ipads
                  if (kIsWeb && _userData.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _userData.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_userData[index]['email'] ?? ''),
                            subtitle: Text(
                                'UID: ${_userData[index]['uid'] ?? ''}, Roles: ${_userData[index]['roles'].toString()}, Type: ${_userData[index]['type']}${_userData[index]['disabled'] ? '  -  (User is disabled.)' : ''}'),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
