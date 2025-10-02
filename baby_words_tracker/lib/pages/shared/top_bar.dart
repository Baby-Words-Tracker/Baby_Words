import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/pages/profile_page.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String pageName;

  const TopBar({super.key, required this.pageName});

  @override
  // ignore: library_private_types_in_public_api
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
          CircleAvatar(
            radius: 24,
            child: Image.asset(
              'assets/lecs_mascot_64x64.png',
              fit: BoxFit.contain,
              width: 38,
              height: 38,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.pageName)),
        ],
      ),
      actions: [
        Consumer2<LocalizationService, CurrentChildrenService>(
          builder:
              (context, localizationService, currentChildrenService, child) {
            final textColor =
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
            final childMenuItems =
                _loadParentAndChildren(currentChildrenService);
            final bool isLoading = !currentChildrenService.dataRetrieved;
            final Child? currentChild = currentChildrenService.getCurrChild();
            final String currentChildLabel = isLoading
                ? localizationService.translate('loading')
                : currentChild?.name ??
                    localizationService.translate('select_child');

            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value.isNotEmpty) {
                  currentChildrenService.switchChild(value);
                }
              },
              itemBuilder: (BuildContext context) {
                if (childMenuItems.isEmpty) {
                  return [
                    PopupMenuItem(
                      value: '',
                      child: Text(
                        localizationService.translate('No children yet'),
                      ),
                    ),
                  ];
                }
                return childMenuItems;
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: textColor.withValues()),
                  borderRadius: BorderRadius.circular(24),
                ),
                constraints: const BoxConstraints(maxWidth: 160),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentChildLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.expand_more,
                      color: textColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, ProfilePage.routeName);
          },
        )
      ],
      automaticallyImplyLeading: false,
      leading: null,
    );
  }
}
