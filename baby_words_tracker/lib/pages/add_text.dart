import 'package:flutter/material.dart';

class AddTextPage extends StatefulWidget {
  const AddTextPage({super.key, required this.title});

  final String title;

  @override
  State<AddTextPage> createState() => _AddTextPageState();
}

class _AddTextPageState extends State<AddTextPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> parsedWords = [];

  void _parseWords() {
    String text = _controller.text;
    parsedWords = text.split(' ');   
    setState(() {});
  }
  
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
        title: const Text('Baby Words Tracker', style: TextStyle(color: Color(0xFF9E1B32), 
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          const SizedBox(
            height : 60,
          ),
          const Center(
            child: Text(
              'Add Words',
              style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(
            height : 80,
            ),
          const Text(
            'My Child Said...',
            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)
          ),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
            hintText: 'Enter word or sentence',
            hintStyle: TextStyle(color: Colors.white),
            filled: true,  
            fillColor: Color(0xFF9E1B32),
            ),
          ),
            Center(
              child: OutlinedButton(
                onPressed: _parseWords,
                style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFF828A8F), 
                foregroundColor: Colors.white,        
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),  
            ),
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0), 
            ),
            child: const Text('Submit', style: TextStyle(fontSize: 18)),
)
            ),
          ],
        ),
      ),
      
    );
  }
}