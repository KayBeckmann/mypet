import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPetOwnerApp());
}

class MyPetOwnerApp extends StatelessWidget {
  const MyPetOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PetProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final router = createRouter(authProvider);

          return MaterialApp.router(
            title: 'MyPet - Living Ledger',
            debugShowCheckedModeBanner: false,
            theme: LivingLedgerTheme.themeData,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
