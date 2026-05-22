import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _AdministrationLayout {
  static const double rolesMinHeight = 288;
  static const double sideCardMinHeight = 234;
  static const double policyMinHeight = 122;
  static const double rowHeight = 46;
}

class AdministrationScreen extends StatelessWidget {
  const AdministrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _RolesCard()),
            SizedBox(width: AppSpacing.xl),
            Expanded(flex: 5, child: _VisibilityCard()),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _TrustedDevicesCard()),
            SizedBox(width: AppSpacing.xl),
            Expanded(child: _ApprovalCard()),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const _PolicyCard(),
      ],
    );
  }
}

class _RoleItem {
  const _RoleItem({
    required this.roleKey,
    required this.permissions,
    this.restricted = false,
  });

  final AppTextKey roleKey;
  final List<AppTextKey> permissions;
  final bool restricted;
}

class _RolesCard extends StatelessWidget {
  const _RolesCard();

  static const items = [
    _RoleItem(
      roleKey: AppTextKey.adminRoleSuperAdmin,
      permissions: [
        AppTextKey.adminPermissionRead,
        AppTextKey.adminPermissionWrite,
        AppTextKey.adminPermissionApprove,
      ],
      restricted: true,
    ),
    _RoleItem(
      roleKey: AppTextKey.adminRoleClinicalAdmin,
      permissions: [
        AppTextKey.adminPermissionRead,
        AppTextKey.adminPermissionApprove,
      ],
    ),
    _RoleItem(
      roleKey: AppTextKey.adminRoleDoctor,
      permissions: [AppTextKey.adminPermissionRead],
    ),
    _RoleItem(
      roleKey: AppTextKey.adminRoleLabTech,
      permissions: [AppTextKey.adminPermissionRead],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.adminRolesTitle),
      subtitle: context.tr(AppTextKey.adminRolesSubtitle),
      minHeight: _AdministrationLayout.rolesMinHeight,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _RoleRow(item: items[i]),
            if (i < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.item});

  final _RoleItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _AdministrationLayout.rowHeight,
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(item.roleKey),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final permission in item.permissions)
                StatusBadge(
                  label: context.tr(permission),
                  tone:
                      item.restricted &&
                          permission == AppTextKey.adminPermissionApprove
                      ? BadgeTone.critical
                      : BadgeTone.neutral,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.adminVisibilityTitle),
      subtitle: context.tr(AppTextKey.adminVisibilitySubtitle),
      minHeight: _AdministrationLayout.rolesMinHeight,
      child: const Column(
        children: [
          _RuleTile(
            icon: Icons.medical_information_outlined,
            labelKey: AppTextKey.adminVisibilityClinical,
          ),
          SizedBox(height: AppSpacing.md),
          _RuleTile(
            icon: Icons.visibility_off_outlined,
            labelKey: AppTextKey.adminVisibilityFinancial,
          ),
          SizedBox(height: AppSpacing.md),
          _RuleTile(
            icon: Icons.policy_outlined,
            labelKey: AppTextKey.adminVisibilityAudit,
          ),
        ],
      ),
    );
  }
}

class _TrustedDevicesCard extends StatelessWidget {
  const _TrustedDevicesCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.adminTrustedDevicesTitle),
      subtitle: context.tr(AppTextKey.adminTrustedDevicesSubtitle),
      minHeight: _AdministrationLayout.sideCardMinHeight,
      child: const Column(
        children: [
          _RuleTile(
            icon: Icons.computer_outlined,
            labelKey: AppTextKey.adminDeviceCabinet,
          ),
          SizedBox(height: AppSpacing.md),
          _RuleTile(
            icon: Icons.tablet_mac_outlined,
            labelKey: AppTextKey.adminDeviceMobile,
          ),
          SizedBox(height: AppSpacing.md),
          _RuleTile(
            icon: Icons.device_unknown_outlined,
            labelKey: AppTextKey.adminDevicePending,
            critical: true,
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.adminApprovalTitle),
      minHeight: _AdministrationLayout.sideCardMinHeight,
      trailing: const StatusBadge(
        label: '1',
        tone: BadgeTone.critical,
        icon: Icons.priority_high_rounded,
      ),
      child: Text(context.tr(AppTextKey.adminApprovalBody)),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.adminPolicyTitle),
      minHeight: _AdministrationLayout.policyMinHeight,
      child: Text(context.tr(AppTextKey.adminPolicyBody)),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.icon,
    required this.labelKey,
    this.critical = false,
  });

  final IconData icon;
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
          Icon(icon, color: color, size: 21),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(context.tr(labelKey))),
        ],
      ),
    );
  }
}
