import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Numeric metric card — large value + small label + colored icon.
///
/// Inspired by Claude/Vercel: a bold, oversized black number fills the card,
/// with a small colored icon in the corner on a clean white surface.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = AppColors.primary,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderFaint, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon chip ──────────────────────────────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: tone, size: 16),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Big number ─────────────────────────────────────
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
              height: 1,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Label ──────────────────────────────────────────
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedInk,
              height: 1.4,
            ),
          ),

          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.placeholder,
                fontSize: 9.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
