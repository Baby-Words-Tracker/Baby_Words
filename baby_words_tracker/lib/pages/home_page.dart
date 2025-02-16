import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'add_text.dart'; // Import the second page
import 'stats.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Home Page"),
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
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF9E1B32),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
          IconButton(
            icon: const Icon(
                Icons.home,
                color: Colors.white,
                size: 40.0,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                  },
          ),
          IconButton(
            icon: const Icon(
                Icons.chat_bubble_outlined,
                color: Colors.white,
                size: 40.0,
            ),
            onPressed: () {
                  Navigator.pushNamed(context, '/addtext');
                  },
          ),
          IconButton(
            icon: const Icon(
                Icons.bar_chart_outlined,
                color: Colors.white,
                size: 40.0,
            ),
            onPressed: () {
                  Navigator.pushNamed(context, '/stats');
                  },
          ),
  ],
)
  ),
),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
            height : 70,
          ),
            const Text('Hello, User!', style: TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            const SizedBox(
            height : 60,
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/addtext');
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF828A8F), 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0), // Change the value to adjust the roundness
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30), 
              ), 
              child: const Column(
              mainAxisSize: MainAxisSize.min, // To keep the button size minimal
              children: [
                Icon(Icons.chat_bubble_outlined, color: Colors.white,
                size: 80.0,),
                SizedBox(height: 5), // Spacer between icon and text
                Text('Add Words', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              ],
            ),
            ),
            const SizedBox(
            height : 60,
          ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF828A8F), 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0), // Change the value to adjust the roundness
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30), 
              ), 
              child: const Column(
              mainAxisSize: MainAxisSize.min, // To keep the button size minimal
              children: [
                Icon(Icons.bar_chart_outlined, color: Colors.white,
                size: 80.0,),
                SizedBox(height: 5), // Spacer between icon and text
                Text('View Stats', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              ],
            ),
            ),   
          ],
        ),
      ),
    );
  }
}