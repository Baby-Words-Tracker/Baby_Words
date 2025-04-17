import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import "package:baby_words_tracker/util/cloud_function_utils.dart";
import 'package:baby_words_tracker/util/download_as_csv.dart';

class RoleTesting extends StatefulWidget {
  static const routeName = '/roletesting';

  const RoleTesting({super.key});

  @override
  _RoleTestingState createState() => _RoleTestingState();
}

class _RoleTestingState extends State<RoleTesting> {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.data['message'])));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
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
      appBar: AppBar(title: const Text('Admin Firebase Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible(
            //     fit: FlexFit.loose,
            //     child:
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
                            child: const Text("Get Custom Claims"),
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                              onPressed: () async {
                                await _callRoleFunction('giveParentClaim');
                              },
                              child: const Text("Assign Parent Role")),
                        ),
                        _buildPadded(
                          ElevatedButton(
                              onPressed: () =>
                                  _callRoleFunction('removeParentClaim'),
                              child: const Text("Remove Parent Role")),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            onPressed: () =>
                                _callRoleFunction('giveResearcherClaim'),
                            child: const Text('Assign Researcher Role'),
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            onPressed: () =>
                                _callRoleFunction('removeResearcherClaim'),
                            child: const Text('Remove Researcher Role'),
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            onPressed: () =>
                                _callRoleFunction('giveAdminClaim'),
                            child: const Text('Assign Admin Role'),
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            onPressed: () =>
                                _callRoleFunction('removeAdminClaim'),
                            child: const Text('Remove Admin Role'),
                          ),
                        ),
                        _buildPadded(
                          ElevatedButton(
                            onPressed: () async {
                              var userData = await callFunction(
                                  context, 'getEmailUIDTable', {});
                              if (userData != null) {
                                // List<Map<String, dynamic>>
                                List<Map<String, dynamic>> users =
                                    (userData['users'] as List).map((user) {
                                  var userMap = Map<String, dynamic>.from(user);
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
                                // debugPrint("users[0] type: ${users[0].runtimeType}");

                                // // print the type of the objects in userDats.first
                                // debugPrint("");
                                // users.first.forEach((key, value) {
                                //   debugPrint("userData.first key: $key value: $value");
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
                                // debugPrint("dataList type: ${dataList.runtimeType}");
                                // // print the type of dataList['dataList'].first
                                // debugPrint("dataList[0] type: ${dataList[0].runtimeType}");

                                // // print the type of the objects in userDats.first
                                // debugPrint("");
                                // for (var value in dataList.first) {
                                //   debugPrint("userData value: $value");
                                //   debugPrint("\t\tuserData valuetype: ${value.runtimeType} ");
                                // }
                                // debugPrint("");

                                downloadAsCSV(header, dataList, "UserUIDData");
                              } else {
                                // debugPrint("No user data received");
                              }
                            },
                            child: const Text('Get Email-UID Data'),
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
