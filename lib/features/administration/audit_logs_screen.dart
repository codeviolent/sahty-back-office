import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _AuditLayout {
  static const double logMinHeight = 288;
  static const double alertMinHeight = 210;
  static const double policyMinHeight = 118;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AuditLogCard(),
        const SizedBox(height: AppSpacing.xl),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SuspiciousAlertsCard()),
            SizedBox(width: AppSpacing.xl),
            Expanded(child: _ImmutablePolicyCard()),
          ],
        ),
      ],
    );
  }
}

class _AuditEntry {
  const _AuditEntry({
    required this.actorKey,
    required this.actionKey,
    required this.targetKey,
    required this.deviceKey,
    required this.timeKey,
    this.critical = false,
  });

  final AppTextKey actorKey;
  final AppTextKey actionKey;
  final AppTextKey targetKey;
  final AppTextKey deviceKey;
  final AppTextKey timeKey;
  final bool critical;
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard();

  static const entries = [
    _AuditEntry(
      actorKey: AppTextKey.auditActorDoctor,
      actionKey: AppTextKey.auditActionOpenedRecord,
      targetKey: AppTextKey.auditTargetPatientFile,
      deviceKey: AppTextKey.auditDeviceClinic,
      timeKey: AppTextKey.auditTimeNow,
    ),
    _AuditEntry(
      actorKey: AppTextKey.auditActorAdmin,
      actionKey: AppTextKey.auditActionApprovedDevice,
      targetKey: AppTextKey.auditTargetMacbook,
      deviceKey: AppTextKey.auditDeviceClinic,
      timeKey: AppTextKey.auditTimeEarlier,
    ),
    _AuditEntry(
      actorKey: AppTextKey.auditActorSystem,
      actionKey: AppTextKey.auditActionFailedLogin,
      targetKey: AppTextKey.auditTargetLogin,
      deviceKey: AppTextKey.auditDeviceUnknown,
      timeKey: AppTextKey.auditTimeEarlier,
      critical: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.auditLogTitle),
      subtitle: context.tr(AppTextKey.auditLogSubtitle),
      minHeight: _AuditLayout.logMinHeight,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _AuditHeader(),
          for (int i = 0; i < entries.length; i++) ...[
            _AuditRow(entry: entries[i]),
            if (i < entries.length - 1)
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

class _AuditHeader extends StatelessWidget {
  const _AuditHeader();

  @override
  Widget build(BuildContext context) {
    const columns = [
      AppTextKey.auditColumnActor,
      AppTextKey.auditColumnAction,
      AppTextKey.auditColumnTarget,
      AppTextKey.auditColumnDevice,
      AppTextKey.auditColumnTime,
    ];

    return Container(
      height: _AuditLayout.headerHeight,
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

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final _AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.critical ? AppColors.critical : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _AuditLayout.rowHeight,
        child: Row(
          children: [
            Expanded(child: Text(context.tr(entry.actorKey))),
            Expanded(
              child: Text(
                context.tr(entry.actionKey),
                style: TextStyle(
                  color: color,
                  fontWeight: entry.critical
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Text(context.tr(entry.targetKey))),
            Expanded(child: Text(context.tr(entry.deviceKey))),
            Expanded(child: Text(context.tr(entry.timeKey))),
          ],
        ),
      ),
    );
  }
}

class _SuspiciousAlertsCard extends StatelessWidget {
  const _SuspiciousAlertsCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.auditSuspiciousTitle),
      subtitle: context.tr(AppTextKey.auditSuspiciousSubtitle),
      minHeight: _AuditLayout.alertMinHeight,
      child: const Column(
        children: [
          _AlertTile(labelKey: AppTextKey.auditSuspiciousLocation),
          SizedBox(height: AppSpacing.md),
          _AlertTile(labelKey: AppTextKey.auditSuspiciousRepeatedOtp),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.labelKey});

  final AppTextKey labelKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.critical,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(context.tr(labelKey))),
          const StatusBadge(label: '!', tone: BadgeTone.critical),
        ],
      ),
    );
  }
}

class _ImmutablePolicyCard extends StatelessWidget {
  const _ImmutablePolicyCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.auditImmutableTitle),
      minHeight: _AuditLayout.policyMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.auditReadOnly),
        tone: BadgeTone.neutral,
        icon: Icons.lock_outline,
      ),
      child: Text(context.tr(AppTextKey.auditImmutableBody)),
    );
  }
}
