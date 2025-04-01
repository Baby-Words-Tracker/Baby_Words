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
  String _currName = "Loading..";

  @override
  void didChangeDependencies() {
    // use didChangeDependencies instead of initState because we depend on an inherited provider for our behavior
    super.didChangeDependencies();
  }

  List<PopupMenuEntry<String>> _loadParentAndChildren(
      CurrentChildrenService currentChildrenService) {
    List<Child>? children = currentChildrenService.getCurrChildren();
    List<PopupMenuEntry<String>> childNamesToChildIDs =
        List.empty(growable: true);
    if (children != null) {
      childNamesToChildIDs = children
          .map((entry) => PopupMenuItem<String>(
                value: entry.id,
                child: Text(entry.name),
              ))
          .toList();
      if (childNamesToChildIDs.isNotEmpty && children != null) {
        return childNamesToChildIDs;
      } else {
        return List.empty();
      }
    } else {
      return List.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.pageName),
      actions: [
        Text(
          _currName,
          style: TextStyle(color: Colors.grey),
        ),
        Consumer<CurrentChildrenService>(
          builder: (context, currentChildrenService, config) {
            var childNamesToChildIDs = _loadParentAndChildren(currentChildrenService);

            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value != "") {
                  currentChildrenService.switchChild(value);
                  setState(() {
                    Child? currChild = currentChildrenService.getCurrChild();
                    if (currChild != null) {
                      _currName = currChild.name;
                    } else {
                      _currName = "Unable to find current child";
                    }
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                if (childNamesToChildIDs.isEmpty) {
                  return [
                    PopupMenuItem(
                        value: "",
                        child: Consumer<LocalizationService>(
                            builder: (context, localizationService, child) {
                          return Text(localizationService.translate("loading"));
                        })),
                  ];
                } else {
                  List<PopupMenuEntry<String>> itemList = childNamesToChildIDs;
                  return itemList;
                }
              },
            );
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
