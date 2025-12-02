import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/admin_page.dart';
import 'package:baby_words_tracker/pages/researcher_home_page.dart';
import 'package:baby_words_tracker/util/download_as_csv.dart' as download_csv;
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/user_roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

class ResearcherAdminPage extends StatefulWidget {
  static const routeName = '/researcher-admin';
  const ResearcherAdminPage({super.key});

  @override
  State<ResearcherAdminPage> createState() => _ResearcherAdminPageState();
}

class _ResearcherAdminPageState extends State<ResearcherAdminPage> {
  final FirestoreDataTableSource _dataSource = FirestoreDataTableSource();

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (Provider.of<LocalizationService>(context, listen: false)
            .getLocaleCode() !=
        LanguageCode.en) {
      Provider.of<LocalizationService>(context, listen: false)
          .changeLocale(LanguageCode.en);
    }

    final theme = Theme.of(context);
    final localizationService = context.watch<LocalizationService>();
    final Color barColor = theme.colorScheme.secondaryContainer;
    final Color onBarColor = theme.colorScheme.onSecondaryContainer;
    final brandTranslation = localizationService.translate('word_buds').trim();
    final String brandLabel =
        brandTranslation.isEmpty ? 'WordBuds' : brandTranslation;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: barColor,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brandLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onBarColor.withOpacity(0.85),
                        ) ??
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onBarColor.withOpacity(0.85),
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/lecs_mascot_64x64.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),           
            //const SizedBox(width: 8),
            //const Expanded(child: Text("WordBuds"))
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
              )
              )
          ],
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ResearcherHomePage(
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text('User Profile'),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      })
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<AuthenticationService>(
            builder: (context, authenticationService, config) {
              if (authenticationService.roles.contains(UserRole.admin)) {
                return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () {
                      Navigator.pushNamed(context, AdminPage.routeName);
                    });
              } else {
                return const SizedBox(
                  width: 5,
                );
              }
            },
          ),
        ],
        //automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
             // height: screenHeight,
              child: Column(children: [
                 Text('Users',
                    // style: TextStyle(
                    //   color: Color(0xFF9E1B32),
                    //   fontSize: 24,
                    //   fontWeight: FontWeight.bold,
                    style: theme.textTheme.titleLarge?.copyWith(
                      //fontWeight: FontWeight.w700,
                    ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(height: 550, child: SingleChildScrollView(child: SizedBox( width: 800, height: 600, child: UserList()))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleDropdown extends StatefulWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _RoleDropdown({
    required this.currentValue,
    required this.onChanged,
    super.key,
  });

  @override
  State<_RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<_RoleDropdown> {
  late String selected;

  @override
  void initState(){
    super.initState();
    selected = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selected,
      items: const [
        DropdownMenuItem(value: 'parent', child: Text('Parent')),
        DropdownMenuItem(value: 'researcher', child: Text('Researcher')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => selected = value);
        widget.onChanged(value);
      }
    );
  }
}

Widget buildUserCard(BuildContext context, DocumentSnapshot userDoc) {
  final data = userDoc.data() as Map<String, dynamic>;
  final userId = userDoc.id;
  var role = data['role'].toString().toUpperCase() ?? "N/A";

  return Card(
    margin: EdgeInsets.all(16),
    child: ExpansionTile(
      title: Text(data['email'] ?? 'No email'),
      subtitle: Text(role),
      children: [
        Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: 
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Email Verified: ${data['emailVerified'].toString().toUpperCase()}'),
                  Text('Survey Completed: ${data['surveyCompleted'].toString().toUpperCase()}'),
                  Text('Two Factor Enabled: ${data['twoFactorEnabled'].toString().toUpperCase()}'),
                  Text('Status: ${data['status'].toString().toUpperCase()}'),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: 
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [ _RoleDropdown(currentValue: data['role'], onChanged: (value) async {
                await FirebaseFirestore.instance.collection('UserProfile').doc(userId).update({'role' : value});
            })]))
          ]
        )
      ]
    )
  );
}

class UserList extends StatelessWidget {
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('UserProfile').snapshots(),
      builder: (context, snapshot) {
       
       final users = snapshot.data!.docs;
       return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return buildUserCard(context, users[index]);
        },
       );
      },
    );
  }
}
