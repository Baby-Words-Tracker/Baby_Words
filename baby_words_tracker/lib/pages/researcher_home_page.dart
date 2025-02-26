import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';


class ResearcherHomePage extends StatelessWidget {
  const ResearcherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Baby Word Tracker', style: TextStyle(color: Color(0xFF9E1B32), 
                                                         fontSize: 24,        
                                                         fontWeight: FontWeight.bold, 
                                                        ),
                          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) =>  ProfileScreen(
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
          )
        ],
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF9E1B32),
        child: Padding(
        padding: EdgeInsets.all(16.0), 
  ),
),
      body: const Center(
        child: Column(
          children: [
            SizedBox(
            height : 70,
          ),
            Text('Hello, Researcher!', style: TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            SizedBox(
            height : 60,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ 
            SizedBox(
            width : 60,
          ),
            ]
          ),
          SizedBox(
            height : 60,
          ),    
          ],
        ),
        
      ),
    );
  }
}