import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import 'sidebar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentRoute =
        GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: LivingLedgerTheme.surface,
      body: Row(
        children: [
          // Sidebar Navigation
          Sidebar(
            currentRoute: _matchRoute(currentRoute),
            onNavigate: (route) => context.go(route),
            onAddAnimal: () => context.go('/animals/add'),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _TopBar(),

                // Page Content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
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
    if (route.startsWith('/settings')) return '/settings';
    return route;
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      color: LivingLedgerTheme.surface,
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
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
                    'Search records...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LivingLedgerTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 3),

          // Action Icons
          _TopBarIcon(icon: Icons.notifications_outlined),
          const SizedBox(width: 8),
          _TopBarIcon(icon: Icons.settings_outlined),
          const SizedBox(width: 12),

          // User Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LivingLedgerTheme.signatureGradient,
            ),
            child: const Center(
              child: Text(
                'E',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIcon extends StatefulWidget {
  final IconData icon;

  const _TopBarIcon({required this.icon});

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
    );
  }
}
