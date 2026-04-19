import 'package:flutter/material.dart';
import '../config/theme.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onAddAnimal;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onAddAnimal,
  });

  static const List<SidebarItem> _items = [
    SidebarItem(label: 'DASHBOARD', icon: Icons.dashboard_rounded, route: '/'),
    SidebarItem(label: 'ANIMALS', icon: Icons.pets_rounded, route: '/animals'),
    SidebarItem(
        label: 'FAMILY',
        icon: Icons.family_restroom_rounded,
        route: '/families'),
    SidebarItem(
        label: 'SHARING',
        icon: Icons.share_rounded,
        route: '/permissions'),
    SidebarItem(
        label: 'TERMINE',
        icon: Icons.calendar_month_rounded,
        route: '/appointments'),
    SidebarItem(
        label: 'FEEDING',
        icon: Icons.restaurant_rounded,
        route: '/feeding'),
    SidebarItem(
        label: 'MARKETPLACE',
        icon: Icons.storefront_rounded,
        route: '/marketplace'),
    SidebarItem(
        label: 'RECORDS',
        icon: Icons.folder_rounded,
        route: '/records'),
    SidebarItem(
        label: 'TRANSFER',
        icon: Icons.swap_horiz_rounded,
        route: '/transfer'),
    SidebarItem(
        label: 'SETTINGS',
        icon: Icons.settings_rounded,
        route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: LivingLedgerTheme.sidebarWidth,
      color: LivingLedgerTheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Living Ledger',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LivingLedgerTheme.primary,
                      ),
                ),
                Text(
                  'MANAGEMENT SUITE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _items.map((item) {
                final isActive = currentRoute == item.route;
                return _SidebarNavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => onNavigate(item.route),
                );
              }).toList(),
            ),
          ),

          // Add New Animal Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddAnimal,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('ADD NEW ANIMAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LivingLedgerTheme.primary,
                  foregroundColor: LivingLedgerTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(LivingLedgerTheme.radiusFull),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isActive
                ? LivingLedgerTheme.primary.withValues(alpha: 0.08)
                : _isHovered
                    ? LivingLedgerTheme.surfaceContainerLow
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius:
                  BorderRadius.circular(LivingLedgerTheme.radiusMd),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      widget.item.icon,
                      size: 20,
                      color: widget.isActive
                          ? LivingLedgerTheme.primary
                          : LivingLedgerTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.item.label,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: widget.isActive
                                    ? LivingLedgerTheme.primary
                                    : LivingLedgerTheme.onSurfaceVariant,
                                fontWeight: widget.isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
