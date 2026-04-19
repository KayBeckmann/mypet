import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/users_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPetAdminApp());
}

class MyPetAdminApp extends StatefulWidget {
  const MyPetAdminApp({super.key});

  @override
  State<MyPetAdminApp> createState() => _MyPetAdminAppState();
}

class _MyPetAdminAppState extends State<MyPetAdminApp> {
  final _apiService = ApiService();
  late final AdminAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AdminAuthProvider(api: _apiService);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(api: _apiService),
        ),
      ],
      child: const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final router = createRouter(auth);
    return MaterialApp.router(
      title: 'MyPet Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.themeData,
      routerConfig: router,
    );
  }
}
