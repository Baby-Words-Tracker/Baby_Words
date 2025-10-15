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
  Size get preferredSize => const Size.fromHeight(96);
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
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: widget.preferredSize.height,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/lecs_mascot_64x64.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.pageName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ) ??
                      TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer2<LocalizationService, CurrentChildrenService>(
            builder:
                (context, localizationService, currentChildrenService, child) {
              final Color outlineColor =
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.6);
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
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: outlineColor, width: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          currentChildLabel,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_rounded),
          onPressed: () {
            Navigator.pushNamed(context, ProfilePage.routeName);
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
