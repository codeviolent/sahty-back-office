import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _VaccinesLayout {
  static const double scheduleMinHeight = 300;
  static const double upcomingMinHeight = 210;
  static const double policyMinHeight = 118;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

class VaccinesScreen extends StatelessWidget {
  const VaccinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _VaccinesScheduleCard(),
        const SizedBox(height: AppSpacing.xl),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _UpcomingVaccinesCard()),
            SizedBox(width: AppSpacing.xl),
            Expanded(flex: 4, child: _VaccinesPolicyCard()),
          ],
        ),
      ],
    );
  }
}

class _VaccineItem {
  const _VaccineItem({
    required this.vaccineKey,
    required this.completedKey,
    required this.missingKey,
    required this.alertKey,
    required this.nextDateKey,
    this.critical = false,
  });

  final AppTextKey vaccineKey;
  final AppTextKey completedKey;
  final AppTextKey missingKey;
  final AppTextKey alertKey;
  final AppTextKey nextDateKey;
  final bool critical;
}

class _VaccinesScheduleCard extends StatelessWidget {
  const _VaccinesScheduleCard();

  static const items = [
    _VaccineItem(
      vaccineKey: AppTextKey.vaccinesInfluenzaTitle,
      completedKey: AppTextKey.vaccinesCompletedOne,
      missingKey: AppTextKey.vaccinesMissingBooster,
      alertKey: AppTextKey.vaccinesAlertDue,
      nextDateKey: AppTextKey.vaccinesNextApr28,
      critical: true,
    ),
    _VaccineItem(
      vaccineKey: AppTextKey.vaccinesCovidTitle,
      completedKey: AppTextKey.vaccinesCompletedThree,
      missingKey: AppTextKey.vaccinesMissingNone,
      alertKey: AppTextKey.vaccinesAlertComplete,
      nextDateKey: AppTextKey.vaccinesNextNone,
    ),
    _VaccineItem(
      vaccineKey: AppTextKey.vaccinesHepatitisTitle,
      completedKey: AppTextKey.vaccinesCompletedTwo,
      missingKey: AppTextKey.vaccinesMissingNone,
      alertKey: AppTextKey.vaccinesAlertComplete,
      nextDateKey: AppTextKey.vaccinesNextNone,
    ),
    _VaccineItem(
      vaccineKey: AppTextKey.vaccinesTetanusTitle,
      completedKey: AppTextKey.vaccinesCompletedOne,
      missingKey: AppTextKey.vaccinesMissingBooster,
      alertKey: AppTextKey.vaccinesAlertMissing,
      nextDateKey: AppTextKey.vaccinesNextMay12,
      critical: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.vaccinesScheduleTitle),
      subtitle: context.tr(AppTextKey.vaccinesScheduleSubtitle),
      minHeight: _VaccinesLayout.scheduleMinHeight,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _VaccinesHeader(),
          for (int i = 0; i < items.length; i++) ...[
            _VaccineRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 0.5,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
          ],
        ],
      ),
    );
  }
}

class _VaccinesHeader extends StatelessWidget {
  const _VaccinesHeader();

  @override
  Widget build(BuildContext context) {
    const columns = [
      AppTextKey.vaccinesColumnVaccine,
      AppTextKey.vaccinesColumnCompleted,
      AppTextKey.vaccinesColumnMissing,
      AppTextKey.vaccinesColumnAlert,
      AppTextKey.vaccinesColumnNextDate,
    ];

    return Container(
      height: _VaccinesLayout.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.65),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              child: Text(
                context.tr(column).toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VaccineRow extends StatelessWidget {
  const _VaccineRow({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _VaccinesLayout.rowHeight,
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(item.vaccineKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: item.critical ? AppColors.critical : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Text(context.tr(item.completedKey))),
            Expanded(child: Text(context.tr(item.missingKey))),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(
                  label: context.tr(item.alertKey),
                  tone: item.critical ? BadgeTone.critical : BadgeTone.neutral,
                ),
              ),
            ),
            Expanded(child: Text(context.tr(item.nextDateKey))),
          ],
        ),
      ),
    );
  }
}

class _UpcomingVaccinesCard extends StatelessWidget {
  const _UpcomingVaccinesCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.vaccinesUpcomingTitle),
      subtitle: context.tr(AppTextKey.vaccinesUpcomingSubtitle),
      minHeight: _VaccinesLayout.upcomingMinHeight,
      child: const Column(
        children: [
          _UpcomingTile(
            labelKey: AppTextKey.vaccinesUpcomingInfluenza,
            critical: true,
          ),
          SizedBox(height: AppSpacing.md),
          _UpcomingTile(labelKey: AppTextKey.vaccinesUpcomingTetanus),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.labelKey, this.critical = false});

  final AppTextKey labelKey;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? AppColors.critical : AppColors.mutedInk;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: critical ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(context.tr(labelKey))),
          StatusBadge(
            label: context.tr(
              critical
                  ? AppTextKey.vaccinesAlertDue
                  : AppTextKey.vaccinesAlertComplete,
            ),
            tone: critical ? BadgeTone.critical : BadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _VaccinesPolicyCard extends StatelessWidget {
  const _VaccinesPolicyCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.vaccinesPolicyTitle),
      minHeight: _VaccinesLayout.policyMinHeight,
      child: Text(context.tr(AppTextKey.vaccinesPolicyBody)),
    );
  }
}
