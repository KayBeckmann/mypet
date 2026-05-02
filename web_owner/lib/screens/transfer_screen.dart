import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/transfer_provider.dart';

/// Screen zum Annehmen/Ablehnen eines Tier-Transfers via Token
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _tokenCtrl = TextEditingController();

  // null = eingabe, non-null = preview loaded
  Map<String, dynamic>? _preview;
  bool _processing = false;
  String? _error;
  String? _successMsg;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _processing = true;
      _error = null;
      _preview = null;
    });
    final provider = context.read<TransferProvider>();
    final result = await provider.lookup(token);
    setState(() {
      _processing = false;
      if (result != null) {
        _preview = result;
      } else {
        _error = provider.error ?? 'Transfer nicht gefunden';
      }
    });
  }

  Future<void> _act({required bool accept}) async {
    final token = _tokenCtrl.text.trim();
    setState(() {
      _processing = true;
      _error = null;
    });
    final provider = context.read<TransferProvider>();
    final ok = accept
        ? await provider.accept(token)
        : await provider.reject(token);
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (ok) {
        _successMsg = accept
            ? 'Transfer angenommen! Das Tier gehört jetzt dir.'
            : 'Transfer abgelehnt.';
        _preview = null;
        _tokenCtrl.clear();
      } else {
        _error = provider.error ?? 'Unbekannter Fehler';
      }
    });
    if (ok && accept && mounted) {
      context.go('/animals');
    }
  }

  void _reset() => setState(() {
        _preview = null;
        _error = null;
        _successMsg = null;
        _tokenCtrl.clear();
      });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/animals'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Zurück'),
          ),
          const SizedBox(height: 16),
          Text('Tier-Übertragung',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Wenn dir jemand ein Tier übertragen möchte, erhältst du einen Token. '
            'Gib ihn hier ein, um die Übertragung zu prüfen und anzunehmen oder abzulehnen.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: LivingLedgerTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          if (_successMsg != null) _SuccessBanner(message: _successMsg!, onDismiss: _reset),

          if (_preview == null) ...[
            _TokenInputCard(
              controller: _tokenCtrl,
              processing: _processing,
              error: _error,
              onLookup: _lookup,
            ),
          ] else ...[
            _PreviewCard(
              preview: _preview!,
              token: _tokenCtrl.text.trim(),
              processing: _processing,
              error: _error,
              onAccept: () => _act(accept: true),
              onReject: () => _act(accept: false),
              onCancel: _reset,
            ),
          ],
        ],
      ),
    );
  }
}

class _TokenInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool processing;
  final String? error;
  final VoidCallback onLookup;

  const _TokenInputCard({
    required this.controller,
    required this.processing,
    required this.error,
    required this.onLookup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LivingLedgerTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer-Token eingeben',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onSubmitted: (_) => onLookup(),
            decoration: const InputDecoration(
              labelText: 'Transfer-Token',
              hintText: 'z.B. aBcDeF1234...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!,
                  style: TextStyle(color: LivingLedgerTheme.error, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search_rounded, size: 18),
            label: const Text('Transfer prüfen'),
            onPressed: processing ? null : onLookup,
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Map<String, dynamic> preview;
  final String token;
  final bool processing;
  final String? error;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  const _PreviewCard({
    required this.preview,
    required this.token,
    required this.processing,
    required this.error,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = preview['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final petName = preview['pet_name'] as String? ?? '—';
    final species = preview['species'] as String? ?? '';
    final breed = preview['breed'] as String? ?? '';
    final fromOwner = preview['from_owner_name'] as String? ?? '—';
    final message = preview['message'] as String?;
    final emoji = _speciesEmoji(species);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LivingLedgerTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LivingLedgerTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (breed.isNotEmpty)
                          Text(breed,
                              style: TextStyle(
                                  color: LivingLedgerTheme.onSurfaceVariant))
                        else if (species.isNotEmpty)
                          Text(_speciesLabel(species),
                              style: TextStyle(
                                  color: LivingLedgerTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Von',
                value: fromOwner,
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.message_outlined,
                  label: 'Nachricht',
                  value: message,
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!,
                      style: TextStyle(
                          color: LivingLedgerTheme.error, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: processing ? null : onCancel,
                    child: const Text('Anderen Token eingeben'),
                  ),
                  const Spacer(),
                  if (isPending) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Ablehnen'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: LivingLedgerTheme.error),
                      onPressed: processing ? null : onReject,
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Annehmen'),
                      onPressed: processing ? null : onAccept,
                    ),
                  ] else
                    Text(
                      'Dieser Transfer ist nicht mehr aktiv (Status: ${_statusLabel(status)})',
                      style: TextStyle(
                          color: LivingLedgerTheme.onSurfaceVariant,
                          fontSize: 13),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _speciesEmoji(String s) => switch (s.toLowerCase()) {
        'dog' => '🐶',
        'cat' => '🐱',
        'horse' => '🐴',
        'bird' => '🐦',
        'rabbit' => '🐰',
        _ => '🐾',
      };

  String _speciesLabel(String s) => switch (s.toLowerCase()) {
        'dog' => 'Hund',
        'cat' => 'Katze',
        'horse' => 'Pferd',
        'bird' => 'Vogel',
        'rabbit' => 'Kaninchen',
        _ => s,
      };

  String _statusLabel(String s) => switch (s) {
        'pending' => 'Ausstehend',
        'accepted' => 'Angenommen',
        'rejected' => 'Abgelehnt',
        'cancelled' => 'Abgebrochen',
        _ => s,
      };
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: LivingLedgerTheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                color: LivingLedgerTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Ausstehend', Colors.orange),
      'accepted' => ('Angenommen', Colors.green),
      'rejected' => ('Abgelehnt', LivingLedgerTheme.error),
      'cancelled' => ('Abgebrochen', Colors.grey),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _SuccessBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.green),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
