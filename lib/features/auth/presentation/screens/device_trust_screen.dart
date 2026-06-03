import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/services/device_info_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';

enum _TrustState { trusted }

enum _FlowStep { done, active, locked }

// ── _DeviceFact — value est maintenant une String réelle ──────────
// (plus de valueKey AppTextKey)
class _DeviceFact {
  const _DeviceFact({
    required this.icon,
    required this.labelKey,
    required this.value, // ← STRING réelle, plus AppTextKey
  });

  final IconData icon;
  final AppTextKey labelKey;
  final String value; // ← dynamique
}

class _AuditEntry {
  const _AuditEntry({
    required this.date,
    required this.event,
    required this.detail,
    required this.actor,
  });

  final String date; // ← STRING réelle, plus AppTextKey
  final String event;
  final String detail;
  final String actor;
}

// ── DeviceTrustScreen — StatefulWidget pour charger DeviceInfo ─────
class DeviceTrustScreen extends StatefulWidget {
  const DeviceTrustScreen({super.key, required this.onDeviceApproved});

  final VoidCallback onDeviceApproved;

  @override
  State<DeviceTrustScreen> createState() => _DeviceTrustScreenState();
}

class _DeviceTrustScreenState extends State<DeviceTrustScreen> {
  DeviceInfo? _deviceInfo;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceInfoService.load();
    if (mounted) setState(() => _deviceInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement → spinner bref transparent
    if (_deviceInfo == null) {
      return const ColoredBox(
        color: AppColors.canvas,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Construire les facts avec les vraies valeurs
    final facts = [
      _DeviceFact(
        icon: Icons.computer_rounded,
        labelKey: AppTextKey.deviceNameLabel,
        value: _deviceInfo!.deviceName, // ← réel
      ),
      _DeviceFact(
        icon: Icons.laptop_mac_rounded,
        labelKey: AppTextKey.operatingSystemLabel,
        value: _deviceInfo!.operatingSystem, // ← réel
      ),
      _DeviceFact(
        icon: Icons.apps_rounded,
        labelKey: AppTextKey.appVersionLabel,
        value: _deviceInfo!.appVersion, // ← réel
      ),
      _DeviceFact(
        icon: Icons.access_time_rounded,
        labelKey: AppTextKey.lastLoginLabel,
        value: _deviceInfo!.lastLogin, // ← réel
      ),
    ];

    // Entrée audit log avec la date/heure réelle
    final now = _deviceInfo!.loginDateTime;
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final dayStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}  $hh:$mm';

    final auditLog = [
      _AuditEntry(
        date: dayStr,
        event: context.tr(AppTextKey.deviceAuditEventApproved),
        detail: context.tr(AppTextKey.deviceAuditDetailApproved),
        actor: context.tr(AppTextKey.deviceAuditActorSystem),
      ),
    ];

    final canApprove = true; // trustState == trusted

    return ColoredBox(
      color: AppColors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 960;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (AppSpacing.xl * 2),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.borderFaint),
                      boxShadow: AppColors.floatingShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StandaloneHeader(
                            canApprove: canApprove,
                            onDeviceApproved: widget.onDeviceApproved,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          if (isCompact)
                            _CompactContent(facts: facts, auditLog: auditLog)
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 5,
                                  child: _TrustHeroCard(),
                                ),
                                const SizedBox(width: AppSpacing.xxl),
                                Expanded(
                                  flex: 6,
                                  child: _VerificationPanel(
                                    facts: facts,
                                    auditLog: auditLog,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── _StandaloneHeader — inchangé ───────────────────────────────────
class _StandaloneHeader extends StatelessWidget {
  const _StandaloneHeader({
    required this.canApprove,
    required this.onDeviceApproved,
  });

  final bool canApprove;
  final VoidCallback onDeviceApproved;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.lg,
      spacing: AppSpacing.xl,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BrandMark(),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(AppTextKey.appTitle),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  context.tr(AppTextKey.routeDeviceTrust),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
                ),
              ],
            ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            const _LocaleSwitch(),
            FilledButton.icon(
              onPressed: canApprove ? onDeviceApproved : null,
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text(context.tr(AppTextKey.approveDeviceAndOpenDashboard)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.glassSurfaceStrong,
                disabledBackgroundColor: AppColors.border.withValues(
                  alpha: 0.45,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── _BrandMark, _LocaleSwitch, _LocaleButton — inchangés ──────────
class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Icon(
          Icons.health_and_safety_outlined,
          color: AppColors.primaryDark,
          size: 24,
        ),
      ),
    );
  }
}

class _LocaleSwitch extends StatelessWidget {
  const _LocaleSwitch();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LocaleButton(
            label: context.tr(AppTextKey.langFr),
            active: context.appLocale == AppLocale.fr,
            onPressed: () => context.setAppLocale(AppLocale.fr),
          ),
          _LocaleButton(
            label: context.tr(AppTextKey.langAr),
            active: context.appLocale == AppLocale.ar,
            onPressed: () => context.setAppLocale(AppLocale.ar),
          ),
        ],
      ),
    );
  }
}

class _LocaleButton extends StatelessWidget {
  const _LocaleButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });
  final String label;
  final bool active;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? AppColors.glassSurfaceStrong : AppColors.mutedInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── _CompactContent — reçoit facts + auditLog ──────────────────────
class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.facts, required this.auditLog});

  final List<_DeviceFact> facts;
  final List<_AuditEntry> auditLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TrustHeroCard(),
        const SizedBox(height: AppSpacing.xl),
        _VerificationPanel(facts: facts, auditLog: auditLog),
      ],
    );
  }
}

// ── _TrustHeroCard — inchangé ──────────────────────────────────────
class _TrustHeroCard extends StatelessWidget {
  const _TrustHeroCard();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(
              label: context.tr(AppTextKey.trusted),
              tone: BadgeTone.normal,
              icon: Icons.verified_user_rounded,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.devices_rounded,
                color: AppColors.glassSurfaceStrong,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.tr(AppTextKey.deviceHeadline),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr(AppTextKey.deviceSubhead),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _PolicyNote(
              title: context.tr(AppTextKey.deviceTrustVerifiedTitle),
              message: context.tr(AppTextKey.deviceTrustVerifiedMessage),
            ),
            const SizedBox(height: AppSpacing.xl),
            _AssuranceRow(
              icon: Icons.account_circle_outlined,
              label: context.tr(AppTextKey.deviceAssuranceMfa),
            ),
            const SizedBox(height: AppSpacing.md),
            _AssuranceRow(
              icon: Icons.lock_outline,
              label: context.tr(AppTextKey.deviceAssuranceEncrypted),
            ),
            const SizedBox(height: AppSpacing.md),
            _AssuranceRow(
              icon: Icons.admin_panel_settings_outlined,
              label: context.tr(AppTextKey.deviceAssuranceAdmin),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _PolicyNote — inchangé ─────────────────────────────────────────
class _PolicyNote extends StatelessWidget {
  const _PolicyNote({required this.title, required this.message});
  final String title, message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AssuranceRow — inchangé ───────────────────────────────────────
class _AssuranceRow extends StatelessWidget {
  const _AssuranceRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primaryDark),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── _VerificationPanel — reçoit facts + auditLog ───────────────────
class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({required this.facts, required this.auditLog});

  final List<_DeviceFact> facts;
  final List<_AuditEntry> auditLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DeviceIdentityCard(facts: facts),
        const SizedBox(height: AppSpacing.lg),
        const _AccessFlowCard(),
        const SizedBox(height: AppSpacing.lg),
        _AuditLogCard(auditLog: auditLog),
      ],
    );
  }
}

// ── _DeviceIdentityCard — reçoit facts avec valeurs réelles ────────
class _DeviceIdentityCard extends StatelessWidget {
  const _DeviceIdentityCard({required this.facts});
  final List<_DeviceFact> facts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.deviceIdentityTitle),
      subtitle: context.tr(AppTextKey.deviceIdentitySubtitle),
      trailing: StatusBadge(
        label: context.tr(AppTextKey.trusted),
        tone: BadgeTone.normal,
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            _DeviceFactRow(fact: facts[i]),
            if (i < facts.length - 1)
              const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFaint,
              ),
          ],
        ],
      ),
    );
  }
}

// ── _DeviceFactRow — affiche fact.value au lieu de context.tr(valueKey)
class _DeviceFactRow extends StatelessWidget {
  const _DeviceFactRow({required this.fact});
  final _DeviceFact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(fact.icon, size: 17, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 132,
            child: Text(
              context.tr(fact.labelKey),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
            ),
          ),
          Expanded(
            child: Text(
              fact.value, // ← VALEUR RÉELLE (plus context.tr)
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AccessFlowCard — inchangé ─────────────────────────────────────
class _AccessFlowCard extends StatelessWidget {
  const _AccessFlowCard();
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.accessGate),
      subtitle: context.tr(AppTextKey.deviceSecurityPosture),
      child: const Column(
        children: [
          _FlowStepRow(
            labelKey: AppTextKey.accessGateLogin,
            step: _FlowStep.done,
          ),
          _FlowConnector(),
          _FlowStepRow(
            labelKey: AppTextKey.accessGateDevice,
            step: _FlowStep.active,
          ),
          _FlowConnector(),
          _FlowStepRow(
            labelKey: AppTextKey.accessGateDashboard,
            step: _FlowStep.locked,
          ),
        ],
      ),
    );
  }
}

// ── _FlowStepRow — inchangé ────────────────────────────────────────
class _FlowStepRow extends StatelessWidget {
  const _FlowStepRow({required this.labelKey, required this.step});
  final AppTextKey labelKey;
  final _FlowStep step;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (step) {
      _FlowStep.done => (AppColors.normal, Icons.check_circle_rounded),
      _FlowStep.active => (
        AppColors.warning,
        Icons.radio_button_checked_rounded,
      ),
      _FlowStep.locked => (
        AppColors.mutedInk.withValues(alpha: 0.34),
        Icons.lock_outline,
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            context.tr(labelKey),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: step == _FlowStep.locked
                  ? AppColors.mutedInk.withValues(alpha: 0.50)
                  : AppColors.ink,
              fontWeight: step == _FlowStep.active
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _FlowConnector — inchangé ──────────────────────────────────────
class _FlowConnector extends StatelessWidget {
  const _FlowConnector();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: AppSpacing.md + 8),
      child: SizedBox(
        height: 18,
        child: VerticalDivider(
          color: AppColors.borderFaint,
          width: 1,
          thickness: 1,
        ),
      ),
    );
  }
}

// ── _AuditLogCard — reçoit auditLog avec valeurs réelles ───────────
class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.auditLog});
  final List<_AuditEntry> auditLog;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.deviceAuditTrail),
      subtitle: context.tr(AppTextKey.deviceSessionPolicy),
      trailing: const Icon(
        Icons.history_rounded,
        size: 18,
        color: AppColors.primaryDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PolicyNote(
            title: context.tr(AppTextKey.deviceSessionPolicy),
            message: context.tr(AppTextKey.deviceSessionPolicyBody),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final entry in auditLog) _AuditEntryWidget(entry: entry),
        ],
      ),
    );
  }
}

// ── _AuditEntryWidget — affiche les strings réelles ────────────────
class _AuditEntryWidget extends StatelessWidget {
  const _AuditEntryWidget({required this.entry});
  final _AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 15,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  entry.date, // ← DATE RÉELLE
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                entry.actor, // ← ACTEUR RÉEL
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            entry.event, // ← EVENT RÉEL
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.detail, // ← DÉTAIL RÉEL
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedInk,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';

// enum _TrustState { trusted }

// enum _FlowStep { done, active, locked }

// class _DeviceFact {
//   const _DeviceFact({
//     required this.icon,
//     required this.labelKey,
//     required this.valueKey,
//   });

//   final IconData icon;
//   final AppTextKey labelKey;
//   final AppTextKey valueKey;
// }

// class _AuditEntry {
//   const _AuditEntry({
//     required this.dateKey,
//     required this.eventKey,
//     required this.detailKey,
//     required this.actorKey,
//   });

//   final AppTextKey dateKey;
//   final AppTextKey eventKey;
//   final AppTextKey detailKey;
//   final AppTextKey actorKey;
// }

// abstract final class _DeviceTrustModel {
//   static const trustState = _TrustState.trusted;

//   static const facts = [
//     _DeviceFact(
//       icon: Icons.computer_rounded,
//       labelKey: AppTextKey.deviceNameLabel,
//       valueKey: AppTextKey.deviceName,
//     ),
//     _DeviceFact(
//       icon: Icons.laptop_mac_rounded,
//       labelKey: AppTextKey.operatingSystemLabel,
//       valueKey: AppTextKey.operatingSystem,
//     ),
//     _DeviceFact(
//       icon: Icons.apps_rounded,
//       labelKey: AppTextKey.appVersionLabel,
//       valueKey: AppTextKey.appVersion,
//     ),
//     _DeviceFact(
//       icon: Icons.access_time_rounded,
//       labelKey: AppTextKey.lastLoginLabel,
//       valueKey: AppTextKey.lastLogin,
//     ),
//   ];

//   static const auditLog = [
//     _AuditEntry(
//       dateKey: AppTextKey.deviceAuditDatePrimary,
//       eventKey: AppTextKey.deviceAuditEventApproved,
//       detailKey: AppTextKey.deviceAuditDetailApproved,
//       actorKey: AppTextKey.deviceAuditActorSystem,
//     ),
//   ];
// }

// class DeviceTrustScreen extends StatelessWidget {
//   const DeviceTrustScreen({super.key, required this.onDeviceApproved});

//   final VoidCallback onDeviceApproved;

//   @override
//   Widget build(BuildContext context) {
//     final canApprove = _DeviceTrustModel.trustState == _TrustState.trusted;

//     return ColoredBox(
//       color: AppColors.canvas,
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final isCompact = constraints.maxWidth < 960;

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(AppSpacing.xl),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight: constraints.maxHeight - (AppSpacing.xl * 2),
//               ),
//               child: Center(
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 1180),
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       color: AppColors.surface,
//                       borderRadius: BorderRadius.circular(30),
//                       border: Border.all(color: AppColors.borderFaint),
//                       boxShadow: AppColors.floatingShadow,
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(AppSpacing.xxl),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           _StandaloneHeader(
//                             canApprove: canApprove,
//                             onDeviceApproved: onDeviceApproved,
//                           ),
//                           const SizedBox(height: AppSpacing.xxl),
//                           if (isCompact)
//                             const _CompactContent()
//                           else
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Expanded(flex: 5, child: _TrustHeroCard()),
//                                 SizedBox(width: AppSpacing.xxl),
//                                 Expanded(flex: 6, child: _VerificationPanel()),
//                               ],
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _StandaloneHeader extends StatelessWidget {
//   const _StandaloneHeader({
//     required this.canApprove,
//     required this.onDeviceApproved,
//   });

//   final bool canApprove;
//   final VoidCallback onDeviceApproved;

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       alignment: WrapAlignment.spaceBetween,
//       crossAxisAlignment: WrapCrossAlignment.center,
//       runSpacing: AppSpacing.lg,
//       spacing: AppSpacing.xl,
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const _BrandMark(),
//             const SizedBox(width: AppSpacing.md),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(AppTextKey.appTitle),
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: AppColors.primaryDark,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: -0.2,
//                   ),
//                 ),
//                 Text(
//                   context.tr(AppTextKey.routeDeviceTrust),
//                   style: Theme.of(
//                     context,
//                   ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         Wrap(
//           crossAxisAlignment: WrapCrossAlignment.center,
//           spacing: AppSpacing.md,
//           runSpacing: AppSpacing.sm,
//           children: [
//             const _LocaleSwitch(),
//             FilledButton.icon(
//               onPressed: canApprove ? onDeviceApproved : null,
//               icon: const Icon(Icons.verified_rounded, size: 18),
//               label: Text(context.tr(AppTextKey.approveDeviceAndOpenDashboard)),
//               style: FilledButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: AppColors.glassSurfaceStrong,
//                 disabledBackgroundColor: AppColors.border.withValues(
//                   alpha: 0.45,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: AppSpacing.xl,
//                   vertical: AppSpacing.md,
//                 ),
//                 textStyle: const TextStyle(fontWeight: FontWeight.w800),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _BrandMark extends StatelessWidget {
//   const _BrandMark();

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 48,
//       height: 48,
//       child: SvgPicture.asset(
//         'assets/images/logo.svg',
//         fit: BoxFit.contain,
//         placeholderBuilder: (context) => const Icon(
//           Icons.health_and_safety_outlined,
//           color: AppColors.primaryDark,
//           size: 24,
//         ),
//       ),
//     );
//   }
// }

// class _LocaleSwitch extends StatelessWidget {
//   const _LocaleSwitch();

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         color: AppColors.glassSurfaceStrong,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _LocaleButton(
//             label: context.tr(AppTextKey.langFr),
//             active: context.appLocale == AppLocale.fr,
//             onPressed: () => context.setAppLocale(AppLocale.fr),
//           ),
//           _LocaleButton(
//             label: context.tr(AppTextKey.langAr),
//             active: context.appLocale == AppLocale.ar,
//             onPressed: () => context.setAppLocale(AppLocale.ar),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LocaleButton extends StatelessWidget {
//   const _LocaleButton({
//     required this.label,
//     required this.active,
//     required this.onPressed,
//   });

//   final String label;
//   final bool active;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(999),
//       onTap: onPressed,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 140),
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.md,
//           vertical: AppSpacing.sm,
//         ),
//         decoration: BoxDecoration(
//           color: active ? AppColors.primary : Colors.transparent,
//           borderRadius: BorderRadius.circular(999),
//         ),
//         child: Text(
//           label,
//           style: Theme.of(context).textTheme.labelSmall?.copyWith(
//             color: active ? AppColors.glassSurfaceStrong : AppColors.mutedInk,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CompactContent extends StatelessWidget {
//   const _CompactContent();

//   @override
//   Widget build(BuildContext context) {
//     return const Column(
//       children: [
//         _TrustHeroCard(),
//         SizedBox(height: AppSpacing.xl),
//         _VerificationPanel(),
//       ],
//     );
//   }
// }

// class _TrustHeroCard extends StatelessWidget {
//   const _TrustHeroCard();

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         color: AppColors.primary.withValues(alpha: 0.06),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(AppSpacing.xxl),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             StatusBadge(
//               label: context.tr(AppTextKey.trusted),
//               tone: BadgeTone.normal,
//               icon: Icons.verified_user_rounded,
//             ),
//             const SizedBox(height: AppSpacing.xxl),
//             Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                 color: AppColors.primary,
//                 borderRadius: BorderRadius.circular(22),
//               ),
//               child: const Icon(
//                 Icons.devices_rounded,
//                 color: AppColors.glassSurfaceStrong,
//                 size: 30,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//             Text(
//               context.tr(AppTextKey.deviceHeadline),
//               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                 color: AppColors.ink,
//                 fontWeight: FontWeight.w900,
//                 letterSpacing: -0.7,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.sm),
//             Text(
//               context.tr(AppTextKey.deviceSubhead),
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: AppColors.mutedInk,
//                 height: 1.55,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.xxl),
//             _PolicyNote(
//               title: context.tr(AppTextKey.deviceTrustVerifiedTitle),
//               message: context.tr(AppTextKey.deviceTrustVerifiedMessage),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//             _AssuranceRow(
//               icon: Icons.account_circle_outlined,
//               label: context.tr(AppTextKey.deviceAssuranceMfa),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             _AssuranceRow(
//               icon: Icons.lock_outline,
//               label: context.tr(AppTextKey.deviceAssuranceEncrypted),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             _AssuranceRow(
//               icon: Icons.admin_panel_settings_outlined,
//               label: context.tr(AppTextKey.deviceAssuranceAdmin),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PolicyNote extends StatelessWidget {
//   const _PolicyNote({required this.title, required this.message});

//   final String title;
//   final String message;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.glassSurfaceStrong.withValues(alpha: 0.86),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(
//             Icons.shield_outlined,
//             color: AppColors.primaryDark,
//             size: 20,
//           ),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: Theme.of(
//                     context,
//                   ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
//                 ),
//                 const SizedBox(height: AppSpacing.xs),
//                 Text(
//                   message,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.mutedInk,
//                     height: 1.45,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AssuranceRow extends StatelessWidget {
//   const _AssuranceRow({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 17, color: AppColors.primaryDark),
//         const SizedBox(width: AppSpacing.md),
//         Expanded(
//           child: Text(
//             label,
//             style: Theme.of(
//               context,
//             ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _VerificationPanel extends StatelessWidget {
//   const _VerificationPanel();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: const [
//         _DeviceIdentityCard(),
//         SizedBox(height: AppSpacing.lg),
//         _AccessFlowCard(),
//         SizedBox(height: AppSpacing.lg),
//         _AuditLogCard(),
//       ],
//     );
//   }
// }

// class _DeviceIdentityCard extends StatelessWidget {
//   const _DeviceIdentityCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.deviceIdentityTitle),
//       subtitle: context.tr(AppTextKey.deviceIdentitySubtitle),
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.trusted),
//         tone: BadgeTone.normal,
//       ),
//       padding: EdgeInsets.zero,
//       child: Column(
//         children: [
//           for (var i = 0; i < _DeviceTrustModel.facts.length; i++) ...[
//             _DeviceFactRow(fact: _DeviceTrustModel.facts[i]),
//             if (i < _DeviceTrustModel.facts.length - 1)
//               const Divider(
//                 height: 1,
//                 thickness: 0.5,
//                 color: AppColors.borderFaint,
//               ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _DeviceFactRow extends StatelessWidget {
//   const _DeviceFactRow({required this.fact});

//   final _DeviceFact fact;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.lg,
//         vertical: AppSpacing.md,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withValues(alpha: 0.07),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(fact.icon, size: 17, color: AppColors.primaryDark),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           SizedBox(
//             width: 132,
//             child: Text(
//               context.tr(fact.labelKey),
//               style: Theme.of(
//                 context,
//               ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               context.tr(fact.valueKey),
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AccessFlowCard extends StatelessWidget {
//   const _AccessFlowCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.accessGate),
//       subtitle: context.tr(AppTextKey.deviceSecurityPosture),
//       child: const Column(
//         children: [
//           _FlowStepRow(
//             labelKey: AppTextKey.accessGateLogin,
//             step: _FlowStep.done,
//           ),
//           _FlowConnector(),
//           _FlowStepRow(
//             labelKey: AppTextKey.accessGateDevice,
//             step: _FlowStep.active,
//           ),
//           _FlowConnector(),
//           _FlowStepRow(
//             labelKey: AppTextKey.accessGateDashboard,
//             step: _FlowStep.locked,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _FlowStepRow extends StatelessWidget {
//   const _FlowStepRow({required this.labelKey, required this.step});

//   final AppTextKey labelKey;
//   final _FlowStep step;

//   @override
//   Widget build(BuildContext context) {
//     final (color, icon) = switch (step) {
//       _FlowStep.done => (AppColors.normal, Icons.check_circle_rounded),
//       _FlowStep.active => (
//         AppColors.warning,
//         Icons.radio_button_checked_rounded,
//       ),
//       _FlowStep.locked => (
//         AppColors.mutedInk.withValues(alpha: 0.34),
//         Icons.lock_outline,
//       ),
//     };

//     return Row(
//       children: [
//         Icon(icon, size: 19, color: color),
//         const SizedBox(width: AppSpacing.md),
//         Expanded(
//           child: Text(
//             context.tr(labelKey),
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               color: step == _FlowStep.locked
//                   ? AppColors.mutedInk.withValues(alpha: 0.50)
//                   : AppColors.ink,
//               fontWeight: step == _FlowStep.active
//                   ? FontWeight.w800
//                   : FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _FlowConnector extends StatelessWidget {
//   const _FlowConnector();

//   @override
//   Widget build(BuildContext context) {
//     return const Padding(
//       padding: EdgeInsetsDirectional.only(start: AppSpacing.md + 8),
//       child: SizedBox(
//         height: 18,
//         child: VerticalDivider(
//           color: AppColors.borderFaint,
//           width: 1,
//           thickness: 1,
//         ),
//       ),
//     );
//   }
// }

// class _AuditLogCard extends StatelessWidget {
//   const _AuditLogCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.deviceAuditTrail),
//       subtitle: context.tr(AppTextKey.deviceSessionPolicy),
//       trailing: const Icon(
//         Icons.history_rounded,
//         size: 18,
//         color: AppColors.primaryDark,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _PolicyNote(
//             title: context.tr(AppTextKey.deviceSessionPolicy),
//             message: context.tr(AppTextKey.deviceSessionPolicyBody),
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           for (final entry in _DeviceTrustModel.auditLog)
//             _AuditEntryWidget(entry: entry),
//         ],
//       ),
//     );
//   }
// }

// class _AuditEntryWidget extends StatelessWidget {
//   const _AuditEntryWidget({required this.entry});

//   final _AuditEntry entry;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.warning.withValues(alpha: 0.05),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(
//                 Icons.verified_outlined,
//                 size: 15,
//                 color: AppColors.warning,
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: Text(
//                   context.tr(entry.dateKey),
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.warning,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ),
//               Text(
//                 context.tr(entry.actorKey),
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           Text(
//             context.tr(entry.eventKey),
//             style: Theme.of(
//               context,
//             ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
//           ),
//           const SizedBox(height: AppSpacing.xs),
//           Text(
//             context.tr(entry.detailKey),
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.mutedInk,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
