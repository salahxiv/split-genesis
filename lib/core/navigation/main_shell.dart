import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/activity/screens/global_activity_screen.dart';
import '../../features/groups/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    GlobalActivityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0A0A0A).withOpacity(0.75)
                  : const Color(0xFFF2F2F7).withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A).withOpacity(0.5)
                      : const Color(0xFFD1D1D6).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TabItem(
                      icon: CupertinoIcons.rectangle_stack,
                      activeIcon: CupertinoIcons.rectangle_stack_fill,
                      label: 'Groups',
                      isActive: _selectedIndex == 0,
                      onTap: () => _setTab(0),
                    ),
                    _TabItem(
                      icon: CupertinoIcons.bolt,
                      activeIcon: CupertinoIcons.bolt_fill,
                      label: 'Activity',
                      isActive: _selectedIndex == 1,
                      onTap: () => _setTab(1),
                    ),
                    _TabItem(
                      icon: CupertinoIcons.gear,
                      activeIcon: CupertinoIcons.gear_solid,
                      label: 'Settings',
                      isActive: _selectedIndex == 2,
                      onTap: () => _setTab(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setTab(int index) {
    if (index != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() => _selectedIndex = index);
    }
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withAlpha(120);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
