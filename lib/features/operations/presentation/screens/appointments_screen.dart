import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';

abstract final class _AppointmentsLayout {
  static const double periodMinHeight = 132;
  static const double listMinHeight = 300;
  static const double rowHeight = 46;
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PeriodSelectorCard(),
        const SizedBox(height: AppSpacing.xl),
        const _AppointmentsCard(),
      ],
    );
  }
}

class _PeriodSelectorCard extends StatelessWidget {
  const _PeriodSelectorCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.appointmentsViewTitle),
      subtitle: context.tr(AppTextKey.appointmentsQueueSubtitle),
      minHeight: _AppointmentsLayout.periodMinHeight,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          StatusBadge(label: context.tr(AppTextKey.appointmentsDay)),
          StatusBadge(label: context.tr(AppTextKey.appointmentsWeek)),
          StatusBadge(label: context.tr(AppTextKey.appointmentsMonth)),
        ],
      ),
    );
  }
}

class _AppointmentItem {
  const _AppointmentItem({
    required this.patientKey,
    required this.timeKey,
    required this.statusKey,
    this.critical = false,
  });

  final AppTextKey patientKey;
  final AppTextKey timeKey;
  final AppTextKey statusKey;
  final bool critical;
}

class _AppointmentsCard extends StatelessWidget {
  const _AppointmentsCard();

  static const items = [
    _AppointmentItem(
      patientKey: AppTextKey.appointmentsPatientFatima,
      timeKey: AppTextKey.appointmentsTimeMorning,
      statusKey: AppTextKey.appointmentsStatusConfirmed,
    ),
    _AppointmentItem(
      patientKey: AppTextKey.appointmentsPatientAli,
      timeKey: AppTextKey.appointmentsTimeNoon,
      statusKey: AppTextKey.appointmentsStatusDelayed,
    ),
    _AppointmentItem(
      patientKey: AppTextKey.appointmentsPatientMariam,
      timeKey: AppTextKey.appointmentsTimeLate,
      statusKey: AppTextKey.appointmentsStatusLate,
      critical: true,
    ),
    _AppointmentItem(
      patientKey: AppTextKey.patientSearchPatientMariam,
      timeKey: AppTextKey.appointmentsTimeNoon,
      statusKey: AppTextKey.appointmentsStatusCancelled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.appointmentsListTitle),
      subtitle: context.tr(AppTextKey.appointmentsListSubtitle),
      minHeight: _AppointmentsLayout.listMinHeight,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _ScheduleRow(item: items[i]),
            if (i < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item});

  final _AppointmentItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _AppointmentsLayout.rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              context.tr(item.timeKey),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: item.critical ? AppColors.critical : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.tr(item.patientKey),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          StatusBadge(
            label: context.tr(item.statusKey),
            tone: item.critical ? BadgeTone.critical : BadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}
