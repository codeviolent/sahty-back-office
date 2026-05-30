import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clinical_alert_banner.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';

abstract final class _PrescriptionsLayout {
  static const double tableMinHeight = 260;
  static const double actionCardMinHeight = 188;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClinicalAlertBanner(
          title: context.tr(AppTextKey.prescriptionsWarningTitle),
          message: context.tr(AppTextKey.prescriptionsWarningMessage),
          isCritical: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        const _PrescriptionTable(),
        const SizedBox(height: AppSpacing.xl),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PrescriptionActionsCard()),
            SizedBox(width: AppSpacing.xl),
            Expanded(child: _InteractionPolicyCard()),
          ],
        ),
      ],
    );
  }
}

class _PrescriptionData {
  const _PrescriptionData({
    required this.medicationKey,
    required this.doseKey,
    required this.frequencyKey,
    required this.durationKey,
    required this.statusKey,
  });

  final AppTextKey medicationKey;
  final AppTextKey doseKey;
  final AppTextKey frequencyKey;
  final AppTextKey durationKey;
  final AppTextKey statusKey;
}

class _PrescriptionTable extends StatelessWidget {
  const _PrescriptionTable();

  static const _items = [
    _PrescriptionData(
      medicationKey: AppTextKey.prescriptionsMedicationMetformin,
      doseKey: AppTextKey.prescriptionsDoseMetformin,
      frequencyKey: AppTextKey.prescriptionsFrequencyTwice,
      durationKey: AppTextKey.prescriptionsDurationOngoing,
      statusKey: AppTextKey.prescriptionsStatusActive,
    ),
    _PrescriptionData(
      medicationKey: AppTextKey.prescriptionsMedicationInsulin,
      doseKey: AppTextKey.prescriptionsDoseInsulin,
      frequencyKey: AppTextKey.prescriptionsFrequencyEvening,
      durationKey: AppTextKey.prescriptionsDurationOngoing,
      statusKey: AppTextKey.prescriptionsStatusMonitoring,
    ),
    _PrescriptionData(
      medicationKey: AppTextKey.prescriptionsMedicationAtorvastatin,
      doseKey: AppTextKey.prescriptionsDoseAtorvastatin,
      frequencyKey: AppTextKey.prescriptionsFrequencyEvening,
      durationKey: AppTextKey.prescriptionsDurationOngoing,
      statusKey: AppTextKey.prescriptionsStatusCompleted,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.prescriptionsListTitle),
      subtitle: context.tr(AppTextKey.prescriptionsListSubtitle),
      minHeight: _PrescriptionsLayout.tableMinHeight,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _PrescriptionHeader(),
          for (int i = 0; i < _items.length; i++) ...[
            _PrescriptionRow(data: _items[i]),
            if (i < _items.length - 1)
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

class _PrescriptionHeader extends StatelessWidget {
  const _PrescriptionHeader();

  @override
  Widget build(BuildContext context) {
    const columns = [
      AppTextKey.prescriptionsColumnMedication,
      AppTextKey.prescriptionsColumnDose,
      AppTextKey.prescriptionsColumnFrequency,
      AppTextKey.prescriptionsColumnDuration,
      AppTextKey.prescriptionsColumnStatus,
    ];

    return Container(
      height: _PrescriptionsLayout.headerHeight,
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

class _PrescriptionRow extends StatelessWidget {
  const _PrescriptionRow({required this.data});

  final _PrescriptionData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _PrescriptionsLayout.rowHeight,
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(data.medicationKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Text(context.tr(data.doseKey))),
            Expanded(child: Text(context.tr(data.frequencyKey))),
            Expanded(child: Text(context.tr(data.durationKey))),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(
                  label: context.tr(data.statusKey),
                  tone: BadgeTone.neutral,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionActionsCard extends StatelessWidget {
  const _PrescriptionActionsCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.prescriptionsActionsTitle),
      subtitle: context.tr(AppTextKey.prescriptionsActionsSubtitle),
      minHeight: _PrescriptionsLayout.actionCardMinHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mutedInk,
                    foregroundColor: AppColors.surface,
                  ),
                  onPressed: () => _confirmExport(
                    context,
                    onConfirm: () {
                      // Mock: in production this calls the print API
                    },
                  ),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(context.tr(AppTextKey.prescriptionsPrint)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mutedInk,
                    side: const BorderSide(color: AppColors.borderSoft),
                  ),
                  onPressed: () => _confirmExport(
                    context,
                    onConfirm: () {
                      // Mock: in production this calls the PDF generation API
                    },
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(context.tr(AppTextKey.prescriptionsPdf)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.tr(AppTextKey.prescriptionsReadOnlyPolicy)),
        ],
      ),
    );
  }
}

/// Shows a confirmation dialog before any medical data export/print — spec §6 requirement.
void _confirmExport(BuildContext context, {required VoidCallback onConfirm}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr(AppTextKey.prescriptionsConfirmExportTitle)),
      content: Text(ctx.tr(AppTextKey.prescriptionsConfirmExportBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.tr(AppTextKey.prescriptionsCancelAction)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.mutedInk),
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: Text(ctx.tr(AppTextKey.prescriptionsConfirmAction)),
        ),
      ],
    ),
  );
}

class _InteractionPolicyCard extends StatelessWidget {
  const _InteractionPolicyCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.prescriptionsInteractionTitle),
      minHeight: _PrescriptionsLayout.actionCardMinHeight,
      child: Text(context.tr(AppTextKey.prescriptionsInteractionBody)),
    );
  }
}
