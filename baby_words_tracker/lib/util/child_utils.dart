import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> addChildToCurrParent(BuildContext context, String name, DateTime bday) async{
  Parent? currParent = getCurrentParent(context);
  if (currParent != null){
    Child? child = await context.read<ChildDataService>().createChild(DateTime.now(), name, 0, [currParent.id]);
    context.read<ParentDataService>().addChildToParent(currParent.id, child?.id ?? "aaaa");
  }
}

Column childAddingFeature(BuildContext context, TextEditingController nameController, TextEditingController dateController){
  return Column(
    children: [
      const Text("Add a Child:"), //FIXME: ugly
      TextField(
        controller: nameController,
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'Choose Name..',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,  
          fillColor: Color(0xFF9E1B32),
        ),
      ),
      TextField(
        controller: dateController,
        onTap: () => selectDate(context, dateController),
        readOnly: true,
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'Tap to Choose Birthday..',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,  
          fillColor: Color(0xFF9E1B32),
        ),
      ),
      Center(
        child: OutlinedButton(
          onPressed: () {
            if (nameController.text != "" && dateController.text != "") //add the word to the child with the id, or the default testing child if no input
            {
              //add child
              addChildToCurrParent(context, nameController.text, DateTime.parse(dateController.text));
              //added indicator
              showAlertMessage(context, "Child Added!", "Successfully added your child!");
              
            } else {
              //failed to add indicator //FIXME: better error checking
              showAlertMessage(context, "Child Add Failed", "Failed to add yoour child, please try again.");
            }
            nameController.clear();
            dateController.clear();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF828A8F), 
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
  );
}

//testing child id: gz1Qe32xJcF0oRGmhw7f
Future<void> addWordToChild(String word, ChildDataService childService, WordDataService wordService, WordTrackerDataService trackerService, {String id = "gz1Qe32xJcF0oRGmhw7f"})
async {
  if (await childService.getChild(id) == null)
  {
    return;
  }
  //FIXME: implement language, part of speech, defn, spellcheck
  /*Word wordObject =*/ await wordService.createWord(word, [LanguageCode.en], PartOfSpeech.noun, "testWord");
  trackerService.createWordTracker(id, word, DateTime.now());
}

Column wordAddingFeature(BuildContext context, TextEditingController wordTextController, TextEditingController idController, WordTrackerDataService trackerService){
  return Column(
    children: [
      TextField(
        controller: wordTextController,
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'Add this word to..',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,  
          fillColor: Color(0xFF9E1B32),
        ),
      ),
      TextField(
        controller: idController,
        decoration: const InputDecoration(
          //border: OutlineInputBorder(),
          hintText: 'child with id.. [or leave empty for testing child]',
          hintStyle: TextStyle(color: Colors.white),
          filled: true,  
          fillColor: Color(0xFF9E1B32),
        ),
      ),
      Center(
        child: OutlinedButton(
          onPressed: () {
            if (idController.text != "") //add the word to the child with the id, or the default testing child if no input
            {
              addWordToChild(wordTextController.text, context.read<ChildDataService>(), context.read<WordDataService>(),  trackerService, id: idController.text);
            } else {
              addWordToChild(wordTextController.text, context.read<ChildDataService>(), context.read<WordDataService>(),  trackerService);
            }
            wordTextController.clear();
            idController.clear();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF828A8F), 
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
  );
}