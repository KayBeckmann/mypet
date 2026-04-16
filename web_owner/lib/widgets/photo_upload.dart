import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Widget für Foto-Auswahl und -Vorschau
///
/// Auf Flutter Web wird ein File-Input per HTML genutzt.
/// Dieses Widget zeigt die Vorschau und den Upload-Status.
class PhotoUpload extends StatefulWidget {
  final String? currentImageUrl;
  final Uint8List? selectedBytes;
  final String? selectedFileName;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const PhotoUpload({
    super.key,
    this.currentImageUrl,
    this.selectedBytes,
    this.selectedFileName,
    this.isUploading = false,
    required this.onPickImage,
    this.onRemoveImage,
  });

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.selectedBytes != null ||
        (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isUploading ? null : widget.onPickImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: _isHovered
                ? LivingLedgerTheme.surfaceContainerHigh
                : LivingLedgerTheme.surfaceContainerLow,
            borderRadius:
                BorderRadius.circular(LivingLedgerTheme.radiusXl),
            border: Border.all(
              color: _isHovered
                  ? LivingLedgerTheme.primary.withValues(alpha: 0.3)
                  : LivingLedgerTheme.outlineVariant.withValues(alpha: 0.15),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: hasImage ? _buildPreview() : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.isUploading) {
      return _buildUploadingState();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 40,
          color: LivingLedgerTheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Foto hinzufügen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: LivingLedgerTheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, WebP oder GIF (max. 10 MB)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LivingLedgerTheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Bild-Vorschau
        ClipRRect(
          borderRadius:
              BorderRadius.circular(LivingLedgerTheme.radiusXl - 2),
          child: widget.selectedBytes != null
              ? Image.memory(
                  widget.selectedBytes!,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  widget.currentImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildBrokenImage(),
                ),
        ),

        // Upload-Overlay
        if (widget.isUploading)
          ClipRRect(
            borderRadius:
                BorderRadius.circular(LivingLedgerTheme.radiusXl - 2),
            child: Container(
              color: LivingLedgerTheme.onSurface.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),

        // Hover-Overlay mit Aktionen
        if (_isHovered && !widget.isUploading)
          ClipRRect(
            borderRadius:
                BorderRadius.circular(LivingLedgerTheme.radiusXl - 2),
            child: Container(
              color: LivingLedgerTheme.onSurface.withValues(alpha: 0.4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Ändern',
                      onTap: widget.onPickImage,
                    ),
                    if (widget.onRemoveImage != null) ...[
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Entfernen',
                        onTap: widget.onRemoveImage!,
                        isDestructive: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Dateiname-Badge
        if (widget.selectedFileName != null && !widget.isUploading)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.onSurface.withValues(alpha: 0.7),
                borderRadius:
                    BorderRadius.circular(LivingLedgerTheme.radiusFull),
              ),
              child: Text(
                widget.selectedFileName!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrokenImage() {
    return Container(
      color: LivingLedgerTheme.surfaceContainerLow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 36,
            color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Bild konnte nicht geladen werden',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: LivingLedgerTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Wird hochgeladen...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LivingLedgerTheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius:
              BorderRadius.circular(LivingLedgerTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive
                  ? LivingLedgerTheme.error
                  : LivingLedgerTheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDestructive
                        ? LivingLedgerTheme.error
                        : LivingLedgerTheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
