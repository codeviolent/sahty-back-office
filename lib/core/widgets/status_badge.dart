import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum BadgeTone { normal, warning, critical, info, neutral, primary }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  Color get _backgroundColor => switch (tone) {
    BadgeTone.critical => AppColors.critical.withValues(alpha: 0.12),
    BadgeTone.warning => AppColors.warning.withValues(alpha: 0.12),
    BadgeTone.info => const Color(0xFFD1ECF1),
    BadgeTone.normal => const Color(0xFFD4EDDA),
    BadgeTone.neutral => AppColors.border.withValues(alpha: 0.55),
    BadgeTone.primary => AppColors.primary.withValues(alpha: 0.10),
  };

  Color get _foregroundColor => switch (tone) {
    BadgeTone.critical => AppColors.critical,
    BadgeTone.warning => const Color(0xFF856404),
    BadgeTone.info => const Color(0xFF0C5460),
    BadgeTone.normal => const Color(0xFF155724),
    BadgeTone.neutral => AppColors.mutedInk,
    BadgeTone.primary => AppColors.primary,
  };

  Color get _borderColor => _foregroundColor.withValues(alpha: 0.22);

  @override
  Widget build(BuildContext context) {
    final bg = _backgroundColor;
    final fg = _foregroundColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor, width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
