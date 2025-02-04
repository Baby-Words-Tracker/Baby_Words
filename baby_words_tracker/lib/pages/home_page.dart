import 'package:flutter/material.dart';
import 'addtext.dart'; // Import the second page
import 'stats.dart';


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Page")),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
              child: Text("Go to Stats Page"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/addtext');
              },
              child: Text("Go to Add Text Page"),
            ),
            
          ],
        ),
      ),
    );
  }
}