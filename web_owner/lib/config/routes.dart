import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/animals_screen.dart';
import '../screens/animal_detail_screen.dart';
import '../screens/add_animal_screen.dart';
import '../screens/edit_animal_screen.dart';
import '../screens/feeding_screen.dart';
import '../screens/records_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/families_screen.dart';
import '../screens/permissions_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../widgets/app_shell.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.uri.toString() == '/login' ||
          state.uri.toString() == '/register';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // App routes (with shell)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/animals',
            builder: (context, state) => const AnimalsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddAnimalScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AnimalDetailScreen(petId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EditAnimalScreen(petId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/families',
            builder: (context, state) => const FamiliesScreen(),
          ),
          GoRoute(
            path: '/permissions',
            builder: (context, state) => const PermissionsScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/feeding',
            builder: (context, state) => const FeedingScreen(),
          ),
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/records',
            builder: (context, state) => const RecordsScreen(),
          ),
        ],
      ),
    ],
  );
}
