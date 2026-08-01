import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/health_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPetApp());
}

class MyPetApp extends StatefulWidget {
  const MyPetApp({super.key});

  @override
  State<MyPetApp> createState() => _MyPetAppState();
}

class _MyPetAppState extends State<MyPetApp> {
  final _api = ApiService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _api),
        ChangeNotifierProvider(create: (_) => MobileAuthProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => MobilePetProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => MobileReminderProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => MobileAppointmentProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => MobileMedicationProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => MobileWeightProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => MobileHealthProvider(api: _api)),
      ],
      child: MaterialApp(
        title: 'MyPet',
        debugShowCheckedModeBanner: false,
        // "Warm Care Narrative"-Designsystem (Google-Stitch-Mockup), dieselbe
        // Markensprache wie web_owner: Public Sans statt Inter, extra-weiche
        // 24px-Rundungen für Karten, sanfte statt harte Schatten.
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4CAF50),
            onPrimary: Colors.white,
            primaryContainer: Color(0xFF94F990),
            onPrimaryContainer: Color(0xFF002204),
            secondary: Color(0xFFFFB74D),
            onSecondary: Color(0xFF704800),
            tertiary: Color(0xFFFF5252),
            onTertiary: Colors.white,
            surface: Color(0xFFF7F9F7),
            onSurface: Color(0xFF2D3436),
            onSurfaceVariant: Color(0xFF3F4A3C),
            outline: Color(0xFF6F7A6B),
            outlineVariant: Color(0xFFBECAB9),
            error: Color(0xFFBA1A1A),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F9F7),
          textTheme: GoogleFonts.publicSansTextTheme(),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.publicSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<MobileAuthProvider>();
    if (auth.isAuthenticated) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
