import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exportLoading = false;
  bool _auditLoading = false;
  List<Map<String, dynamic>> _auditLog = [];
  String? _exportData;
  String? _error;

  Future<void> _exportMyData() async {
    setState(() {
      _exportLoading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/account/export');
      setState(() {
        _exportData = const JsonEncoder.withIndent('  ').convert(data);
      });
      if (mounted) {
        _showExportDialog();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _exportLoading = false);
    }
  }

  Future<void> _loadAuditLog() async {
    setState(() {
      _auditLoading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/account/audit-log');
      setState(() {
        _auditLog = (data['audit_log'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _auditLoading = false);
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datenexport'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              _exportData ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Einstellungen & Datenschutz',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Verwalte deine Daten und Kontosicherheit.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: LivingLedgerTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Account info
          _Section(
            title: 'Mein Konto',
            children: [
              ListTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.person_rounded)),
                title: Text(auth.user?.name ?? '—'),
                subtitle: Text(auth.user?.email ?? '—'),
                trailing: TextButton(
                  onPressed: auth.logout,
                  child: const Text('Abmelden'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // DSGVO
          _Section(
            title: 'Datenschutz (DSGVO)',
            children: [
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Meine Daten exportieren'),
                subtitle: const Text(
                    'Erhalte alle gespeicherten Daten als JSON-Export.'),
                trailing: _exportLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Exportieren'),
                        onPressed: _exportMyData,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Audit log
          _Section(
            title: 'Aktivitätsprotokoll',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hier siehst du protokollierte Aktivitäten auf deinem Konto.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _auditLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded,
                                size: 16),
                            label: const Text('Laden'),
                            onPressed: _loadAuditLog,
                          ),
                  ],
                ),
              ),
              if (_auditLog.isNotEmpty)
                ...(_auditLog.take(20).map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.history_rounded, size: 18),
                      title: Text(e['action'] as String? ?? '—'),
                      subtitle: Text(
                        [
                          if (e['resource_type'] != null)
                            e['resource_type'] as String,
                          if (e['ip_address'] != null)
                            'IP: ${e['ip_address']}',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        _fmtDate(e['created_at'] as String?),
                        style: const TextStyle(
                            fontSize: 11,
                            color: LivingLedgerTheme.onSurfaceVariant),
                      ),
                    ))),
              if (_auditLog.isEmpty && !_auditLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Keine Einträge vorhanden.',
                      style: TextStyle(
                          color: LivingLedgerTheme.onSurfaceVariant)),
                ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style:
                      TextStyle(color: LivingLedgerTheme.error, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.substring(0, 16);
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
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LivingLedgerTheme.outlineVariant),
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
                    color: LivingLedgerTheme.onSurfaceVariant,
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
