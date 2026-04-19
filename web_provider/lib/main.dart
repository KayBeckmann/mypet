import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/organization_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/appointment_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPetProviderApp());
}

class MyPetProviderApp extends StatefulWidget {
  const MyPetProviderApp({super.key});

  @override
  State<MyPetProviderApp> createState() => _MyPetProviderAppState();
}

class _MyPetProviderAppState extends State<MyPetProviderApp> {
  final _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProviderAuthProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProviderOrganizationProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomersProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProviderAppointmentProvider(api: _apiService),
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
    final auth = context.watch<ProviderAuthProvider>();
    final router = createRouter(auth);
    return MaterialApp.router(
      title: 'MyPet Provider',
      debugShowCheckedModeBanner: false,
      theme: ProviderTheme.themeData,
      routerConfig: router,
    );
  }
}
