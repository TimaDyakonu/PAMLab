import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/item_details_screen.dart';
import 'screens/new_item_screen.dart';
import 'screens/my_items_screen.dart';
import 'screens/my_purchases_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_shell.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewItemScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ItemDetailsScreen(itemId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/my-items',
            builder: (context, state) => const MyItemsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewItemScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ItemDetailsScreen(itemId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const MyPurchasesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ItemDetailsScreen(itemId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
);

