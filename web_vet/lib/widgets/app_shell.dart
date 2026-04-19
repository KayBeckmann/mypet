import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class VetAppShell extends StatelessWidget {
  final Widget child;
  const VetAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final auth = context.watch<VetAuthProvider>();

    return Scaffold(
      backgroundColor: VetTheme.surface,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: VetTheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services,
                          color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'MyPet Vet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (auth.activeOrganizationId != null)
                        Text(
                          _activeOrgName(auth),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        route: '/',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.business_outlined,
                        label: 'Meine Praxis',
                        route: '/organization',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.people_outlined,
                        label: 'Team',
                        route: '/members',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.pets_outlined,
                        label: 'Patienten',
                        route: '/patients',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                ),
                // User + Logout
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          (auth.user?.name ?? '?').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.user?.name ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout,
                            color: Colors.white, size: 18),
                        tooltip: 'Abmelden',
                        onPressed: auth.logout,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: child),
        ],
      ),
    );
  }

  String _activeOrgName(VetAuthProvider auth) {
    final id = auth.activeOrganizationId;
    if (id == null) return '';
    final org = auth.organizations.firstWhere(
      (o) => o['id'] == id,
      orElse: () => {},
    );
    return org['name'] as String? ?? '';
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  bool get _isActive {
    if (route == '/') return currentRoute == '/';
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: _isActive
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: _isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.7)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: _isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
