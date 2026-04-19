import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/family_provider.dart';
import 'providers/permission_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/feeding_provider.dart';
import 'providers/media_provider.dart';
import 'providers/transfer_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/health_provider.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPetOwnerApp());
}

class MyPetOwnerApp extends StatefulWidget {
  const MyPetOwnerApp({super.key});

  @override
  State<MyPetOwnerApp> createState() => _MyPetOwnerAppState();
}

class _MyPetOwnerAppState extends State<MyPetOwnerApp> {
  final _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PetProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => FamilyProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PermissionProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedingProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MediaProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => WeightProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OwnerHealthProvider(api: _apiService),
        ),
      ],
      child: const _AppWithAuth(),
    );
  }
}

class _AppWithAuth extends StatefulWidget {
  const _AppWithAuth();

  @override
  State<_AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends State<_AppWithAuth> {
  bool _petsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final petProvider = context.read<PetProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();

    // Daten laden, sobald der Benutzer angemeldet ist
    if (authProvider.isAuthenticated && !_petsLoaded) {
      _petsLoaded = true;
      if (authProvider.isDemoMode) {
        petProvider.loadDemo();
      } else {
        petProvider.loadPets();
        appointmentProvider.load();
      }
    }
    if (!authProvider.isAuthenticated && _petsLoaded) {
      _petsLoaded = false;
    }

    final router = createRouter(authProvider);

    return MaterialApp.router(
      title: 'MyPet - Living Ledger',
      debugShowCheckedModeBanner: false,
      theme: LivingLedgerTheme.themeData,
      routerConfig: router,
    );
  }
}
