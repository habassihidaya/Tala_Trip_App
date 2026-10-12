import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<NavigationDestination> destinations;
  final VoidCallback? onCenterAction;
  final String centerActionTooltip;

  const AppNavigationShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
    this.onCenterAction,
    this.centerActionTooltip = 'Add',
  });

  void _selectTab(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the selected tab returns to its first page.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCenterAction = onCenterAction != null;
    final centerIndex = destinations.length ~/ 2;

    final navigationItems = <Widget>[...destinations];

    if (hasCenterAction) {
      navigationItems.insert(
        centerIndex,
        Center(
          child: IconButton.filled(
            onPressed: onCenterAction,
            tooltip: centerActionTooltip,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(52, 52),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.add, size: 28),
          ),
        ),
      );
    }

    // Account for the extra button when highlighting the selected tab.
    final branchIndex = navigationShell.currentIndex;
    final selectedIndex = hasCenterAction && branchIndex >= centerIndex
        ? branchIndex + 1
        : branchIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (!hasCenterAction) {
            _selectTab(index);
            return;
          }

          // The center button handles its own action.
          if (index == centerIndex) return;

          final targetBranch = index > centerIndex ? index - 1 : index;

          _selectTab(targetBranch);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: navigationItems,
      ),
    );
  }
}
