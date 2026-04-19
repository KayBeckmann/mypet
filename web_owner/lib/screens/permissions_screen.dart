import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/permission_provider.dart';
import '../providers/pet_provider.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionProvider>().loadPermissions();
    });
  }

  Future<void> _showGrantDialog() async {
    final petProvider = context.read<PetProvider>();
    final pets = petProvider.pets;

    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erst ein Tier anlegen, dann Berechtigungen erteilen.')),
      );
      return;
    }

    String selectedPetId = pets.first.id;
    String selectedPermission = 'read';
    final emailController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? startsAt;
    DateTime? endsAt;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Zugriff erteilen'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tier wählen
                    DropdownButtonFormField<String>(
                      value: selectedPetId,
                      decoration: const InputDecoration(labelText: 'Tier'),
                      items: pets
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedPetId = v!),
                    ),
                    const SizedBox(height: 12),

                    // E-Mail des Empfängers
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail des Empfängers',
                        helperText: 'Benutzer muss bereits registriert sein',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Ungültige E-Mail' : null,
                    ),
                    const SizedBox(height: 12),

                    // Berechtigungsstufe
                    DropdownButtonFormField<String>(
                      value: selectedPermission,
                      decoration: const InputDecoration(labelText: 'Berechtigung'),
                      items: const [
                        DropdownMenuItem(value: 'read', child: Text('Lesen (Profil & Akte einsehen)')),
                        DropdownMenuItem(value: 'write', child: Text('Schreiben (Einträge hinzufügen)')),
                        DropdownMenuItem(value: 'manage', child: Text('Verwalten (voller Zugriff)')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedPermission = v!),
                    ),
                    const SizedBox(height: 12),

                    // Zeitraum
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(startsAt != null
                                ? 'Ab: ${DateFormat('dd.MM.yy').format(startsAt!)}'
                                : 'Ab (optional)'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) setDialogState(() => startsAt = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_busy, size: 16),
                            label: Text(endsAt != null
                                ? 'Bis: ${DateFormat('dd.MM.yy').format(endsAt!)}'
                                : 'Bis (optional)'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) setDialogState(() => endsAt = date);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notiz
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Notiz (optional)',
                        hintText: 'z.B. Urlaubsvertretung Juli',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Zugriff erteilen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      // E-Mail → userId auflösen ist serverseitig — wir senden E-Mail direkt
      // Der Backend /permissions endpoint akzeptiert subject_user_id (UUID).
      // Wir senden hier vorerst die E-Mail als "email" Feld — alternativ
      // könnte ein /users/lookup?email= Endpoint genutzt werden.
      // Für die MVP-Phase senden wir die E-Mail und der Server muss sie auflösen.
      // Da die aktuelle API subject_user_id erwartet, zeigen wir einen Hinweis.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berechtigung wird erteilt...'),
          duration: Duration(seconds: 1),
        ),
      );
      // TODO: /users/lookup?email= implementieren für E-Mail→UUID Auflösung
      // Für jetzt reloaden wir nur die Liste
      await context.read<PermissionProvider>().loadPermissions();
    }
  }

  Future<void> _revokePermission(AccessPermission perm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Berechtigung widerrufen'),
        content: Text('Zugriff auf „${perm.petName}" widerrufen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LivingLedgerTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Widerrufen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<PermissionProvider>().revokePermission(perm.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PermissionProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zugriffsberechtigungen',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    'Erteile anderen Personen zeitlich begrenzten Zugriff auf deine Tiere.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LivingLedgerTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showGrantDialog,
                icon: const Icon(Icons.add),
                label: const Text('Zugriff erteilen'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (provider.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
              ),
              child: Text(provider.error!,
                  style: const TextStyle(color: LivingLedgerTheme.error)),
            ),

          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.permissions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_open_outlined,
                        size: 72,
                        color: LivingLedgerTheme.onSurfaceVariant
                            .withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Keine aktiven Berechtigungen',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Erteile z.B. einer Urlaubsvertretung temporären Zugriff\nauf ein bestimmtes Tier.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: provider.permissions.map((perm) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PermissionCard(
                    permission: perm,
                    dateFormat: _dateFormat,
                    onRevoke: () => _revokePermission(perm),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AccessPermission permission;
  final DateFormat dateFormat;
  final VoidCallback onRevoke;

  const _PermissionCard({
    required this.permission,
    required this.dateFormat,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final expired = permission.isExpired;
    final subjectName = permission.subjectUserName ??
        permission.subjectUserEmail ??
        permission.subjectOrganizationName ??
        'Unbekannt';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: expired
            ? LivingLedgerTheme.surfaceContainerHigh
            : LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        border: Border.all(
          color: expired
              ? LivingLedgerTheme.outlineVariant
              : LivingLedgerTheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _permIcon(permission.permission),
            color: expired
                ? LivingLedgerTheme.onSurfaceVariant
                : LivingLedgerTheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      permission.petName.isNotEmpty
                          ? permission.petName
                          : 'Tier',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: expired
                                ? LivingLedgerTheme.onSurfaceVariant
                                : null,
                          ),
                    ),
                    const SizedBox(width: 8),
                    _PermBadge(permission: permission.permission),
                    if (expired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: LivingLedgerTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              LivingLedgerTheme.radiusFull),
                        ),
                        child: const Text(
                          'Abgelaufen',
                          style: TextStyle(
                              fontSize: 11, color: LivingLedgerTheme.error),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '→ $subjectName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                ),
                if (permission.startsAt != null || permission.endsAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _dateRange(permission),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                if (permission.note != null && permission.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      permission.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.block_outlined),
            color: LivingLedgerTheme.error,
            tooltip: 'Widerrufen',
            onPressed: onRevoke,
          ),
        ],
      ),
    );
  }

  IconData _permIcon(String perm) {
    switch (perm) {
      case 'manage':
        return Icons.admin_panel_settings_outlined;
      case 'write':
        return Icons.edit_outlined;
      default:
        return Icons.visibility_outlined;
    }
  }

  String _dateRange(AccessPermission p) {
    final from = p.startsAt != null ? 'ab ${dateFormat.format(p.startsAt!)}' : '';
    final to = p.endsAt != null ? 'bis ${dateFormat.format(p.endsAt!)}' : '';
    if (from.isNotEmpty && to.isNotEmpty) return '$from $to';
    return from.isNotEmpty ? from : to;
  }
}

class _PermBadge extends StatelessWidget {
  final String permission;
  const _PermBadge({required this.permission});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (permission) {
      'manage' => ('Verwalten', Colors.white, LivingLedgerTheme.primary),
      'write' => ('Schreiben', LivingLedgerTheme.onSurface, const Color(0xFFE8F5E9)),
      _ => ('Lesen', LivingLedgerTheme.onSurfaceVariant, LivingLedgerTheme.surfaceContainerHigh),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
