import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// macOS-style surface panel.
///
/// When [blur] == 0 (the default), renders as a plain white card with
/// shadow — zero GPU overhead, safe to use for many cards per screen.
///
/// When [blur] > 0, wraps content in [BackdropFilter] for a true glass
/// effect. Use sparingly (at most 1–2 per screen) to avoid GPU overload.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppSpacing.panelRadius,
    this.blur = 0,
    this.color = AppColors.glassSurface,
    this.borderColor = AppColors.glassStroke,
    this.shadows,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  /// Blur sigma applied via [BackdropFilter].
  /// Set to 0 (default) to skip blur entirely — strongly preferred for
  /// repeated widgets (cards, rows, banners) to avoid GPU freeze.
  final double blur;

  final Color color;
  final Color borderColor;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    // Compute once per build — shared by Container, DecoratedBox, and ClipRRect.
    final br = BorderRadius.circular(radius);
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: br,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadows ?? AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: inner,
              )
            : inner,
      ),
    );
  }
}
