import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _QueueLayout {
  static const double queueMinHeight = 300;
  static const double rowHeight = 46;
  static const double policyMinHeight = 118;
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QueueCard(),
        const SizedBox(height: AppSpacing.xl),
        const _QueuePolicyCard(),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.queueTitle),
      subtitle: context.tr(AppTextKey.queueSubtitle),
      minHeight: _QueueLayout.queueMinHeight,
      child: const Column(
        children: [
          _QueueRow(
            patientKey: AppTextKey.appointmentsPatientMariam,
            priorityKey: AppTextKey.queueHighPriority,
            waitKey: AppTextKey.queueWaitLong,
            critical: true,
          ),
          SizedBox(height: AppSpacing.md),
          _QueueRow(
            patientKey: AppTextKey.appointmentsPatientFatima,
            priorityKey: AppTextKey.queueMediumPriority,
            waitKey: AppTextKey.queueWaitMedium,
          ),
          SizedBox(height: AppSpacing.md),
          _QueueRow(
            patientKey: AppTextKey.appointmentsPatientAli,
            priorityKey: AppTextKey.queueLowPriority,
            waitKey: AppTextKey.queueWaitShort,
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.patientKey,
    required this.priorityKey,
    required this.waitKey,
    this.critical = false,
  });

  final AppTextKey patientKey;
  final AppTextKey priorityKey;
  final AppTextKey waitKey;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? AppColors.critical : AppColors.mutedInk;

    return Container(
      height: _QueueLayout.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: critical ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.tr(patientKey),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          StatusBadge(
            label: context.tr(priorityKey),
            tone: critical ? BadgeTone.critical : BadgeTone.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(context.tr(waitKey)),
        ],
      ),
    );
  }
}

class _QueuePolicyCard extends StatelessWidget {
  const _QueuePolicyCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.queuePolicyTitle),
      minHeight: _QueueLayout.policyMinHeight,
      child: Text(context.tr(AppTextKey.queuePolicyBody)),
    );
  }
}
