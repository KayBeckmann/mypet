import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/organization_screen.dart';
import '../screens/members_screen.dart';
import '../screens/patients_screen.dart';
import '../screens/patient_detail_screen.dart';
import '../widgets/app_shell.dart';

GoRouter createRouter(VetAuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final loc = state.uri.toString();
      if (!isAuthenticated && loc != '/login') return '/login';
      if (isAuthenticated && loc == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => VetAppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/organization',
              builder: (_, __) => const OrganizationScreen()),
          GoRoute(
              path: '/members', builder: (_, __) => const MembersScreen()),
          GoRoute(
              path: '/patients', builder: (_, __) => const PatientsScreen()),
          GoRoute(
            path: '/patients/:id',
            builder: (_, state) => PatientDetailScreen(
                petId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}
