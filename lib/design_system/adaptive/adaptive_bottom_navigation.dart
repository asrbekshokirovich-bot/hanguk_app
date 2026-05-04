import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveNavigationItem> items;

  const AdaptiveBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items.map((item) => NavigationDestination(
        icon: Icon(item.icon),
        label: item.label,
      )).toList(),
    );
  }
}

class AdaptiveNavigationItem {
  final String label;
  final IconData icon;

  const AdaptiveNavigationItem({
    required this.label,
    required this.icon,
  });
}
