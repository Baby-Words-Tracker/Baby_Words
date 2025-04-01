import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String pageName;

  const TopBar({super.key, required this.pageName});

  @override
  _TopBarState createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  List<PopupMenuEntry<String>> _childNamesToChildIDs = List.empty(growable: true);
  bool _isInvalidUserType = false;
  bool _isloadingChildren = true;
  String _currName = "Loading..";

  @override
  void didChangeDependencies() {
    // use didChangeDependencies instead of initState because we depend on an inherited provider for our behavior
    super.didChangeDependencies();
    _loadParentAndChildren(context);
  }

  Future<void> _loadParentAndChildren(BuildContext context) async {
    

    // load parent (night not even be necessary anymore)
    // // Parent? currParent;
    // // if (context.watch<UserModelService>().userType == UserType.parent) {
    // //   currParent = context.read<UserModelService>().parent!;
    // // } else {
    // //   // if it is not a parent acccessing the page, short circuit and say invalid state
    // //   setState(() {
    // //     _isInvalidUserType = true; // handle invalid user type with this bool
    // //     _currName = "Unable to find current child";
    // //   });
    // //   return;
    // // }
    List<Child>? children = context.watch<CurrentChildrenService>().getCurrChildren(context);
    if (_childNamesToChildIDs.isEmpty) {
    List<PopupMenuEntry<String>> childNamesToChildIDs = List.empty(growable: true);
      if (children != null)
      {
        childNamesToChildIDs = children.map((entry) => PopupMenuItem<String>(
          value: entry.id,
          child: Text(entry.name),
        ))
        .toList();
      }
      if (childNamesToChildIDs.isNotEmpty && children != null){
        setState(() {
          _childNamesToChildIDs = childNamesToChildIDs; 
          _currName = children[context.read<CurrentChildrenService>().getChildIndex()].name;
          _isInvalidUserType = false;
          _isloadingChildren = false;
        });
        return;
      } else {
        setState(() {
          _isloadingChildren = true;
          return;
        });
      }
    } else {
      if (children != null){
        setState(() {
          _currName = children[context.read<CurrentChildrenService>().getChildIndex()].name;
        });
      }
    }
    // all i need to do is get the name of the current child the above code makes the menu fine in 1 query
    // so im thinking of decoupling getting the children from generating the popupmenuitems, so that i can grab the current childs name,

    //load current child name
  }

  @override
  Widget build(BuildContext context) {
    if (_isInvalidUserType || _isloadingChildren) {
      return AppBar(title: const Text("Loading..."), automaticallyImplyLeading: false, leading: null);
    }

    return AppBar(
      title: Text(widget.pageName),
      actions: [
        Text( _currName, style: TextStyle(color: Colors.grey),),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value != "") {
              context.read<CurrentChildrenService>().switchChild(value);
                  setState(() {
                    Child? currChild = context.read<CurrentChildrenService>().getCurrChild(context);
                    if (currChild != null)
                    {
                      _currName = currChild.name;
                    } else {
                      _currName = "Unable to find current child";
                    }

                    
                  });
            }
          },
          itemBuilder: (BuildContext context) {
            if (_childNamesToChildIDs.isEmpty) {
              return [
                PopupMenuItem(
                  value: "",
                  child: Consumer<LocalizationService>(
                    builder: (context, localizationService, child) {
                      return Text(localizationService.translate("loading"));
            }
            )
            ),
              ];
            } else {
              List<PopupMenuEntry<String>> itemList = _childNamesToChildIDs;
              return itemList;
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
      automaticallyImplyLeading: false,
      leading: null,
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
