import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/organization_provider.dart';
import 'providers/patients_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/media_provider.dart';
import 'providers/notes_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPetVetApp());
}

class MyPetVetApp extends StatefulWidget {
  const MyPetVetApp({super.key});

  @override
  State<MyPetVetApp> createState() => _MyPetVetAppState();
}

class _MyPetVetAppState extends State<MyPetVetApp> {
  final _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VetAuthProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OrganizationProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientsProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicalProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => VetAppointmentProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => VetMediaProvider(api: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => VetNotesProvider(api: _apiService),
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
    final auth = context.watch<VetAuthProvider>();
    final router = createRouter(auth);
    return MaterialApp.router(
      title: 'MyPet Vet',
      debugShowCheckedModeBanner: false,
      theme: VetTheme.themeData,
      routerConfig: router,
    );
  }
}
