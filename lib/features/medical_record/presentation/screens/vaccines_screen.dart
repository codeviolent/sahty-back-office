import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sahty_back_office/core/widgets/section_dispatcher.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clinical_session_gate.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/section_helpers.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/dossier_models.dart';
import '../bloc/dossier/dossier_bloc.dart';
import '../bloc/dossier/dossier_event.dart';
import '../bloc/dossier/dossier_state.dart';

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
    return ClinicalSessionGate(builder: (s) => _VaccinesBlocView(session: s));
  }
}

class _VaccinesBlocView extends StatelessWidget {
  final PatientSession session;
  const _VaccinesBlocView({required this.session});
  @override
  Widget build(BuildContext context) {
    return SectionDispatcher(
      section: DossierSection.vaccinations,
      builder: (ctx, state, session) {
        final raw = getSectionData(state, DossierSection.vaccinations) ?? [];
        final items = raw
            .map((e) => VaccinationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return _VaccinesContent(session: session, items: items);
      },
    );
  }
}

class _VaccinesContent extends StatelessWidget {
  final PatientSession session;
  final List<VaccinationItem> items;
  const _VaccinesContent({required this.session, required this.items});

  @override
  Widget build(BuildContext context) {
    //final active = items.where((i) => i.status == 'active').toList();
    final allItems = items.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VaccinesScheduleCard(allItem: allItems),
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
  final List<VaccinationItem> allItem;
  const _VaccinesScheduleCard({required this.allItem});

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
          for (int i = 0; i < allItem.length; i++) ...[
            _VaccineRow(item: allItem[i]),
            if (i < allItem.length - 1)
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

  final VaccinationItem item;

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
                item.vaccineName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: item.status == 'pending'
                      ? AppColors.warning
                      : AppColors.normal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Text(item.status)),
            Expanded(child: Text(item.dosesReceived.toString())),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(
                  label: item.dosesRequired.toString(),
                  tone: item.status == 'pending'
                      ? BadgeTone.warning
                      : BadgeTone.normal,
                ),
              ),
            ),
            Expanded(child: Text(item.nextDoseDate)),
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
