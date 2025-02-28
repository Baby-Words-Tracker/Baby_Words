
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/util/config.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


 
class TopBar extends StatefulWidget implements PreferredSizeWidget {
   final String pageName;

   TopBar({super.key, required this.pageName});

   @override
  _TopBarState createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  Parent? _currParent;
  List<PopupMenuEntry<int>> _childNames = List.empty(growable: true);
  bool _isInvalidUserType = false;
  bool _isloadingChildren = true;

  @override
  void didChangeDependencies() { // use didChangeDependencies instead of initState because we depend on an inherited provider for our behavior
    super.didChangeDependencies();
    _loadParentAndChildren(context);
  }

  Future<void> _loadParentAndChildren(BuildContext context) async {
    if (_childNames.isNotEmpty){ // ensure we init only once, idk if this is buggy or not we'll see
      return;
    }
    // load parent
    Parent? currParent;
    if (context.watch<UserModelService>().userType == UserType.parent)
    {
      currParent = context.read<UserModelService>().parent!; 
    } else { // if it is not a parent acccessing the page, short circuit and say invalid state
      setState(() {
        _isInvalidUserType = true; // handle invalid user type with this bool
      });
      return;
    }
    //load children
    ChildDataService childService = context.read<ChildDataService>();
    List<PopupMenuEntry<int>> childNames = List.empty(growable: true);
    int currIndex = 0;
    for (String childID in currParent.childIDs ?? []) {
      String currChildName = ((await childService.getChild(childID))?.name ?? "Failed to fetch child name");
      childNames.add(
        PopupMenuItem(
          value: currIndex,
          child: Text(currChildName),
        )
      );
      currIndex++;
    }
    setState(() {
        _currParent = currParent;
        _childNames = childNames;
        _isInvalidUserType = false;
        _isloadingChildren = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInvalidUserType) {
      return AppBar(title: const Text("Invalid user Type"));
    } else if (_isloadingChildren) {
      return AppBar(title: const Text("Loading..."));
    }

    return AppBar(
      title: Text(widget.pageName),
      actions: [
        PopupMenuButton<int>(
          onSelected: (value) {
            if (value > -1 && value < (_currParent?.childIDs.length ?? -1))
            {
              context.read<Config>().switchChild(value);
            }
          },
          itemBuilder: (BuildContext context) {
            if (_childNames.isEmpty) {
              return [
              const PopupMenuItem(
                value: -1,
                child: Text("Loading Children..."),
              ),
            ];
            } else {
              return _childNames;
            }
            
          },
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, '/profilepage');
          },
        )
      ],
      automaticallyImplyLeading: true,
    );
  }
}



    

//   return AppBar(
//         title: Text(pageName),
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               // Handle selection
//               print("Selected: $value");
//             },
//             itemBuilder: (BuildContext context) {
//               ChildDataService childService = context.read<ChildDataService>();
//               List<String> childNames = List.empty(growable: true);
//               for (String childID in currParent.childIDs) {
//                 childNames.add((await childService.getChild(childID)).name);
//               }
//               return [
//                 const PopupMenuItem(
//                   value: "Option 1",
//                   child: Text("Option 1"),
//                 ),
//                 const PopupMenuItem(
//                   value: "Option 2",
//                   child: Text("Option 2"),
//                 ),
//                 const PopupMenuItem(
//                   value: "Option 3",
//                   child: Text("Option 3"),
//                 ),
//               ];
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.person),
//             onPressed: () {
//               Navigator.pushNamed(context, '/profilepage');
//             },
//           )
//         ],
//         automaticallyImplyLeading: true,
//       );
// }
