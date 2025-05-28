import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import "package:baby_words_tracker/util/cloud_function_utils.dart";
import 'package:baby_words_tracker/util/download_as_csv.dart';

class AdminPage extends StatefulWidget {
  static const routeName = '/adminpage';

  const AdminPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedUserEmail;

  Map<String, dynamic> _userRoles = {};
  List<Map<String, dynamic>> _userData = [];

  Future<void> _callRoleFunction(String functionName) async {
    if (_selectedUserEmail == null) return;
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
      final claims = row['customClaims'] as List<UserRole>? ?? [];
      return List<String>.from([
        row['email'] ?? '',
        row['uid'] ?? '',
        row['disabled']?.toString() ?? '',
        ...UserRole.values
            .map((role) => claims.contains(role) ? 'true' : 'false'),
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
  ];

  Widget _buildPadded(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: child,
    );
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
                  _userRoles = {};
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
                        Text('Selected User ID: $_selectedUserEmail'),
                        // TODO: make this wrap
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(" User Roles: ["),
                            ..._userRoles.entries.map(
                              (entry) {
                                return Text("(${entry.key}: ${entry.value}), ");
                              },
                            ),
                            const Text("]"),
                          ],
                        ),
                        _buildPadded(
                          ElevatedButton(
                            child: const Text("Get Custom Claims"),
                            onPressed: () async {
                              var customClaims = await callFunction(
                                context,
                                'getUserCustomClaims',
                                {'targetEmail': _selectedUserEmail},
                              );
                              if (customClaims == null) {
                                // debugPrint("No Custom Claims");
                                return;
                              } else {
                                setState(() {
                                  _userRoles = customClaims;
                                });
                              }
                            },
                          ),
                        ),
                        // TODO: add a button here to make a user a parnet and one to make them a researcher or use a dropdown and a single button to change user type.
                        _buildPadded(
                          ElevatedButton(
                            child: const Text("Assign Parent Role"),
                            onPressed: () async {
                              if (await showConfirmationDialog(context,
                                      'Are your sure you want to assign the Parent role to $_selectedUserEmail?') ??
                                  false) {
                                await _callRoleFunction('giveParentClaim');
                              }
                            },
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            child: const Text("Remove Parent Role"),
                            onPressed: () async {
                              if (await showConfirmationDialog(context,
                                      'Are your sure you want to remove the Parent role from $_selectedUserEmail?') ??
                                  false) {
                                await _callRoleFunction('removeParentClaim');
                              }
                            },
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                              child: const Text('Assign Researcher Role'),
                              onPressed: () async {
                                if (await showConfirmationDialog(context,
                                        'Are your sure you want to give the Researcher role to $_selectedUserEmail?') ??
                                    false) {
                                  _callRoleFunction('giveResearcherClaim');
                                }
                              }),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            child: const Text('Remove Researcher Role'),
                            onPressed: () async {
                              if (await showConfirmationDialog(context,
                                      'Are your sure you want to remove the Researcher role from $_selectedUserEmail?') ??
                                  false) {
                                _callRoleFunction('removeResearcherClaim');
                              }
                            },
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            child: const Text('Assign Admin Role'),
                            onPressed: () async {
                              if (await showConfirmationDialog(context,
                                      'Are your sure you want to give the Admin role to $_selectedUserEmail?') ??
                                  false) {
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
                                      'Are your sure you want to remove the Admin role from $_selectedUserEmail?') ??
                                  false) {
                                _callRoleFunction('removeAdminClaim');
                              }
                            },
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            child: const Text('Get Email-UID Data'),
                            onPressed: () async {
                              if (await showConfirmationDialog(context,
                                      'This will query all email and uid data and return it as a csv. Continue?') ??
                                  false) {
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
                                          .map<Map<String, dynamic>>((user) {
                                    final rawMap =
                                        user as Map<Object?, Object?>;
                                    final userMap =
                                        convertToMapStringDynamic(rawMap);

                                    if (userMap['customClaims'] != null) {
                                      userMap['customClaims'] =
                                          getUserRolesFromClaims(
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
                        ),
                      ],
                    ),
                  ),
                  if (_userData.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _userData.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_userData[index]['email'] ?? ''),
                            subtitle: Text(
                                'UID: ${_userData[index]['uid'] ?? ''}, Roles: ${_userData[index]['customClaims'].toString()}${_userData[index]['disabled'] ? '  -  (User is disabled.)' : ''}'),
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
