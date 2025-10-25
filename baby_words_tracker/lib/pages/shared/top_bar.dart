import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String? pageName;
  final bool showPageTitle;

  const TopBar({
    super.key,
    this.pageName,
    this.showPageTitle = true,
  });

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
    final localizationService = context.watch<LocalizationService>();
    final showPageTitle =
        widget.showPageTitle && (widget.pageName?.trim().isNotEmpty ?? false);
    final Color barColor = theme.colorScheme.secondaryContainer;
    final Color onBarColor = theme.colorScheme.onSecondaryContainer;
    final brandTranslation = localizationService.translate('word_buds').trim();
    final String brandLabel =
        brandTranslation.isEmpty ? 'WordBuds' : brandTranslation;

    return AppBar(
      backgroundColor: barColor,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brandLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onBarColor.withOpacity(0.85),
                        ) ??
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onBarColor.withOpacity(0.85),
                        ),
                  ),
                  if (showPageTitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.pageName!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: onBarColor,
                          ) ??
                          TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: onBarColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/lecs_mascot_64x64.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Consumer2<LocalizationService, CurrentChildrenService>(
                  builder: (context, localizationService,
                      currentChildrenService, child) {
                    final Color outlineColor = onBarColor.withOpacity(0.32);
                    final childMenuItems =
                        _loadParentAndChildren(currentChildrenService);
                    final bool isLoading =
                        !currentChildrenService.dataRetrieved;
                    final Child? currentChild =
                        currentChildrenService.getCurrChild();
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
                                localizationService
                                    .translate('No children yet'),
                              ),
                            ),
                          ];
                        }
                        return childMenuItems;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onBarColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.expand_more,
                              color: onBarColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
