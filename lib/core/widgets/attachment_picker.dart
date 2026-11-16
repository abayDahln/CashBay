import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Where a new attachment should come from.
enum AttachmentSource { camera, gallery }

/// Full-width attachment field shared by the add/edit transaction forms.
///
/// Empty: a dropzone the width of the form. Filled: the photo in a fixed-height
/// frame with the remove / change actions overlaid on it, so the controls never
/// add extra rows below the image.
class AttachmentPicker extends StatelessWidget {
  final String? path;

  /// True when [path] is a freshly picked file that has not been saved yet, so
  /// remove shows an undo affordance instead of a delete one.
  final bool isNew;

  /// Asks the host to pick a new file (and update its own state).
  final Future<void> Function(AttachmentSource source) onPick;

  /// Asks the host to apply the remove/undo action. When null, no remove
  /// action is shown (e.g. a read-only context).
  final VoidCallback? onRemove;

  /// Opens the full-screen viewer for [path]; when null the photo is not
  /// tappable.
  final VoidCallback? onView;

  const AttachmentPicker({
    super.key,
    required this.path,
    required this.onPick,
    this.onRemove,
    this.onView,
    this.isNew = false,
  });

  static const double _filledHeight = 170;
  static const double _radius = 16;

  Future<void> _chooseSource(BuildContext context) async {
    final t = L.of(context);
    final source = await showModalBottomSheet<AttachmentSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(t.camera),
              onTap: () => Navigator.pop(context, AttachmentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.gallery),
              onTap: () => Navigator.pop(context, AttachmentSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return (path == null || path!.isEmpty)
        ? _empty(context, t, scheme)
        : _filled(context, t, scheme);
  }

  Widget _empty(BuildContext context, L t, ColorScheme scheme) {
    return AspectRatio(
      aspectRatio: 2 / 1,
      child: InkWell(
        onTap: () => _chooseSource(context),
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 28,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                t.addPhotoHint,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filled(BuildContext context, L t, ColorScheme scheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        height: _filledHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onView,
              child: Image.file(
                File(path!),
                fit: BoxFit.cover,
                semanticLabel: t.attachmentPhoto,
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: _CircleAction(
                  icon: isNew ? Icons.undo : Icons.close,
                  tooltip: isNew ? t.undoNewPhoto : t.removePhoto,
                  onTap: onRemove!,
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.tonalIcon(
                onPressed: () => _chooseSource(context),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(t.change),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark translucent circular icon button for overlaying on a photo.
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        color: Colors.white,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}
