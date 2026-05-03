import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/family_invitation_provider.dart';
import '../providers/family_provider.dart';

class FamiliesScreen extends StatefulWidget {
  const FamiliesScreen({super.key});

  @override
  State<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends State<FamiliesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().loadFamilies();
    });
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Familie erstellen'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Familienname',
              hintText: 'z.B. Familie Müller',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name ist erforderlich' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context
          .read<FamilyProvider>()
          .createFamily(controller.text.trim());
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Familie erstellt')),
        );
      }
    }
  }

  Future<void> _showJoinDialog() async {
    final codeCtrl = TextEditingController();
    Map<String, dynamic>? preview;
    bool loading = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Familie beitreten'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Einladungscode (8 Zeichen)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        setDs(() {
                          loading = true;
                          error = null;
                          preview = null;
                        });
                        try {
                          final api = context.read<ApiService>();
                          final data = await api.get(
                              '/families/join/${codeCtrl.text.trim().toUpperCase()}');
                          setDs(() {
                            preview = data;
                            loading = false;
                          });
                        } catch (e) {
                          setDs(() {
                            error = 'Code ungültig oder abgelaufen';
                            loading = false;
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: TextStyle(color: LivingLedgerTheme.error)),
                ],
                if (preview != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LivingLedgerTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.people_rounded,
                            color: LivingLedgerTheme.primary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          preview!['family_name'] as String? ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        Text(
                          'Erstellt von: ${preview!['created_by_name']}',
                          style: TextStyle(
                              color: LivingLedgerTheme.onSurfaceVariant),
                        ),
                        Text(
                          '${preview!['member_count']} Mitglieder',
                          style: TextStyle(
                              color: LivingLedgerTheme.onSurfaceVariant,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: preview == null
                  ? null
                  : () async {
                      try {
                        final api = context.read<ApiService>();
                        await api.post(
                            '/families/join/${codeCtrl.text.trim().toUpperCase()}',
                            body: {});
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          context
                              .read<FamilyProvider>()
                              .loadFamilies();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Erfolgreich "${preview!['family_name']}" beigetreten')),
                          );
                        }
                      } catch (_) {
                        setDs(() => error = 'Beitreten fehlgeschlagen');
                      }
                    },
              child: const Text('Beitreten'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyProvider>();
    final invitations = context.watch<FamilyInvitationProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Einladungs-Banner
          if (invitations.invitations.isNotEmpty) ...[
            ...invitations.invitations.map((inv) => _InvitationBanner(
                  invitation: inv,
                  onAccept: () async {
                    final ok = await invitations.accept(inv.id);
                    if (ok && context.mounted) {
                      provider.loadFamilies();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Du bist jetzt Mitglied von "${inv.familyName}"'),
                      ));
                    }
                  },
                  onReject: () => invitations.reject(inv.id),
                )),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meine Familien',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verwalte Familienmitglieder und gemeinsame Tierpflege.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LivingLedgerTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _showJoinDialog,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Per Code beitreten'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Familie erstellen'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (provider.error != null)
            _ErrorBanner(message: provider.error!),

          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.families.isEmpty)
            _EmptyState(onCreate: _showCreateDialog)
          else
            ...provider.families.map(
              (family) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _FamilyCard(family: family),
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatefulWidget {
  final Family family;
  const _FamilyCard({required this.family});

  @override
  State<_FamilyCard> createState() => _FamilyCardState();
}

class _FamilyCardState extends State<_FamilyCard> {
  Future<void> _inviteMember() async {
    final emailCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mitglied zu „${widget.family.name}" einladen'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail-Adresse *',
                    hintText: 'nutzer@beispiel.de',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Ungültige E-Mail' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: msgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nachricht (optional)',
                    hintText: 'z.B. "Hey, tritt unserer Familienpflege bei!"',
                  ),
                  maxLines: 2,
                ),
              ],
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
            child: const Text('Einladung senden'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context
          .read<FamilyProvider>()
          .inviteMember(widget.family.id, emailCtrl.text.trim(),
              message: msgCtrl.text.trim().isEmpty ? null : msgCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Einladung gesendet — erscheint im Dashboard von ${emailCtrl.text.trim()}'
                : 'Fehler: Benutzer nicht gefunden oder bereits eingeladen'),
          ),
        );
      }
    }
  }

  Future<void> _showInviteCode() async {
    String? code;
    String? expiresAt;
    bool loading = true;

    try {
      final api = context.read<ApiService>();
      final data = await api.post(
          '/families/${widget.family.id}/invite-code', body: {});
      code = data['code'] as String?;
      expiresAt = data['expires_at'] as String?;
      loading = false;
    } catch (_) {
      loading = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Familie „${widget.family.name}" beitreten'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (code == null)
                const Text('Fehler beim Generieren des Codes')
              else ...[
                // QR Code
                QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),

                // Code als Text
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: LivingLedgerTheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Code kopieren',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Code kopiert')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gültig 7 Tage · Einmalig verwendbar',
                  style: TextStyle(
                      fontSize: 12,
                      color: LivingLedgerTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'Das andere Familienmitglied gibt diesen Code in der App unter '
                  '"Familien → Per Code beitreten" ein.',
                  style: TextStyle(
                      fontSize: 12,
                      color: LivingLedgerTheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Schließen')),
        ],
      ),
    );
  }

  Future<void> _renameFamily() async {
    final controller = TextEditingController(text: widget.family.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Familie umbenennen'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Neuer Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name erforderlich' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context
          .read<FamilyProvider>()
          .renameFamily(widget.family.id, controller.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ok ? 'Familie umbenannt' : 'Umbenennen fehlgeschlagen')),
        );
      }
    }
  }

  Future<void> _deleteFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Familie löschen'),
        content: Text(
            'Möchtest du „${widget.family.name}" wirklich löschen? '
            'Alle Mitglieder verlieren den gemeinsamen Zugriff.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LivingLedgerTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok =
          await context.read<FamilyProvider>().deleteFamily(widget.family.id);
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Löschen fehlgeschlagen')),
        );
      }
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitglied entfernen'),
        content: Text(
            '${member['name'] ?? member['email']} aus der Familie entfernen?'),
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
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<FamilyProvider>()
          .removeMember(widget.family.id, member['user_id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = widget.family;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isAdmin = family.createdBy == currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        border: Border.all(color: LivingLedgerTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.family_restroom,
                      color: LivingLedgerTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    family.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded),
                  tooltip: 'Einladungslink / QR-Code',
                  onPressed: _showInviteCode,
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Mitglied per E-Mail einladen',
                  onPressed: _inviteMember,
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Familie umbenennen',
                    onPressed: _renameFamily,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Familie löschen',
                    color: LivingLedgerTheme.error,
                    onPressed: _deleteFamily,
                  ),
                ],
              ],
            ),
          ),

          // Mitglieder
          if (family.members.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Text(
                'Noch keine Mitglieder. Lade jemanden ein!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LivingLedgerTheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: family.members.map((member) {
                  final name = member['name'] as String? ??
                      member['email'] as String? ??
                      'Unbekannt';
                  final role = member['role'] as String? ?? 'member';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: LivingLedgerTheme.primaryContainer,
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(name)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: role == 'owner'
                                ? LivingLedgerTheme.primaryContainer
                                    .withValues(alpha: 0.15)
                                : LivingLedgerTheme.surfaceContainerHigh,
                            borderRadius:
                                BorderRadius.circular(LivingLedgerTheme.radiusFull),
                          ),
                          child: Text(
                            role == 'owner' ? 'Admin' : 'Mitglied',
                            style: TextStyle(
                              fontSize: 11,
                              color: role == 'owner'
                                  ? LivingLedgerTheme.primary
                                  : LivingLedgerTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (role != 'owner') ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                            color: LivingLedgerTheme.error,
                            tooltip: 'Entfernen',
                            onPressed: () => _removeMember(member),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom,
                size: 72, color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Noch keine Familien',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle eine Familie und lade Familienmitglieder ein,\num gemeinsam Tiere zu verwalten.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Erste Familie erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
      ),
      child: Text(message,
          style: const TextStyle(color: LivingLedgerTheme.error)),
    );
  }
}

class _InvitationBanner extends StatelessWidget {
  final FamilyInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _InvitationBanner({
    required this.invitation,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(
            color: LivingLedgerTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom_rounded,
              color: LivingLedgerTheme.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${invitation.invitedByName} lädt dich ein',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '"${invitation.familyName}" · ${invitation.memberCount} Mitglieder',
                  style: TextStyle(
                      fontSize: 13, color: LivingLedgerTheme.onSurfaceVariant),
                ),
                if (invitation.message?.isNotEmpty == true)
                  Text(
                    '"${invitation.message}"',
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: LivingLedgerTheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onAccept,
            child: const Text('Annehmen'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
                foregroundColor: LivingLedgerTheme.error,
                side: BorderSide(
                    color:
                        LivingLedgerTheme.error.withValues(alpha: 0.5))),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }
}
