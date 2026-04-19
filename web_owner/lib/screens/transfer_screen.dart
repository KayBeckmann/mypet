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
  bool _processing = false;
  String? _result;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

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
          Text(
            'Tier-Übertragung',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Wenn dir jemand ein Tier übertragen möchte, erhältst du einen Token. '
            'Gib ihn hier ein, um die Übertragung anzunehmen oder abzulehnen.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
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
                Text(
                  'Transfer-Token eingeben',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Transfer-Token',
                    hintText: 'z.B. aBcDeF1234...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                if (_result != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _result!.startsWith('✓')
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_result!,
                        style: TextStyle(
                          color: _result!.startsWith('✓')
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                if (_result != null) const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Ablehnen'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: LivingLedgerTheme.error),
                      onPressed: _processing ? null : () => _act(accept: false),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Annehmen'),
                      onPressed: _processing ? null : () => _act(accept: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _act({required bool accept}) async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;

    setState(() {
      _processing = true;
      _result = null;
    });

    final provider = context.read<TransferProvider>();
    final ok = accept ? await provider.accept(token) : await provider.reject(token);

    setState(() {
      _processing = false;
      if (ok) {
        _result = accept
            ? '✓ Transfer angenommen! Das Tier gehört jetzt dir.'
            : '✓ Transfer abgelehnt.';
        _tokenCtrl.clear();
      } else {
        _result = '✗ Fehler: ${provider.error ?? 'Unbekannter Fehler'}';
      }
    });

    if (ok && accept && mounted) {
      // Reload pets
      context.go('/animals');
    }
  }
}
