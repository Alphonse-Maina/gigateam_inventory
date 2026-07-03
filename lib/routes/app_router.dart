import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/stores/store_list_screen.dart';
import '../screens/stores/store_detail_screen.dart';
import '../screens/inventory/item_detail_screen.dart';
import '../screens/inventory/item_form_screen.dart';
import '../screens/search/global_search_screen.dart';
import '../screens/requests/requests_screen.dart';
import '../screens/requests/request_form_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/logs/logs_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final signedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!signedIn && !loggingIn) return '/login';
      if (signedIn && loggingIn) return '/';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/stores', builder: (context, state) => const StoreListScreen()),
          GoRoute(
            path: '/stores/:storeId',
            builder: (context, state) => StoreDetailScreen(storeId: state.pathParameters['storeId']!),
          ),
          GoRoute(path: '/search', builder: (context, state) => const GlobalSearchScreen()),
          GoRoute(path: '/requests', builder: (context, state) => const RequestsScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: '/logs', builder: (context, state) => const LogsScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/item/:storeId/:itemId',
        builder: (context, state) => ItemDetailScreen(
          storeId: state.pathParameters['storeId']!,
          itemId: state.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        path: '/item/:storeId/new',
        builder: (context, state) => ItemFormScreen(storeId: state.pathParameters['storeId']!),
      ),
      GoRoute(
        path: '/item/:storeId/:itemId/edit',
        builder: (context, state) => ItemFormScreen(
          storeId: state.pathParameters['storeId']!,
          itemId: state.pathParameters['itemId'],
        ),
      ),
      GoRoute(
        path: '/request/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RequestFormScreen(prefill: extra);
        },
      ),
    ],
  );
});

/// Bridges a Riverpod stream into a Listenable so go_router re-evaluates
/// `redirect` whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
