import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
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

class _TopBar extends StatelessWidget {
  final bool showTitle;

  const _TopBar({this.showTitle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      color: LivingLedgerTheme.surface,
      child: Row(
        children: [
          if (showTitle) ...[
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
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.surfaceContainerHigh,
                borderRadius:
                    BorderRadius.circular(LivingLedgerTheme.radiusFull),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search,
                    size: 20,
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suchen …',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LivingLedgerTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          _TopBarIcon(icon: Icons.notifications_outlined, onTap: () {}),
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
