import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      destinations: const [
        NavigationDestination(
          icon: Icon(LucideIcons.home),
          selectedIcon: Icon(LucideIcons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.history),
          selectedIcon: Icon(LucideIcons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.settings),
          selectedIcon: Icon(LucideIcons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
