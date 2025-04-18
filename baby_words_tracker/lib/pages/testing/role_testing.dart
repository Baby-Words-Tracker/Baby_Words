import 'package:baby_words_tracker/util/user_type.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import "package:baby_words_tracker/util/cloud_function_utils.dart";

class RoleTesting extends StatefulWidget {
  static const routeName = '/roletesting';

  const RoleTesting({super.key});

  @override
  _RoleTestingState createState() => _RoleTestingState();
}

class _RoleTestingState extends State<RoleTesting> {
  UserType _selectedUserType = UserType.parent;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedUserEmail;

  Map<String, dynamic> _userRoles = {};
  List<String> _userData = [];

  // Future<List<Map<String, String>>> _searchUsers(String query) async {
  //   if (query.isEmpty) return [];

  //   String collection = _selectedUserType == UserType.parent
  //       ? Parent.collectionName
  //       : Researcher.collectionName;
  //   var snapshot = await FirebaseFirestore.instance
  //       .collection(collection)
  //       .where('email', isGreaterThanOrEqualTo: query)
  //       .where('email', isLessThan: '${query}z')
  //       .limit(5)
  //       .get();

  //   return snapshot.docs
  //       .map((doc) => {'email': doc['email'] as String, 'uid': doc.id})
  //       .toList();
  // }

  Future<void> _callRoleFunction(String functionName) async {
    if (_selectedUserEmail == null) return;
    debugPrint(
        'Getting callable for function $functionName with uid $_selectedUserEmail');
    HttpsCallable function =
        FirebaseFunctions.instance.httpsCallable(functionName);
    try {
      debugPrint('Calling function $functionName with uid $_selectedUserEmail');
      final response = await function.call({'targetEmail': _selectedUserEmail});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.data['message'])));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Firebase Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search User by Email',
              ),
              onChanged: (String value) async {
                debugPrint("Setting value for $value");
                setState(() {
                  _selectedUserEmail = value;
                  _userRoles = {};
                  debugPrint("_selectedUserEmail set to $value");
                });
              },
            ),
            if (_selectedUserEmail != null) ...[
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
              ElevatedButton(
                onPressed: () async {
                  var customClaims = await callFunction(
                    context,
                    'getUserCustomClaims',
                    {'targetEmail': _selectedUserEmail},
                  );
                  if (customClaims == null) {
                    debugPrint("No Custom Claims");
                    return;
                  } else {
                    setState(() {
                      _userRoles = customClaims;
                    });
                  }
                },
                child: const Text("Get Custom Claims"),
              ),
              ElevatedButton(
                  onPressed: () async {
                    await _callRoleFunction('giveParentClaim');
                  },
                  child: const Text("Assign Parent Role")),
              ElevatedButton(
                  onPressed: () => _callRoleFunction('removeParentClaim'),
                  child: const Text("Remove Parent Role")),
              ElevatedButton(
                onPressed: () => _callRoleFunction('giveResearcherClaim'),
                child: const Text('Assign Researcher Role'),
              ),
              ElevatedButton(
                onPressed: () => _callRoleFunction('removeResearcherClaim'),
                child: const Text('Remove Researcher Role'),
              ),
              ElevatedButton(
                onPressed: () => _callRoleFunction('giveAdminClaim'),
                child: const Text('Assign Admin Role'),
              ),
              ElevatedButton(
                onPressed: () => _callRoleFunction('removeAdminClaim'),
                child: const Text('Remove Admin Role'),
              ),
              ElevatedButton(
                onPressed: () async {
                  var userData =
                      await callFunction(context, 'getEmailUIDTable', {});
                  if (userData != null) {
                    setState(() {
                      _userData = userData['users'] as List<String>;
                    });
                  }
                },
                child: const Text('Get Email-UID Data'),
              ),
              if (_userData.isNotEmpty) ...[
                const Text('User Data:'),
                ..._userData.map((data) => Text(data)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
