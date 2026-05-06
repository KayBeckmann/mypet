import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/health_provider.dart';
import 'dashboard_screen.dart';
import 'pets_screen.dart';
import 'reminders_screen.dart';
import 'appointments_screen.dart';
import 'medications_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final petProv = context.read<MobilePetProvider>();
      final medProv = context.read<MobileMedicationProvider>();
      final weightProv = context.read<MobileWeightProvider>();
      final healthProv = context.read<MobileHealthProvider>();
      context.read<MobileReminderProvider>().load();
      context.read<MobileAppointmentProvider>().load();
      await petProv.load();
      for (final pet in petProv.pets) {
        medProv.loadForPet(pet.id);
        weightProv.loadForPet(pet.id);
        healthProv.loadForPet(pet.id);
      }
    });
  }

  static const _screens = [
    DashboardScreen(),
    PetsScreen(),
    MedicationsScreen(),
    RemindersScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final overdueCount = context.watch<MobileReminderProvider>().overdue.length;
    final pendingAppts = context
        .watch<MobileAppointmentProvider>()
        .appointments
        .where((a) => a.status == MobileApptStatus.requested)
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Übersicht',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: 'Meine Tiere',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Medikamente',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: overdueCount > 0,
              label: Text('$overdueCount'),
              child: const Icon(Icons.alarm_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: overdueCount > 0,
              label: Text('$overdueCount'),
              child: const Icon(Icons.alarm_rounded),
            ),
            label: 'Erinnerungen',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingAppts > 0,
              label: Text('$pendingAppts'),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingAppts > 0,
              label: Text('$pendingAppts'),
              child: const Icon(Icons.calendar_month_rounded),
            ),
            label: 'Termine',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
