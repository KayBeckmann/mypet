import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/emergency_contact_provider.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _showDialog(BuildContext context, [EmergencyContact? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final relCtrl = TextEditingController(text: existing?.relationship);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final emailCtrl = TextEditingController(text: existing?.email);
    final notesCtrl = TextEditingController(text: existing?.notes);
    bool isPrimary = existing?.isPrimary ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Notfallkontakt hinzufügen' : 'Kontakt bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: relCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Beziehung',
                    hintText: 'z.B. Ehepartner, Nachbar, Tierarzt',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notizen'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Primärkontakt'),
                  value: isPrimary,
                  onChanged: (v) => setSt(() => isPrimary = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                final body = {
                  'name': name,
                  if (relCtrl.text.trim().isNotEmpty) 'relationship': relCtrl.text.trim(),
                  'phone': phone,
                  if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                  if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                  'is_primary': isPrimary,
                };

                bool ok;
                final provider = context.read<EmergencyContactProvider>();
                if (existing == null) {
                  ok = await provider.add(body);
                } else {
                  ok = await provider.update(existing.id, body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fehler beim Speichern')));
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kontakt löschen'),
        content: Text('„${contact.name}" wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LivingLedgerTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<EmergencyContactProvider>().delete(contact.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notfallkontakte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Hinzufügen',
            onPressed: () => _showDialog(context),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contact_phone_outlined,
                          size: 64,
                          color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Notfallkontakte',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: LivingLedgerTheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Füge Personen hinzu, die im Notfall kontaktiert werden sollen.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Kontakt hinzufügen'),
                        onPressed: () => _showDialog(context),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = provider.contacts[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c.isPrimary
                              ? LivingLedgerTheme.primary.withValues(alpha: 0.15)
                              : LivingLedgerTheme.surface,
                          child: Icon(
                            Icons.person,
                            color: c.isPrimary
                                ? LivingLedgerTheme.primary
                                : LivingLedgerTheme.onSurfaceVariant,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (c.isPrimary) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LivingLedgerTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Primär',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: LivingLedgerTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.relationship != null)
                              Text(c.relationship!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LivingLedgerTheme.onSurfaceVariant,
                                  )),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 12),
                                const SizedBox(width: 4),
                                Text(c.phone, style: const TextStyle(fontSize: 12)),
                                if (c.email != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.email, size: 12),
                                  const SizedBox(width: 4),
                                  Text(c.email!, style: const TextStyle(fontSize: 12)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showDialog(context, c),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: LivingLedgerTheme.error),
                              onPressed: () => _confirmDelete(context, c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
