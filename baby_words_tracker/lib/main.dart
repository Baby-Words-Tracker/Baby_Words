import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Baby Word Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Color(0xFF828A8F),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(color: Color(0xFF9E1B32), 
                                                         fontSize: 24,        
                                                         fontWeight: FontWeight.bold, 
                                                        ),
                    ),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF9E1B32),
        child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Baby Word Tracker', style: TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center,
                ),
  ),
),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          const SizedBox(
            height : 40,
          ),
          const Center(
            child: Text(
              'Add Words',
              style: TextStyle(color: Colors.white, fontSize: 50)
            ),
          ),
          const SizedBox(
            height : 80,
            ),
          const Text(
            'My Child Said...',
            style: TextStyle(color: Colors.white, fontSize: 30)
          ),
          const TextField(
            decoration: InputDecoration(
            //border: OutlineInputBorder(),
            hintText: 'Enter word or sentence',
            filled: true,  
            fillColor: Color(0xFF9E1B32),
            ),
          ),
            Center(
              //submit button currently doesn't do anything
              child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF828A8F), // Button color
                      foregroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded rectangle shape
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Button size
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}
