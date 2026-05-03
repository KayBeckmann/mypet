import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<MobileAuthProvider>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mein Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: cs.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? '—',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  user?.email ?? '—',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Name'),
                  trailing: Text(user?.name ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('E-Mail'),
                  trailing: Text(user?.email ?? '—',
                      style: const TextStyle(fontSize: 13)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Rolle'),
                  trailing: Text(_roleLabel(user?.role ?? ''),
                      style: TextStyle(color: cs.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: cs.error),
                  title: Text('Abmelden',
                      style: TextStyle(color: cs.error)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Abmelden'),
                        content:
                            const Text('Möchtest du dich abmelden?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Abbrechen'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                                backgroundColor: cs.error),
                            child: const Text('Abmelden'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      auth.logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner': return 'Tierbesitzer';
      case 'vet': return 'Tierarzt';
      case 'provider': return 'Dienstleister';
      default: return role;
    }
  }
}
