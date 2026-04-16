import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../widgets/pet_card.dart';
import '../widgets/appointment_card.dart';
import '../widgets/quick_action_chip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final userName = auth.user?.name ?? 'Tierfreund';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Content Area ──
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  _greeting(userName),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Alles im Blick auf dem Living Ledger. '
                  'Deine Tiere sind heute bestens versorgt.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    QuickActionChip(
                      icon: Icons.book_rounded,
                      label: 'Tagebuch',
                    ),
                    QuickActionChip(
                      icon: Icons.health_and_safety_rounded,
                      label: 'Gesundheits-Check',
                    ),
                    QuickActionChip(
                      icon: Icons.inventory_2_rounded,
                      label: 'Futterbestand',
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Pet Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deine Tiere',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/animals'),
                      child: Text(
                        'Alle ansehen →',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: LivingLedgerTheme.onSurfaceVariant,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pet Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        constraints.maxWidth > 700 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: petProvider.pets.length,
                      itemBuilder: (context, index) {
                        final pet = petProvider.pets[index];
                        return PetCard(
                          pet: pet,
                          imageBaseUrl: petProvider.apiBaseUrl,
                          onTap: () =>
                              context.go('/animals/${pet.id}'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // ── Right Panel: Appointments ──
          SizedBox(
            width: 300,
            child: _AppointmentsPanel(
              appointments: petProvider.appointments,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Guten Morgen, $name.';
    if (hour < 18) return 'Guten Tag, $name.';
    return 'Guten Abend, $name.';
  }
}

class _AppointmentsPanel extends StatelessWidget {
  final List appointments;

  const _AppointmentsPanel({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: LivingLedgerTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Termine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Appointment List
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 40,
                      color: LivingLedgerTheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keine anstehenden Termine',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: LivingLedgerTheme.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...appointments.map((appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppointmentCard(appointment: appointment),
                )),

          const SizedBox(height: 12),

          // Calendar Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Kalender öffnen'),
            ),
          ),
        ],
      ),
    );
  }
}
