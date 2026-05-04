import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = false;
  String? _error;
  int _total = 0;
  int _offset = 0;
  static const int _pageSize = 50;

  final _actionCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _fmt = DateFormat('dd.MM.yy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _actionCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _offset = 0;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final params = {
        'limit': _pageSize.toString(),
        'offset': _offset.toString(),
        if (_actionCtrl.text.trim().isNotEmpty) 'action': _actionCtrl.text.trim(),
      };
      final uri = Uri(
        path: '/admin/audit-log',
        queryParameters: params,
      ).toString();
      final data = await api.get(uri);

      setState(() {
        _entries = (data['audit_log'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _total = (data['total'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitätsprotokoll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            color: AdminTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _actionCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nach Aktion filtern...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _load(reset: true),
                  child: const Text('Suchen'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _actionCtrl.clear();
                    _load(reset: true);
                  },
                  child: const Text('Zurücksetzen'),
                ),
              ],
            ),
          ),
          // Total count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  '$_total Einträge',
                  style: TextStyle(
                    color: AdminTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (_offset > 0)
                  TextButton(
                    onPressed: () {
                      _offset = (_offset - _pageSize).clamp(0, _total);
                      _load();
                    },
                    child: const Text('← Zurück'),
                  ),
                if (_offset + _pageSize < _total)
                  TextButton(
                    onPressed: () {
                      _offset += _pageSize;
                      _load();
                    },
                    child: const Text('Weiter →'),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: TextStyle(color: AdminTheme.error)))
                    : _entries.isEmpty
                        ? const Center(child: Text('Keine Einträge gefunden'))
                        : ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final e = _entries[i];
                              final ts = e['created_at'] as String?;
                              final date = ts != null
                                  ? _fmt.format(DateTime.parse(ts))
                                  : '—';

                              return ListTile(
                                dense: true,
                                leading: _ActionIcon(action: e['action'] as String? ?? ''),
                                title: Row(
                                  children: [
                                    Text(
                                      e['action'] as String? ?? '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    if (e['resource_type'] != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AdminTheme.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          e['resource_type'] as String,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AdminTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  [
                                    if (e['user_name'] != null) e['user_name'] as String,
                                    if (e['user_email'] != null) e['user_email'] as String,
                                    if (e['ip_address'] != null) 'IP: ${e['ip_address']}',
                                  ].join(' · '),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AdminTheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String action;
  const _ActionIcon({required this.action});

  @override
  Widget build(BuildContext context) {
    final lower = action.toLowerCase();
    IconData icon;
    Color color;

    if (lower.contains('login')) {
      icon = Icons.login_rounded;
      color = Colors.blue;
    } else if (lower.contains('delete') || lower.contains('lösch')) {
      icon = Icons.delete_outline_rounded;
      color = Colors.red;
    } else if (lower.contains('create') || lower.contains('anlegen')) {
      icon = Icons.add_circle_outline_rounded;
      color = Colors.green;
    } else if (lower.contains('update') || lower.contains('ändern')) {
      icon = Icons.edit_outlined;
      color = Colors.orange;
    } else if (lower.contains('transfer')) {
      icon = Icons.swap_horiz_rounded;
      color = Colors.purple;
    } else {
      icon = Icons.history_rounded;
      color = Colors.grey;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
