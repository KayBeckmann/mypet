import 'package:flutter/material.dart';
import '../config/theme.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (role) {
      'superadmin' => ('Superadmin', Colors.white, AdminTheme.primary),
      'vet' => ('Tierarzt', AdminTheme.onPrimary, const Color(0xFF1565C0)),
      'provider' => ('Dienstleister', Colors.white, const Color(0xFF6A1B9A)),
      'owner' => ('Besitzer', AdminTheme.onSurface, AdminTheme.surfaceContainerHigh),
      _ => (role, AdminTheme.onSurfaceVariant, AdminTheme.surfaceContainerHigh),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
