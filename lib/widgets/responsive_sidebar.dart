import 'package:flutter/material.dart';
import '../config/app_localizations.dart';

class ResponsiveSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavigationItem> items;
  final List<Widget>? bottomItems;

  const ResponsiveSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.bottomItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return NavigationRail(
      extended: MediaQuery.of(context).size.width >= 1200,
      backgroundColor: theme.colorScheme.surface,
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.admin_panel_settings,
          size: 32,
        ),
      ),
      destinations: items.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon ?? item.icon),
          label: Text(l10n?.translate(item.labelKey) ?? item.label),
        );
      }).toList(),
      trailing: bottomItems != null
          ? Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: bottomItems!,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String labelKey;

  const NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.labelKey,
  });
}
