import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Records Screen - Placeholder for medical records / documents
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumente & Unterlagen',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Verwalte alle Dokumente, Befunde und Unterlagen deiner Tiere.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 48),

          // Empty State
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.secondary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 40,
                    color: LivingLedgerTheme.secondary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Noch keine Dokumente vorhanden',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hier werden zukünftig medizinische Unterlagen,\n'
                  'Impfpässe und Befunde deiner Tiere angezeigt.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
