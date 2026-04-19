import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/users_screen.dart';
import '../screens/create_user_screen.dart';
import '../screens/user_detail_screen.dart';

GoRouter createRouter(AdminAuthProvider authProvider) {
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
      GoRoute(path: '/', builder: (_, __) => const UsersScreen()),
      GoRoute(path: '/users/create', builder: (_, __) => const CreateUserScreen()),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) =>
            UserDetailScreen(userId: state.pathParameters['id']!),
      ),
    ],
  );
}
