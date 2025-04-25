import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
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
      if (childNamesToChildIDs.isNotEmpty) {
        return childNamesToChildIDs;
      }
    }
    return List.empty();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
    children: [
      const CircleAvatar(
        radius: 24,
        backgroundImage: AssetImage('assets/LECS_mascot.png'),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(widget.pageName)),
    ],
  ),
      actions: [
        Consumer2<LocalizationService, CurrentChildrenService>(
          builder: (context, localizationService, currentChildrenService, child) {
            var childNamesToChildIDs =
                _loadParentAndChildren(currentChildrenService);
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  localizationService.translate("curr_child"),
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey),
                ),
                Builder(
                  builder: (context) {
                    Child? currChild = currentChildrenService.getCurrChild();
                    String text = '';
                    if (!currentChildrenService.dataRetrieved) {
                      text = "loading";
                    } else if (currChild != null) {
                      text = currChild.name;
                    } else {
                      text = "No-Children-nl-Yet";
                    }

                    return Consumer<LocalizationService>(
                      builder: (context, localizationService, children) {
                        return Text(
                          localizationService.translate(text),
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    );
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value != "") {
                      currentChildrenService.switchChild(value);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    if (childNamesToChildIDs.isEmpty) {
                      return [
                        PopupMenuItem(
                            value: "",
                            child: Consumer<LocalizationService>(
                                builder: (context, localizationService, child) {
                              return Text(localizationService
                                  .translate("No children yet"));
                            })),
                      ];
                    } else {
                      List<PopupMenuEntry<String>> itemList =
                          childNamesToChildIDs;
                      return itemList;
                    }
                  },
                ),
              ],
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
