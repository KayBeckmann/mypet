import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/appointment_provider.dart';
import 'dashboard_screen.dart';
import 'pets_screen.dart';
import 'reminders_screen.dart';
import 'appointments_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MobilePetProvider>().load();
      context.read<MobileReminderProvider>().load();
      context.read<MobileAppointmentProvider>().load();
    });
  }

  static const _screens = [
    DashboardScreen(),
    PetsScreen(),
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
