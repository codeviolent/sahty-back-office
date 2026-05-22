import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _TimelineLayout {
  static const double filtersMinHeight = 112;
  static const double eventsMinHeight = 390;
  static const double contextMinHeight = 390;
  static const double laneLabelWidth = 124;
  static const double laneHeight = 62;
}

class _TimelineEventData {
  const _TimelineEventData({
    required this.titleKey,
    required this.bodyKey,
    required this.dateKey,
    required this.icon,
    required this.quickLinkKey,
    required this.tone,
    this.critical = false,
  });

  final AppTextKey titleKey;
  final AppTextKey bodyKey;
  final AppTextKey dateKey;
  final IconData icon;
  final AppTextKey quickLinkKey;
  final Color tone;
  final bool critical;
}

abstract final class _TimelineMock {
  static const events = [
    _TimelineEventData(
      titleKey: AppTextKey.timelineEventLabTitle,
      bodyKey: AppTextKey.timelineEventLabBody,
      dateKey: AppTextKey.timelineEventLabDate,
      icon: Icons.science_outlined,
      quickLinkKey: AppTextKey.timelineQuickOpenLab,
      tone: AppColors.critical,
      critical: true,
    ),
    _TimelineEventData(
      titleKey: AppTextKey.timelineEventPrescriptionTitle,
      bodyKey: AppTextKey.timelineEventPrescriptionBody,
      dateKey: AppTextKey.timelineEventPrescriptionDate,
      icon: Icons.medication_outlined,
      quickLinkKey: AppTextKey.timelineQuickOpenPrescription,
      tone: AppColors.primary,
    ),
    _TimelineEventData(
      titleKey: AppTextKey.timelineEventDiagnosisTitle,
      bodyKey: AppTextKey.timelineEventDiagnosisBody,
      dateKey: AppTextKey.timelineEventDiagnosisDate,
      icon: Icons.medical_information_outlined,
      quickLinkKey: AppTextKey.timelineQuickOpenDiagnosis,
      tone: AppColors.info,
    ),
  ];
}

enum _TimelineFilter {
  year2026,
  monthApril,
  all,
  labs,
  prescription,
  diagnosis,
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final Set<_TimelineFilter> _activeFilters = {_TimelineFilter.all};

  void _toggleFilter(_TimelineFilter filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        if (_activeFilters.length > 1) _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineFilters(
          activeFilters: _activeFilters,
          onToggle: _toggleFilter,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _TimelineEventsCard()),
            SizedBox(width: AppSpacing.lg),
            Expanded(flex: 3, child: _TimelineContextCard()),
          ],
        ),
      ],
    );
  }
}

class _TimelineFilters extends StatelessWidget {
  const _TimelineFilters({required this.activeFilters, required this.onToggle});

  final Set<_TimelineFilter> activeFilters;
  final ValueChanged<_TimelineFilter> onToggle;

  @override
  Widget build(BuildContext context) {
    final filterItems = [
      (_TimelineFilter.year2026, AppTextKey.timelineYear2026),
      (_TimelineFilter.monthApril, AppTextKey.timelineMonthApril),
      (_TimelineFilter.all, AppTextKey.timelineTypeAll),
      (_TimelineFilter.labs, AppTextKey.timelineTypeLabs),
      (_TimelineFilter.prescription, AppTextKey.timelineTypePrescription),
      (_TimelineFilter.diagnosis, AppTextKey.timelineTypeDiagnosis),
    ];

    return SectionCard(
      title: context.tr(AppTextKey.timelineFiltersTitle),
      subtitle: context.tr(AppTextKey.timelineFiltersSubtitle),
      minHeight: _TimelineLayout.filtersMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.timelineTypeAll),
        tone: BadgeTone.primary,
        icon: Icons.filter_alt_outlined,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (filter, key) in filterItems)
                  _TimelineFilterChip(
                    label: context.tr(key),
                    selected: activeFilters.contains(filter),
                    onTap: () => onToggle(filter),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineFilterChip extends StatelessWidget {
  const _TimelineFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.canvas.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.borderFaint,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? AppColors.primary : AppColors.mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineEventsCard extends StatelessWidget {
  const _TimelineEventsCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.timelineEventsTitle),
      subtitle: context.tr(AppTextKey.timelineEventsSubtitle),
      minHeight: _TimelineLayout.eventsMinHeight,
      padding: EdgeInsets.zero,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.timelineMonthApril),
        tone: BadgeTone.neutral,
        icon: Icons.calendar_today_outlined,
      ),
      child: Column(
        children: [const _TimelineMonthHeader(), const _TimelineRoadmapBoard()],
      ),
    );
  }
}

class _TimelineMonthHeader extends StatelessWidget {
  const _TimelineMonthHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.62),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timeline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${context.tr(AppTextKey.timelineMonthApril)} · ${context.tr(AppTextKey.timelineYear2026)}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          StatusBadge(
            label: '${_TimelineMock.events.length}',
            tone: BadgeTone.primary,
          ),
        ],
      ),
    );
  }
}

class _TimelineRoadmapBoard extends StatelessWidget {
  const _TimelineRoadmapBoard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const _TimelineScale(),
          const SizedBox(height: AppSpacing.sm),
          _TimelineLane(
            labelKey: AppTextKey.timelineTypeLabs,
            event: _TimelineMock.events[0],
            start: 0.20,
            width: 0.35,
          ),
          const SizedBox(height: AppSpacing.md),
          _TimelineLane(
            labelKey: AppTextKey.timelineTypePrescription,
            event: _TimelineMock.events[1],
            start: 0.42,
            width: 0.32,
          ),
          const SizedBox(height: AppSpacing.md),
          _TimelineLane(
            labelKey: AppTextKey.timelineTypeDiagnosis,
            event: _TimelineMock.events[2],
            start: 0.04,
            width: 0.38,
          ),
        ],
      ),
    );
  }
}

class _TimelineScale extends StatelessWidget {
  const _TimelineScale();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: _TimelineLayout.laneLabelWidth),
        Expanded(
          child: Container(
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _ScaleTick(label: context.tr(AppTextKey.timelineMonthApril)),
                const _ScaleTick(label: '08'),
                const _ScaleTick(label: '13'),
                _ScaleTick(label: context.tr(AppTextKey.timelineYear2026)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScaleTick extends StatelessWidget {
  const _ScaleTick({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.placeholder,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TimelineLane extends StatelessWidget {
  const _TimelineLane({
    required this.labelKey,
    required this.event,
    required this.start,
    required this.width,
  });

  final AppTextKey labelKey;
  final _TimelineEventData event;
  final double start;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TimelineLayout.laneHeight,
      child: Row(
        children: [
          SizedBox(
            width: _TimelineLayout.laneLabelWidth,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: event.tone.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(event.icon, color: event.tone, size: 15),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr(labelKey),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    const _TimelineTrackGrid(),
                    Positioned(
                      left: constraints.maxWidth * start,
                      top: 14,
                      width: constraints.maxWidth * width,
                      child: _RoadmapBar(event: event),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTrackGrid extends StatelessWidget {
  const _TimelineTrackGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 8; i++)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: AppColors.borderFaint, width: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoadmapBar extends StatelessWidget {
  const _RoadmapBar({required this.event});

  final _TimelineEventData event;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.tr(event.bodyKey),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: event.tone.withValues(alpha: event.critical ? 0.12 : 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: event.tone.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(event.titleKey),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: event.tone,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.more_horiz_rounded, color: event.tone, size: 15),
          ],
        ),
      ),
    );
  }
}

class _TimelineContextCard extends StatelessWidget {
  const _TimelineContextCard();

  @override
  Widget build(BuildContext context) {
    final auditLabel = context.appLocale == AppLocale.ar ? 'تدقيق' : 'Audit';
    return SectionCard(
      title: context.tr(AppTextKey.timelinePolicyTitle),
      minHeight: _TimelineLayout.contextMinHeight,
      trailing: StatusBadge(
        label: auditLabel,
        tone: BadgeTone.neutral,
        icon: Icons.verified_user_outlined,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(AppTextKey.timelinePolicyBody),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedInk,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TimelineSummaryTile(
            icon: Icons.science_outlined,
            label: context.tr(AppTextKey.timelineQuickOpenLab),
            tone: AppColors.critical,
          ),
          const SizedBox(height: AppSpacing.sm),
          _TimelineSummaryTile(
            icon: Icons.medication_outlined,
            label: context.tr(AppTextKey.timelineQuickOpenPrescription),
            tone: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _TimelineSummaryTile(
            icon: Icons.medical_information_outlined,
            label: context.tr(AppTextKey.timelineQuickOpenDiagnosis),
            tone: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          StatusBadge(
            label: context.tr(AppTextKey.timelineTypeAll),
            tone: BadgeTone.primary,
            icon: Icons.timeline_rounded,
          ),
        ],
      ),
    );
  }
}

class _TimelineSummaryTile extends StatelessWidget {
  const _TimelineSummaryTile({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: tone, size: 15),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.placeholder,
          ),
        ],
      ),
    );
  }
}
