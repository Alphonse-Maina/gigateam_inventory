import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';

class _Destination {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Destination(this.path, this.icon, this.selectedIcon, this.label);
}

const _destinations = [
  _Destination('/', Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
  _Destination('/stores', Icons.storefront_outlined, Icons.storefront_rounded, 'Stores'),
  _Destination('/search', Icons.search_outlined, Icons.search_rounded, 'Search'),
  _Destination('/requests', Icons.swap_horiz_outlined, Icons.swap_horiz_rounded, 'Requests'),
];

const _adminOnlyDestination = _Destination('/logs', Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Logs');

/// Wraps every authenticated screen. Uses a bottom nav bar under 700px
/// (phones) and a nav rail beside the content above that (tablet/desktop) —
/// same codebase, same Firebase data, adapted layout.
class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  List<_Destination> _destinationsFor(AppUser? user) {
    final list = [..._destinations];
    if (user?.isAdmin ?? false) list.add(_adminOnlyDestination);
    return list;
  }

  int _indexForLocation(String location, List<_Destination> dests) {
    final i = dests.indexWhere((d) => d.path == location);
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final unread = ref.watch(unreadNotificationCountProvider);
    final dests = _destinationsFor(user);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location, dests);
    final isWide = MediaQuery.of(context).size.width >= 700;

    final notificationButton = badges.Badge(
      showBadge: unread > 0,
      badgeContent: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
      badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.danger),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.go('/notifications'),
      ),
    );

    if (!isWide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(dests[currentIndex].label),
          actions: [
            notificationButton,
            IconButton(icon: const Icon(Icons.person_outline_rounded), onPressed: () => context.go('/profile')),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(child: child),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(dests[i].path),
          items: [
            for (final d in dests)
              BottomNavigationBarItem(icon: Icon(d.icon), activeIcon: Icon(d.selectedIcon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => context.go(dests[i].path),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.shield_moon_rounded, color: AppColors.accent),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  notificationButton,
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: IconButton(
                    icon: const CircleAvatar(radius: 16, child: Icon(Icons.person_outline_rounded, size: 18)),
                    onPressed: () => context.go('/profile'),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in dests)
                NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}
