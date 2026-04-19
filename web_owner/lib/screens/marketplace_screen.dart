import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  String _typeFilter = '';
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final q = _searchCtrl.text.trim();
      var url = '/organizations/search';
      final params = <String>[];
      if (_typeFilter.isNotEmpty) params.add('type=$_typeFilter');
      if (q.isNotEmpty) params.add('q=${Uri.encodeQueryComponent(q)}');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final data = await api.get(url);
      setState(() {
        _results = (data['organizations'] as List? ?? [])
            .cast<Map<String, dynamic>>();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marktplatz',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Finde Tierärzte und Dienstleister in deiner Nähe.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Search + filter row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Suche nach Name, Ort oder Spezialisierung…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(LivingLedgerTheme.radiusFull),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '', label: Text('Alle')),
                  ButtonSegment(
                      value: 'vet_practice',
                      icon: Icon(Icons.local_hospital_rounded),
                      label: Text('Tierärzte')),
                  ButtonSegment(
                      value: 'service_provider',
                      icon: Icon(Icons.handyman_rounded),
                      label: Text('Dienstleister')),
                ],
                selected: {_typeFilter},
                onSelectionChanged: (s) {
                  setState(() => _typeFilter = s.first);
                  _search();
                },
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _search,
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Suchen',
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Center(
              child: Text('Fehler: $_error',
                  style: TextStyle(color: LivingLedgerTheme.error)),
            )
          else if (_results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.storefront_rounded,
                        size: 48,
                        color: LivingLedgerTheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Ergebnisse',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Versuche einen anderen Suchbegriff oder Filter.',
                      style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _results.map((org) => _OrgCard(org: org)).toList(),
            ),
        ],
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final Map<String, dynamic> org;
  const _OrgCard({required this.org});

  @override
  Widget build(BuildContext context) {
    final type = org['type'] as String? ?? '';
    final isVet = type == 'vet_practice';
    final color =
        isVet ? LivingLedgerTheme.primary : LivingLedgerTheme.secondary;
    final icon =
        isVet ? Icons.local_hospital_rounded : Icons.handyman_rounded;
    final typeLabel = isVet ? 'Tierarztpraxis' : 'Dienstleister';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(
            color: LivingLedgerTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org['name'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      typeLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((org['specialization'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              org['specialization'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((org['address'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: LivingLedgerTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    org['address'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        color: LivingLedgerTheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if ((org['phone'] as String?)?.isNotEmpty == true ||
              (org['email'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if ((org['phone'] as String?)?.isNotEmpty == true) ...[
                  Icon(Icons.phone_outlined,
                      size: 14, color: LivingLedgerTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    org['phone'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        color: LivingLedgerTheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                ],
                if ((org['email'] as String?)?.isNotEmpty == true) ...[
                  Icon(Icons.email_outlined,
                      size: 14, color: LivingLedgerTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      org['email'] as String,
                      style: TextStyle(
                          fontSize: 12,
                          color: LivingLedgerTheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
