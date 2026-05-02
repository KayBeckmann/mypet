import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

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

class _SidebarSection {
  final String? title;
  final List<SidebarItem> items;

  const _SidebarSection({this.title, required this.items});
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onAddAnimal;
  final bool compact;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onAddAnimal,
    this.compact = false,
  });

  static const List<_SidebarSection> _sections = [
    _SidebarSection(items: [
      SidebarItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/'),
    ]),
    _SidebarSection(title: 'Meine Tiere', items: [
      SidebarItem(label: 'Tiere', icon: Icons.pets_rounded, route: '/animals'),
      SidebarItem(label: 'Akten', icon: Icons.folder_rounded, route: '/records'),
      SidebarItem(label: 'Gewicht', icon: Icons.monitor_weight_rounded, route: '/weight'),
      SidebarItem(label: 'Fütterung', icon: Icons.restaurant_rounded, route: '/feeding'),
      SidebarItem(label: 'Medikamente', icon: Icons.medication_rounded, route: '/medications'),
      SidebarItem(label: 'Erinnerungen', icon: Icons.alarm_rounded, route: '/reminders'),
    ]),
    _SidebarSection(title: 'Verwaltung', items: [
      SidebarItem(label: 'Familie', icon: Icons.family_restroom_rounded, route: '/families'),
      SidebarItem(label: 'Freigaben', icon: Icons.share_rounded, route: '/permissions'),
      SidebarItem(label: 'Übergabe', icon: Icons.swap_horiz_rounded, route: '/transfer'),
      SidebarItem(label: 'Termine', icon: Icons.calendar_month_rounded, route: '/appointments'),
    ]),
    _SidebarSection(title: 'Community', items: [
      SidebarItem(label: 'Marktplatz', icon: Icons.storefront_rounded, route: '/marketplace'),
    ]),
    _SidebarSection(title: 'Konto', items: [
      SidebarItem(label: 'Einstellungen', icon: Icons.settings_outlined, route: '/settings'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      width: compact ? 72 : LivingLedgerTheme.sidebarWidth,
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: LivingLedgerTheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Brand
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 24, 32, compact ? 14 : 24, 8,
            ),
            child: compact
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LivingLedgerTheme.signatureGradient,
                      borderRadius:
                          BorderRadius.circular(LivingLedgerTheme.radiusMd),
                    ),
                    child: const Center(
                      child: Text(
                        'LL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : Column(
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
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  color: LivingLedgerTheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // Navigation Sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
              children: [
                for (final section in _sections) ...[
                  if (section.title != null && !compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        section.title!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: LivingLedgerTheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                  for (final item in section.items)
                    _SidebarNavItem(
                      item: item,
                      isActive: currentRoute == item.route,
                      onTap: () => onNavigate(item.route),
                      compact: compact,
                    ),
                  if (section.title != null) const SizedBox(height: 4),
                ],
              ],
            ),
          ),

          // Add Animal Button
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: 8),
            child: compact
                ? _CompactIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Tier hinzufügen',
                    onTap: onAddAnimal,
                    isPrimary: true,
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddAnimal,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('TIER HINZUFÜGEN'),
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

          // User Section
          Container(
            padding: EdgeInsets.all(compact ? 8 : 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color:
                      LivingLedgerTheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: compact
                ? _CompactIconButton(
                    icon: Icons.logout_rounded,
                    tooltip: 'Abmelden',
                    onTap: () => auth.logout(),
                  )
                : Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LivingLedgerTheme.signatureGradient,
                        ),
                        child: Center(
                          child: Text(
                            _initials(user?.name ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.name ?? 'Benutzer',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (auth.isDemoMode)
                              Text(
                                'Demo-Modus',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: LivingLedgerTheme.tertiary),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => auth.logout(),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        color: LivingLedgerTheme.onSurfaceVariant,
                        tooltip: 'Abmelden',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CompactIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isPrimary;

  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_CompactIconButton> createState() => _CompactIconButtonState();
}

class _CompactIconButtonState extends State<_CompactIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? LivingLedgerTheme.primary
                  : _isHovered
                      ? LivingLedgerTheme.surfaceContainerHigh
                      : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(LivingLedgerTheme.radiusMd),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isPrimary
                  ? Colors.white
                  : LivingLedgerTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool compact;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final itemContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 12 : 16,
        vertical: 12,
      ),
      child: widget.compact
          ? Icon(
              widget.item.icon,
              size: 20,
              color: widget.isActive
                  ? LivingLedgerTheme.primary
                  : LivingLedgerTheme.onSurfaceVariant,
            )
          : Row(
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.isActive
                            ? LivingLedgerTheme.primary
                            : LivingLedgerTheme.onSurfaceVariant,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
    );

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.isActive
            ? LivingLedgerTheme.primary.withValues(alpha: 0.08)
            : _isHovered
                ? LivingLedgerTheme.surfaceContainerLow
                : Colors.transparent,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
        border: widget.isActive
            ? Border.all(
                color: LivingLedgerTheme.primary.withValues(alpha: 0.15),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
          child: itemContent,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: widget.compact
            ? Tooltip(
                message: widget.item.label,
                preferBelow: false,
                child: decorated,
              )
            : decorated,
      ),
    );
  }
}
