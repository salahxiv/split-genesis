import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/activity/providers/activity_provider.dart';
import '../../features/activity/screens/global_activity_screen.dart';
import '../../features/groups/providers/groups_provider.dart';
import '../../features/groups/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity badge provider — counts unseen activity entries across all groups
// ─────────────────────────────────────────────────────────────────────────────

const _kLastSeenActivityKey = 'last_seen_activity_ts';

final _lastSeenTimestampProvider =
    StateNotifierProvider<_LastSeenNotifier, DateTime?>((ref) {
  return _LastSeenNotifier();
});

class _LastSeenNotifier extends StateNotifier<DateTime?> {
  _LastSeenNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastSeenActivityKey);
    if (ms != null) {
      state = DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }

  Future<void> markSeen() async {
    final now = DateTime.now();
    state = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSeenActivityKey, now.millisecondsSinceEpoch);
  }
}

final activityBadgeCountProvider = Provider<int>((ref) {
  final groupsAsync = ref.watch(groupsProvider);
  final lastSeen = ref.watch(_lastSeenTimestampProvider);

  return groupsAsync.when(
    data: (groups) {
      int count = 0;
      for (final group in groups) {
        final activitiesAsync = ref.watch(activityProvider(group.id));
        activitiesAsync.whenData((entries) {
          for (final e in entries) {
            if (lastSeen == null || e.timestamp.isAfter(lastSeen)) {
              count++;
            }
          }
        });
      }
      return count;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Main Shell
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Per-tab animation controllers for spring icon bounce
  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconAnimations;

  static const List<Widget> _pages = [
    HomeScreen(),
    GlobalActivityScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      3,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    _iconAnimations = _iconControllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.28)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.28, end: 0.9)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 40,
        ),
      ]).animate(controller);
    }).toList();

    // Animate the initial tab
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;

    HapticFeedback.selectionClick();

    // Mark activity as seen when switching to activity tab
    if (index == 1) {
      ref.read(_lastSeenTimestampProvider.notifier).markSeen();
    }

    setState(() => _selectedIndex = index);

    // Spring animation on the newly selected icon
    _iconControllers[index]
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final badgeCount = ref.watch(activityBadgeCountProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(12),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          destinations: [
            // Groups tab
            NavigationDestination(
              icon: _AnimatedTabIcon(
                animation: _iconAnimations[0],
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                isSelected: _selectedIndex == 0,
              ),
              selectedIcon: _AnimatedTabIcon(
                animation: _iconAnimations[0],
                icon: const Icon(Icons.home),
                selectedIcon: const Icon(Icons.home),
                isSelected: true,
              ),
              label: 'Groups',
            ),
            // Activity tab with badge
            NavigationDestination(
              icon: _AnimatedTabIcon(
                animation: _iconAnimations[1],
                icon: Icon(
                  Icons.bolt_outlined,
                  color: _selectedIndex == 1
                      ? theme.colorScheme.primary
                      : null,
                ),
                selectedIcon: const Icon(Icons.bolt),
                isSelected: _selectedIndex == 1,
                badge: badgeCount > 0 && _selectedIndex != 1
                    ? badgeCount
                    : null,
              ),
              selectedIcon: _AnimatedTabIcon(
                animation: _iconAnimations[1],
                icon: const Icon(Icons.bolt),
                selectedIcon: const Icon(Icons.bolt),
                isSelected: true,
              ),
              label: 'Activity',
            ),
            // Settings tab
            NavigationDestination(
              icon: _AnimatedTabIcon(
                animation: _iconAnimations[2],
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                isSelected: _selectedIndex == 2,
              ),
              selectedIcon: _AnimatedTabIcon(
                animation: _iconAnimations[2],
                icon: const Icon(Icons.settings),
                selectedIcon: const Icon(Icons.settings),
                isSelected: true,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Tab Icon — spring scale on selection + optional badge
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedTabIcon extends StatelessWidget {
  final Animation<double> animation;
  final Widget icon;
  final Widget selectedIcon;
  final bool isSelected;
  final int? badge;

  const _AnimatedTabIcon({
    required this.animation,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child = AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.scale(
        scale: animation.value,
        child: child,
      ),
      child: isSelected ? selectedIcon : icon,
    );

    if (badge != null && badge! > 0) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: -4,
            right: -4,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, _) => Transform.scale(
                scale: value,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge! > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return child;
  }
}
