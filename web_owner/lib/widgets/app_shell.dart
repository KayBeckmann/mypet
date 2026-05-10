import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/reminder_provider.dart';
import 'sidebar.dart';

const double _kWideBreakpoint = 1024;
const double _kMediumBreakpoint = 720;

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final matchedRoute = _matchRoute(currentRoute);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _kWideBreakpoint) {
          return _WideLayout(currentRoute: matchedRoute, child: child);
        } else if (width >= _kMediumBreakpoint) {
          return _MediumLayout(currentRoute: matchedRoute, child: child);
        } else {
          return _NarrowLayout(currentRoute: matchedRoute, child: child);
        }
      },
    );
  }

  String _matchRoute(String route) {
    if (route == '/' || route.isEmpty) return '/';
    if (route.startsWith('/animals')) return '/animals';
    if (route.startsWith('/families')) return '/families';
    if (route.startsWith('/permissions')) return '/permissions';
    if (route.startsWith('/appointments')) return '/appointments';
    if (route.startsWith('/feeding')) return '/feeding';
    if (route.startsWith('/marketplace')) return '/marketplace';
    if (route.startsWith('/records')) return '/records';
    if (route.startsWith('/transfer')) return '/transfer';
    if (route.startsWith('/weight')) return '/weight';
    if (route.startsWith('/reminders')) return '/reminders';
    if (route.startsWith('/settings')) return '/settings';
    return route;
  }
}

// ── Wide Layout (>= 1024px): volle Sidebar ────────────────────────────────

class _WideLayout extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const _WideLayout({required this.currentRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LivingLedgerTheme.surface,
      body: Row(
        children: [
          Sidebar(
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            onAddAnimal: () => context.go('/animals/add'),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medium Layout (720–1023px): kompakte Sidebar (Icons) ──────────────────

class _MediumLayout extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const _MediumLayout({required this.currentRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LivingLedgerTheme.surface,
      body: Row(
        children: [
          Sidebar(
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            onAddAnimal: () => context.go('/animals/add'),
            compact: true,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(showTitle: true),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrow Layout (< 720px): AppBar + Drawer ──────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const _NarrowLayout({required this.currentRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LivingLedgerTheme.surface,
      appBar: AppBar(
        backgroundColor: LivingLedgerTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Living Ledger',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: LivingLedgerTheme.primary,
              ),
        ),
        actions: [
          _TopBarIcon(icon: Icons.notifications_outlined, onTap: () {}),
          const SizedBox(width: 8),
          _UserAvatar(),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        backgroundColor: LivingLedgerTheme.surfaceContainerLowest,
        child: Sidebar(
          currentRoute: currentRoute,
          onNavigate: (route) {
            Navigator.of(context).pop();
            context.go(route);
          },
          onAddAnimal: () {
            Navigator.of(context).pop();
            context.go('/animals/add');
          },
        ),
      ),
      body: child,
    );
  }
}

// ── TopBar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  final bool showTitle;

  const _TopBar({this.showTitle = false});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _showResults = false;
  List<_SearchResult> _results = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    final q = query.toLowerCase();
    final results = <_SearchResult>[];

    // Search pets
    final pets = context.read<PetProvider>().pets;
    for (final p in pets) {
      if (p.name.toLowerCase().contains(q) ||
          p.species.name.toLowerCase().contains(q) ||
          (p.breed?.toLowerCase().contains(q) ?? false)) {
        results.add(_SearchResult(
          icon: Icons.pets_rounded,
          title: p.name,
          subtitle: '${p.species ?? ''} · ${p.breed ?? ''}',
          route: '/animals/${p.id}',
          color: LivingLedgerTheme.primary,
        ));
      }
    }

    // Search appointments
    final appts = context.read<AppointmentProvider>().appointments;
    for (final a in appts) {
      if (a.title.toLowerCase().contains(q) ||
          (a.organizationName?.toLowerCase().contains(q) ?? false)) {
        results.add(_SearchResult(
          icon: Icons.event_rounded,
          title: a.title,
          subtitle: a.statusLabel,
          route: '/appointments',
          color: Colors.blue,
        ));
      }
    }

    // Search reminders
    final reminders = context.read<ReminderProvider>().reminders;
    for (final r in reminders) {
      if (r.title.toLowerCase().contains(q)) {
        results.add(_SearchResult(
          icon: Icons.alarm_rounded,
          title: r.title,
          subtitle: 'Erinnerung',
          route: '/reminders',
          color: Colors.teal,
        ));
      }
    }

    setState(() {
      _results = results.take(6).toList();
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      color: LivingLedgerTheme.surface,
      child: Row(
        children: [
          if (widget.showTitle) ...[
            Text(
              'Living Ledger',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LivingLedgerTheme.primary,
                  ),
            ),
            const SizedBox(width: 24),
          ],

          // Search Bar
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(LivingLedgerTheme.radiusFull),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    onChanged: _onSearch,
                    onTap: () {
                      if (_searchCtrl.text.isNotEmpty) {
                        setState(() => _showResults = true);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Tiere, Termine, Erinnerungen suchen…',
                      hintStyle: TextStyle(color: LivingLedgerTheme.onSurfaceVariant, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 20, color: LivingLedgerTheme.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {_results = []; _showResults = false;});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                if (_showResults && _results.isNotEmpty)
                  Positioned(
                    top: 46,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _results.map((r) => InkWell(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {_results = []; _showResults = false;});
                              context.go(r.route);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(r.icon, color: r.color, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        if (r.subtitle.isNotEmpty)
                                          Text(r.subtitle, style: TextStyle(fontSize: 11, color: LivingLedgerTheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          _TopBarIcon(icon: Icons.notifications_outlined, onTap: () => context.go('/notifications')),
          const SizedBox(width: 8),
          _TopBarIcon(
            icon: Icons.settings_outlined,
            onTap: () => context.go('/settings'),
          ),
          const SizedBox(width: 12),
          _UserAvatar(),
        ],
      ),
    );
  }
}

class _SearchResult {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
  const _SearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? '';

    return Tooltip(
      message: name.isNotEmpty ? name : 'Benutzer',
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LivingLedgerTheme.signatureGradient,
        ),
        child: Center(
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIcon({required this.icon, required this.onTap});

  @override
  State<_TopBarIcon> createState() => _TopBarIconState();
}

class _TopBarIconState extends State<_TopBarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? LivingLedgerTheme.surfaceContainerHigh
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 22,
            color: LivingLedgerTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
