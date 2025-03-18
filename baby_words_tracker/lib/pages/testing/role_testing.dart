import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum UserType { parent, researcher, unauthenticated }

class AdminFirebasePage extends StatefulWidget {
  static const routeName = '/admin-firebase';

  const AdminFirebasePage({super.key});

  @override
  _AdminFirebasePageState createState() => _AdminFirebasePageState();
}

class _AdminFirebasePageState extends State<AdminFirebasePage> {
  UserType _selectedUserType = UserType.parent;
  TextEditingController _searchController = TextEditingController();
  String? _selectedUserId;

  Future<List<Map<String, String>>> _searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    String collection = _selectedUserType == UserType.parent ? Parent.collectionName : Researcher.collectionName;
    var snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThan: '${query}z')
        .limit(5)
        .get();

    return snapshot.docs.map((doc) => {'email': doc['email'] as String, 'uid': doc.id}).toList();
  }

  Future<void> _callFunction(String functionName) async {
    if (_selectedUserId == null) return;
    debugPrint('Getting callable for function $functionName with uid $_selectedUserId');
    HttpsCallable function = FirebaseFunctions.instance.httpsCallable(functionName);
    try {
      debugPrint('Calling function $functionName with uid $_selectedUserId');
      final response = await function.call({'targetUid': _selectedUserId});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'])));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
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
            DropdownButton<UserType>(
              value: _selectedUserType,
              onChanged: (UserType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedUserType = newValue;
                    _selectedUserId = null;
                    _searchController.clear();
                  });
                }
              },
              items: UserType.values
                  .where((type) => type != UserType.unauthenticated)
                  .map((UserType type) {
                return DropdownMenuItem<UserType>(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
            ),
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                return await _searchUsers(textEditingValue.text);
              },
              displayStringForOption: (Map<String, String> option) => option['email']!,
              onSelected: (Map<String, String> selection) {
                setState(() {
                  _searchController.text = selection['email']!;
                  _selectedUserId = selection['uid'];
                });
                debugPrint('Selected: ${selection['email']} with id ${selection['uid']}');
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _searchController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Search User by Email'),
                );
              },
            ),
            if (_selectedUserId != null) ...[
              ElevatedButton(
                onPressed: () => _callFunction('giveParentClaim'), 
                child: const Text("Assign Parent Role")
              ),
              ElevatedButton(
                onPressed: () => _callFunction('removeParentClaim'), 
                child: const Text("Remove Parent Role")
              ),
              ElevatedButton(
                onPressed: () => _callFunction('giveResearcherClaim'),
                child: const Text('Assign Researcher Role'),
              ),
              ElevatedButton(
                onPressed: () => _callFunction('removeResearcherClaim'),
                child: const Text('Remove Researcher Role'),
              ),
              ElevatedButton(
                onPressed: () => _callFunction('giveAdminClaim'),
                child: const Text('Assign Admin Role'),
              ),
              ElevatedButton(
                onPressed: () => _callFunction('removeAdminClaim'),
                child: const Text('Remove Admin Role'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
