import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Clinical alert card — clean, flat design with no animated elements.
///
/// Used directly for a single alert,
/// or inside [AlertStack] for a stacked group.
///
/// [shadow] — disable the shadow for background cards in [AlertStack] to prevent
/// the peek-strip gesture area from being covered by the front card's drop shadow.
class ClinicalAlertBanner extends StatelessWidget {
  const ClinicalAlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.isCritical = false,
    this.shadow = true,
  });

  final String title;
  final String message;
  final bool isCritical;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.critical : AppColors.warning;
    final icon = isCritical
        ? Icons.warning_rounded
        : Icons.notifications_outlined;
    final chipLabel = isCritical ? 'CRITIQUE' : 'ATTENTION';

    // ── Shell: shadow (optional) + rounded clip ───────────────
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: shadow ? AppColors.cardShadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Stack(
          children: [
            // ── Card body ──────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Icon ──────────────────────────────────────
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: AppSpacing.md),

                  // ── Text ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.mutedInk,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // ── Severity chip ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
