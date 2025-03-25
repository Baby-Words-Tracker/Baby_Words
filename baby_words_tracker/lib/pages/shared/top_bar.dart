import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/util/config.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:baby_words_tracker/util/user_type.dart';
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
  Parent? _currParent;
  List<PopupMenuEntry<int>> _childNames = List.empty(growable: true);
  bool _isInvalidUserType = false;
  bool _isloadingChildren = true;

  @override
  void didChangeDependencies() {
    // use didChangeDependencies instead of initState because we depend on an inherited provider for our behavior
    super.didChangeDependencies();
    _loadParentAndChildren(context);
  }

  Future<void> _loadParentAndChildren(BuildContext context) async {
    if (_childNames.isNotEmpty) {
      // ensure we init only once, idk if this is buggy or not we'll see
      return;
    }
    // load parent
    Parent? currParent;
    if (context.watch<UserModelService>().userType == UserType.parent) {
      currParent = context.read<UserModelService>().parent!;
    } else {
      // if it is not a parent acccessing the page, short circuit and say invalid state
      setState(() {
        _isInvalidUserType = true; // handle invalid user type with this bool
      });
      return;
    }
    //load children

    List<PopupMenuEntry<int>> childNames = List.empty(growable: true);
      int i = 0;
      for (var childID in currParent.childIDs) {
        Child? currChild = await context.read<ChildDataService>().getChild(childID);
        if (currChild != null)
        {
          PopupMenuItem<int> currEntry = PopupMenuItem<int>(value: i, child: Text(currChild.name));
          childNames.add(currEntry);
          i++;
        }
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
    if (_isInvalidUserType || _isloadingChildren) {
      return AppBar(title: const Text("Loading..."), automaticallyImplyLeading: false, leading: null);
    }

    return AppBar(
      title: Text(widget.pageName),
      actions: [
        Text( ((_childNames[context.read<Config>().childIndex] as PopupMenuItem<int>).child as Text).data!, style: TextStyle(color: Colors.grey),),
        PopupMenuButton<int>(
          onSelected: (value) {
            if (value > -1 && value < (_currParent?.childIDs.length ?? -1)) {
              context.read<Config>().switchChild(value);
            }
          },
          itemBuilder: (BuildContext context) {
            if (_childNames.isEmpty) {
              return [
                PopupMenuItem(
                  value: -1,
                  child: Consumer<LocalizationService>(
                    builder: (context, localizationService, child) {
                      return Text(localizationService.translate("loading"));
            }
            )
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
