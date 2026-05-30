import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';

enum _AccessStatus { activeSession, needsReason, restricted }

abstract final class _PatientSearchLayout {
  static const double controlCardMinHeight = 188;
  static const double resultsCardMinHeight = 260;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

class _PatientResult {
  const _PatientResult({
    required this.nameKey,
    required this.fileNo,
    required this.maskedNni,
    required this.age,
    required this.lastVisitKey,
    required this.status,
  });

  final AppTextKey nameKey;
  final String fileNo;
  final String maskedNni;
  final int age;
  final AppTextKey lastVisitKey;
  final _AccessStatus status;
}

abstract final class _PatientSearchMock {
  static const results = [
    _PatientResult(
      nameKey: AppTextKey.patientSearchPatientFatima,
      fileNo: 'MR-2048',
      maskedNni: '**** **** 4821',
      age: 56,
      lastVisitKey: AppTextKey.patientSearchVisitApr13,
      status: _AccessStatus.needsReason,
    ),
    _PatientResult(
      nameKey: AppTextKey.patientSearchPatientAli,
      fileNo: 'MR-1182',
      maskedNni: '**** **** 9134',
      age: 44,
      lastVisitKey: AppTextKey.patientSearchVisitApr11,
      status: _AccessStatus.activeSession,
    ),
    _PatientResult(
      nameKey: AppTextKey.patientSearchPatientMariam,
      fileNo: 'MR-0931',
      maskedNni: '**** **** 2049',
      age: 63,
      lastVisitKey: AppTextKey.patientSearchVisitApr08,
      status: _AccessStatus.restricted,
    ),
  ];
}

class PatientSearchScreen extends StatelessWidget {
  const PatientSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SearchControlCard(),
        const SizedBox(height: AppSpacing.xl),
        _ResultsCard(results: _PatientSearchMock.results),
      ],
    );
  }
}

class _SearchControlCard extends StatelessWidget {
  const _SearchControlCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.patientSearchCardTitle),
      subtitle: context.tr(AppTextKey.patientSearchCardSubtitle),
      minHeight: _PatientSearchLayout.controlCardMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.patientSearchReadOnlyPreview),
        tone: BadgeTone.neutral,
        icon: Icons.visibility_outlined,
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: context.tr(AppTextKey.patientSearchHint),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 18),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _FilterChip(
                labelKey: AppTextKey.patientSearchFilterAge,
                icon: Icons.cake_outlined,
              ),
              _FilterChip(
                labelKey: AppTextKey.patientSearchFilterSex,
                icon: Icons.wc_outlined,
              ),
              _FilterChip(
                labelKey: AppTextKey.patientSearchFilterLastVisit,
                icon: Icons.history,
              ),
              _FilterChip(
                labelKey: AppTextKey.patientSearchFilterDoctor,
                icon: Icons.badge,
              ),
              _FilterChip(
                labelKey: AppTextKey.patientSearchFilterActiveSession,
                icon: Icons.lock_clock,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.labelKey, required this.icon});

  final AppTextKey labelKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: context.tr(labelKey),
      tone: BadgeTone.neutral,
      icon: icon,
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.results});

  final List<_PatientResult> results;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.patientSearchResultsTitle),
      subtitle: context.tr(AppTextKey.patientSearchResultsSubtitle),
      minHeight: _PatientSearchLayout.resultsCardMinHeight,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _TableHeader(
            columns: [
              AppTextKey.patientSearchColumnPatient,
              AppTextKey.patientSearchColumnRecordNni,
              AppTextKey.patientSearchColumnAge,
              AppTextKey.patientSearchColumnLastVisit,
              AppTextKey.patientSearchColumnAccess,
            ],
            flexes: [3, 3, 1, 2, 2],
          ),
          for (int i = 0; i < results.length; i++) ...[
            _PatientRow(patient: results[i]),
            if (i < results.length - 1)
              const Divider(
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});

  final _PatientResult patient;

  @override
  Widget build(BuildContext context) {
    final (labelKey, tone) = switch (patient.status) {
      _AccessStatus.activeSession => (
        AppTextKey.patientSearchStatusOpen,
        BadgeTone.neutral,
      ),
      _AccessStatus.needsReason => (
        AppTextKey.patientSearchStatusReason,
        BadgeTone.neutral,
      ),
      _AccessStatus.restricted => (
        AppTextKey.patientSearchStatusRestricted,
        BadgeTone.critical,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _PatientSearchLayout.rowHeight,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                context.tr(patient.nameKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${patient.fileNo}  ·  ${patient.maskedNni}',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${patient.age} ${context.tr(AppTextKey.patientSearchAgeSuffix)}',
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                context.tr(patient.lastVisitKey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: StatusBadge(label: context.tr(labelKey), tone: tone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns, required this.flexes});

  final List<AppTextKey> columns;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _PatientSearchLayout.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.65),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < columns.length; i++)
            Expanded(
              flex: flexes[i],
              child: Text(
                context.tr(columns[i]).toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
