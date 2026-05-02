import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class VetSettingsScreen extends StatelessWidget {
  const VetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<VetAuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Einstellungen',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(
            'Profil und Kontosicherheit verwalten',
            style: TextStyle(color: VetTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          _Section(
            title: 'Mein Konto',
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: VetTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (auth.user?.name ?? '?').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: VetTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(auth.user?.name ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(auth.user?.email ?? '—'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Bearbeiten'),
                      onPressed: () =>
                          _showEditProfileDialog(context, auth),
                    ),
                    TextButton(
                      onPressed: auth.logout,
                      child: const Text('Abmelden'),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Passwort ändern'),
                trailing: OutlinedButton(
                  onPressed: () => _showChangePasswordDialog(context, auth),
                  child: const Text('Ändern'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(
      BuildContext context, VetAuthProvider auth) async {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final emailCtrl = TextEditingController(text: auth.user?.email ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profil bearbeiten'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Speichern')),
        ],
      ),
    );

    if (confirmed != true) return;
    // ignore: use_build_context_synchronously
    final ok = await auth.updateProfile(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Profil aktualisiert.' : (auth.error ?? 'Fehler')),
        backgroundColor: ok ? null : VetTheme.error,
      ));
    }
  }

  Future<void> _showChangePasswordDialog(
      BuildContext context, VetAuthProvider auth) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Passwort ändern'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Aktuelles Passwort',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  onChanged: (_) => setDs(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Neues Passwort (min. 8 Zeichen)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  onChanged: (_) => setDs(() {}),
                  decoration: InputDecoration(
                    labelText: 'Bestätigen',
                    border: const OutlineInputBorder(),
                    errorText: confirmCtrl.text.isNotEmpty &&
                            confirmCtrl.text != newCtrl.text
                        ? 'Passwörter stimmen nicht überein'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: newCtrl.text.length >= 8 &&
                      newCtrl.text == confirmCtrl.text &&
                      currentCtrl.text.isNotEmpty
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Ändern'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    // ignore: use_build_context_synchronously
    final ok = await auth.changePassword(
      currentPassword: currentCtrl.text,
      newPassword: newCtrl.text,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Passwort geändert.'
            : (auth.error ?? 'Fehler beim Ändern des Passworts')),
        backgroundColor: ok ? null : VetTheme.error,
      ));
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VetTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    color: VetTheme.onSurfaceVariant,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
