import 'package:flutter/material.dart';
import 'add_text.dart'; // Import the second page
import 'stats.dart';


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Baby Word Tracker', style: TextStyle(color: Color(0xFF9E1B32), 
                                                         fontSize: 24,        
                                                         fontWeight: FontWeight.bold, 
                                                        ),
                    ),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF9E1B32),
        child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
          Icon(
              Icons.home,
              color: Colors.white,
              size: 40.0,
              ),
          Icon(
              Icons.chat_bubble_outlined,
              color: Colors.white,
              size: 40.0,
          ),
          Icon(
              Icons.bar_chart_outlined,
              color: Colors.white,
              size: 40.0,
          ),
  ],
)
  ),
),
      body: Center(
        child: Column(
          children: [
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