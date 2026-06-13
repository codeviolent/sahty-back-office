import 'dart:math' as math;
import 'package:flutter/material.dart';
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

abstract final class _Layout {
  static const double summaryMinH = 118;
  static const double chartMinH = 302;
  static const double gaugeMinH = 302;
  static const double readingsMinH = 228;
  static const double tileMinH = 86;
  static const double policyMinH = 178;
}

// ── Seuils critiques par type de constante ─────────────────────────
bool _isCritical(VitalItem v) => switch (v.vitalType) {
  'blood_pressure' => v.value > 140 || v.value < 90,
  'blood_sugar' => v.value > 2.0 || v.value < 0.7,
  'oxygen_saturation' => v.value < 95,
  'heart_rate' => v.value > 100 || v.value < 50,
  'temperature' => v.value > 38.0 || v.value < 36.0,
  _ => false,
};

IconData _iconForType(String t) => switch (t) {
  'weight' => Icons.monitor_weight_outlined,
  'heart_rate' => Icons.favorite_border_rounded,
  'blood_pressure' => Icons.bloodtype_outlined,
  'temperature' => Icons.thermostat_outlined,
  'oxygen_saturation' => Icons.air_rounded,
  'blood_sugar' => Icons.water_drop_outlined,
  _ => Icons.monitor_heart_outlined,
};

// ══════════════════════════════════════════════════════════════════
class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      ClinicalSessionGate(builder: (s) => _VitalsBlocView(session: s));
}

class _VitalsBlocView extends StatelessWidget {
  final PatientSession session;
  const _VitalsBlocView({required this.session});

  @override
  Widget build(BuildContext context) {
    return SectionDispatcher(
      section: DossierSection.vitals,
      builder: (ctx, state, session) {
        final raw = getSectionData(state, DossierSection.vitals) ?? [];
        // latest par type (API retourne DESC → premier = plus récent)
        final List<VitalItem> items;
        if (raw.isNotEmpty) {
          items = raw
              .map((e) => VitalItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          // Les latestVitals sont déjà des VitalItem parsés
          final overview = getOverviewData(state);
          items = overview?.latestVitals ?? [];
        }
        final latestByType = <String, VitalItem>{};
        final historyByType = <String, List<VitalItem>>{};
        for (final v in items) {
          historyByType.putIfAbsent(v.vitalType, () => []).add(v);
          latestByType.putIfAbsent(v.vitalType, () => v);
        }

        if (latestByType.isEmpty) {
          return const SectionEmpty(label: 'constante vitale');
        }

        final latestList = latestByType.values.toList();
        final criticals = latestList.where(_isCritical).toList();

        return _VitalsContent(
          session: session,
          latestList: latestList,
          historyByType: historyByType,
          criticals: criticals,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
class _VitalsContent extends StatelessWidget {
  final PatientSession session;
  final List<VitalItem> latestList;
  final Map<String, List<VitalItem>> historyByType;
  final List<VitalItem> criticals;

  const _VitalsContent({
    required this.session,
    required this.latestList,
    required this.historyByType,
    required this.criticals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Alerte critiques ─────────────────────────────────────
        if (criticals.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.critical.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.critical.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.critical,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Constantes critiques : '
                    '${criticals.map((v) => v.typeLabel).join(", ")}',
                    style: const TextStyle(
                      color: AppColors.critical,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Résumé tuiles ─────────────────────────────────────────
        SectionCard(
          title: context.tr(AppTextKey.vitalsSummaryTitle),
          subtitle: context.tr(AppTextKey.vitalsSummarySubtitle),
          minHeight: _Layout.summaryMinH,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: latestList
                  .map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: _VitalTile(vital: v, critical: _isCritical(v)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Graphique ────────────────────────────────────────────
            Expanded(
              flex: 8,
              child: SectionCard(
                title: context.tr(AppTextKey.vitalsChartTitle),
                subtitle: context.tr(AppTextKey.vitalsChartSubtitle),
                minHeight: _Layout.chartMinH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Légendes
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: latestList.take(3).map((v) {
                        final crit = _isCritical(v);
                        final color = crit
                            ? AppColors.critical
                            : AppColors.primary;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: crit ? 0.08 : 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: color.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                v.typeLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${v.value} ${v.unit}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Graphique barres par historique
                    SizedBox(
                      height: 214,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _VitalsBarPainter(
                          vitals: latestList.take(3).toList(),
                          history: historyByType,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // ── Jauge critique ────────────────────────────────────────
            Expanded(
              flex: 3,
              child: SectionCard(
                title: context.tr(AppTextKey.vitalsClinicalBadge),
                subtitle: context.tr(AppTextKey.vitalsCriticalBannerTitle),
                minHeight: _Layout.gaugeMinH,
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        painter: _GaugePainter(
                          criticalCount: criticals.length,
                          total: latestList.length,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${criticals.length}/${latestList.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              Text(
                                context.tr(AppTextKey.vitalsCriticalState),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.mutedInk,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: AppSpacing.lg, thickness: 0.5),
                    _GaugeLegend(
                      color: AppColors.critical,
                      label: context.tr(AppTextKey.vitalsCriticalState),
                      value: criticals.length.toString(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GaugeLegend(
                      color: AppColors.primary,
                      label: context.tr(AppTextKey.vitalsNormalState),
                      value: (latestList.length - criticals.length).toString(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Lectures ────────────────────────────────────────────
            Expanded(
              flex: 7,
              child: SectionCard(
                title: context.tr(AppTextKey.vitalsSummaryTitle),
                subtitle: context.tr(AppTextKey.vitalsSummarySubtitle),
                minHeight: _Layout.readingsMinH,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0; i < latestList.length; i++) ...[
                      _ReadingRow(vital: latestList[i]),
                      if (i < latestList.length - 1)
                        const Divider(height: 1, thickness: 0.5),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // ── Politique ────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: SectionCard(
                title: context.tr(AppTextKey.vitalsPolicyTitle),
                minHeight: _Layout.policyMinH,
                trailing: StatusBadge(
                  label: context.tr(AppTextKey.vitalsClinicalBadge),
                  tone: BadgeTone.primary,
                  icon: Icons.verified_user_outlined,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(AppTextKey.vitalsPolicyBody),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PolicySignal(
                      icon: Icons.priority_high_rounded,
                      title: context.tr(AppTextKey.vitalsEscalationTitle),
                      body: context.tr(AppTextKey.vitalsEscalationBody),
                      tone: AppColors.critical,
                    ),
                    const Divider(height: AppSpacing.md, thickness: 0.5),
                    _PolicySignal(
                      icon: Icons.timeline_rounded,
                      title: context.tr(AppTextKey.vitalsReadingTitle),
                      body: context.tr(AppTextKey.vitalsReadingBody),
                      tone: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── VitalTile ──────────────────────────────────────────────────────
class _VitalTile extends StatelessWidget {
  final VitalItem vital;
  final bool critical;
  const _VitalTile({required this.vital, required this.critical});

  @override
  Widget build(BuildContext context) {
    final tone = critical ? AppColors.critical : AppColors.primary;
    final badgeTone = critical ? BadgeTone.critical : BadgeTone.neutral;

    return Container(
      width: 150,
      constraints: const BoxConstraints(minHeight: _Layout.tileMinH),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: critical
              ? AppColors.critical.withValues(alpha: 0.18)
              : AppColors.borderFaint,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: critical ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: tone.withValues(alpha: 0.14)),
                ),
                child: Icon(
                  _iconForType(vital.vitalType),
                  color: tone,
                  size: 14,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: critical ? 'Critique' : 'Normal',
                tone: badgeTone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            vital.typeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${vital.value} ${vital.unit}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: critical ? AppColors.critical : AppColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Barre de plage
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: critical ? 0.85 : 0.45,
              backgroundColor: AppColors.borderFaint,
              color: tone.withValues(alpha: critical ? 0.7 : 0.4),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Graphique barres historique ────────────────────────────────────
class _VitalsBarPainter extends CustomPainter {
  final List<VitalItem> vitals;
  final Map<String, List<VitalItem>> history;
  const _VitalsBarPainter({required this.vitals, required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.borderFaint
      ..strokeWidth = 0.7;
    final bandPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.38, size.width, size.height * 0.22),
        const Radius.circular(8),
      ),
      bandPaint,
    );

    for (final y in [0.25, 0.50, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        gridPaint,
      );
    }

    if (vitals.isEmpty) return;
    final groupW = size.width / vitals.length;

    for (int i = 0; i < vitals.length; i++) {
      final v = vitals[i];
      final crit = _isCritical(v);
      final color = crit ? AppColors.critical : AppColors.primary;
      final history = this.history[v.vitalType] ?? [];
      final maxVal = history.map((x) => x.value).fold(v.value, math.max);
      if (maxVal == 0) continue;

      double normalize(double val) => (val / maxVal).clamp(0.1, 1.0);
      final center = groupW * i + groupW / 2;
      final barW = (groupW * 0.3).clamp(8.0, 22.0);

      // Barres historique (en fond)
      for (int j = math.min(history.length - 1, 4); j >= 1; j--) {
        final hv = history[j];
        final hFact = normalize(hv.value);
        final hH = size.height * hFact;
        final xOff = (j - history.length / 2.0) * barW * 0.3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              center + xOff - barW * 0.2,
              size.height - hH,
              barW * 0.4,
              hH,
            ),
            const Radius.circular(999),
          ),
          Paint()
            ..color = color.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill,
        );
      }

      // Barre principale (valeur la plus récente)
      final fact = normalize(v.value);
      final h = size.height * fact;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(center - barW / 2, size.height - h, barW, h),
          const Radius.circular(999),
        ),
        Paint()
          ..color = color.withValues(alpha: crit ? 0.85 : 0.65)
          ..style = PaintingStyle.fill,
      );

      // Valeur texte
      final tp = TextPainter(
        text: TextSpan(
          text: '${v.value}',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center - tp.width / 2, size.height - h - 14));
    }
  }

  @override
  bool shouldRepaint(_VitalsBarPainter o) => o.vitals != vitals;
}

// ── Jauge ──────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final int criticalCount, total;
  const _GaugePainter({required this.criticalCount, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final sw = radius * 0.16;
    const start = -math.pi * 0.72;
    const sweep = math.pi * 1.44;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );

    final cSweep = total == 0 ? 0.0 : sweep * (criticalCount / total);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      cSweep,
      false,
      Paint()
        ..color = AppColors.critical
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter o) =>
      o.criticalCount != criticalCount || o.total != total;
}

class _GaugeLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _GaugeLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ── Lecture individuelle ───────────────────────────────────────────
class _ReadingRow extends StatelessWidget {
  final VitalItem vital;
  const _ReadingRow({required this.vital});

  @override
  Widget build(BuildContext context) {
    final crit = _isCritical(vital);
    final tone = crit ? AppColors.critical : AppColors.primary;
    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Icon(_iconForType(vital.vitalType), color: tone, size: 15),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                vital.typeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${vital.value} ${vital.unit}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: crit ? AppColors.critical : AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: crit ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                crit ? 'Critique' : 'Normal',
                style: TextStyle(
                  color: tone,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PolicySignal ───────────────────────────────────────────────────
class _PolicySignal extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color tone;
  const _PolicySignal({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: tone.withValues(alpha: 0.66), width: 2.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
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

// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:sahty_back_office/core/widgets/clinical_session_gate.dart';
// import 'package:sahty_back_office/features/medical_record/data/models/dossier_models.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/clinical_alert_banner.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';

// abstract final class _VitalsLayout {
//   static const double summaryMinHeight = 118;
//   static const double chartMinHeight = 302;
//   static const double gaugeMinHeight = 302;
//   static const double readingsMinHeight = 228;
//   static const double tileMinHeight = 86;
//   static const double policyMinHeight = 178;
// }

// class VitalsScreen extends StatelessWidget {
//   const VitalsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ClinicalSessionGate(
//       builder: (session) => _VitalsContent(session: session),
//     );
//   }
// }

// class _VitalsContent extends StatelessWidget {
//   final PatientSession session;
//   const _VitalsContent({required this.session});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ClinicalAlertBanner(
//           title: context.tr(AppTextKey.vitalsCriticalBannerTitle),
//           message: context.tr(AppTextKey.vitalsCriticalBannerMessage),
//           isCritical: true,
//         ),
//         const SizedBox(height: AppSpacing.lg),
//         const _VitalsSummaryCard(),
//         const SizedBox(height: AppSpacing.lg),
//         const Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(flex: 8, child: _VitalsChartCard()),
//             SizedBox(width: AppSpacing.lg),
//             Expanded(flex: 3, child: _VitalsGaugeCard()),
//           ],
//         ),
//         const SizedBox(height: AppSpacing.lg),
//         const Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(flex: 7, child: _VitalsReadingsCard()),
//             SizedBox(width: AppSpacing.lg),
//             Expanded(flex: 4, child: _VitalsPolicyCard()),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _VitalItem {
//   const _VitalItem({
//     required this.titleKey,
//     required this.valueKey,
//     required this.icon,
//     required this.delta,
//     required this.direction,
//     required this.tone,
//     this.critical = false,
//   });

//   final AppTextKey titleKey;
//   final AppTextKey valueKey;
//   final IconData icon;
//   final String delta;
//   final String direction;
//   final Color tone;
//   final bool critical;
// }

// class _TrendItem {
//   const _TrendItem({
//     required this.labelKey,
//     required this.current,
//     required this.delta,
//     required this.values,
//     required this.tone,
//     this.critical = false,
//   });

//   final AppTextKey labelKey;
//   final String current;
//   final String delta;
//   final List<double> values;
//   final Color tone;
//   final bool critical;
// }

// class _VitalsSummaryCard extends StatelessWidget {
//   const _VitalsSummaryCard();

//   static const items = [
//     _VitalItem(
//       titleKey: AppTextKey.vitalsWeightTitle,
//       valueKey: AppTextKey.vitalsWeightValue,
//       icon: Icons.monitor_weight_outlined,
//       delta: '+1.8 kg',
//       direction: '30j',
//       tone: AppColors.primary,
//     ),
//     _VitalItem(
//       titleKey: AppTextKey.vitalsBloodPressureTitle,
//       valueKey: AppTextKey.vitalsBloodPressureValue,
//       icon: Icons.bloodtype_outlined,
//       delta: '+12%',
//       direction: '7j',
//       tone: AppColors.critical,
//       critical: true,
//     ),
//     _VitalItem(
//       titleKey: AppTextKey.vitalsGlucoseTitle,
//       valueKey: AppTextKey.vitalsGlucoseValue,
//       icon: Icons.water_drop_outlined,
//       delta: '+0.42',
//       direction: '24h',
//       tone: AppColors.critical,
//       critical: true,
//     ),
//     _VitalItem(
//       titleKey: AppTextKey.vitalsTemperatureTitle,
//       valueKey: AppTextKey.vitalsTemperatureValue,
//       icon: Icons.thermostat_outlined,
//       delta: '+0.2',
//       direction: '24h',
//       tone: AppColors.primary,
//     ),
//     _VitalItem(
//       titleKey: AppTextKey.vitalsPulseTitle,
//       valueKey: AppTextKey.vitalsPulseValue,
//       icon: Icons.favorite_border_rounded,
//       delta: '+6 bpm',
//       direction: '7j',
//       tone: AppColors.primary,
//     ),
//     _VitalItem(
//       titleKey: AppTextKey.vitalsOxygenTitle,
//       valueKey: AppTextKey.vitalsOxygenValue,
//       icon: Icons.air_rounded,
//       delta: '-1%',
//       direction: '7j',
//       tone: AppColors.primary,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.vitalsSummaryTitle),
//       subtitle: context.tr(AppTextKey.vitalsSummarySubtitle),
//       minHeight: _VitalsLayout.summaryMinHeight,
//       child: Row(
//         children: [
//           for (int i = 0; i < _featuredItems.length; i++) ...[
//             Expanded(child: _VitalTile(item: _featuredItems[i])),
//             if (i < _featuredItems.length - 1)
//               const SizedBox(width: AppSpacing.md),
//           ],
//         ],
//       ),
//     );
//   }

//   static final _featuredItems = [items[0], items[2], items[1], items[5]];
// }

// class _VitalTile extends StatelessWidget {
//   const _VitalTile({required this.item});

//   final _VitalItem item;

//   @override
//   Widget build(BuildContext context) {
//     final tone = item.tone;
//     final badgeTone = item.critical ? BadgeTone.critical : BadgeTone.neutral;

//     return Container(
//       constraints: const BoxConstraints(minHeight: _VitalsLayout.tileMinHeight),
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.canvas.withValues(alpha: 0.42),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(
//           color: item.critical
//               ? AppColors.critical.withValues(alpha: 0.18)
//               : AppColors.borderFaint,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 26,
//                 height: 26,
//                 decoration: BoxDecoration(
//                   color: tone.withValues(alpha: item.critical ? 0.10 : 0.07),
//                   borderRadius: BorderRadius.circular(9),
//                   border: Border.all(color: tone.withValues(alpha: 0.14)),
//                 ),
//                 child: Icon(item.icon, color: tone, size: 14),
//               ),
//               const Spacer(),
//               StatusBadge(
//                 label: context.tr(
//                   item.critical
//                       ? AppTextKey.vitalsCriticalState
//                       : AppTextKey.vitalsNormalState,
//                 ),
//                 tone: badgeTone,
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Text(
//             context.tr(item.titleKey),
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.mutedInk,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: AppSpacing.xs),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Expanded(
//                 child: Text(
//                   context.tr(item.valueKey),
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     color: item.critical ? AppColors.critical : AppColors.ink,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: -0.25,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.xs),
//               _DeltaPill(
//                 label: item.delta,
//                 caption: item.direction,
//                 tone: tone,
//                 critical: item.critical,
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           _VitalRangeTrack(tone: tone, critical: item.critical),
//         ],
//       ),
//     );
//   }
// }

// class _VitalRangeTrack extends StatelessWidget {
//   const _VitalRangeTrack({required this.tone, required this.critical});

//   final Color tone;
//   final bool critical;

//   @override
//   Widget build(BuildContext context) {
//     final markerAlignment = critical ? 0.78 : 0.44;
//     return SizedBox(
//       height: 10,
//       child: Stack(
//         alignment: Alignment.centerLeft,
//         children: [
//           Container(
//             height: 3,
//             decoration: BoxDecoration(
//               color: AppColors.borderFaint,
//               borderRadius: BorderRadius.circular(999),
//             ),
//           ),
//           FractionallySizedBox(
//             widthFactor: critical ? 0.78 : 0.52,
//             child: Container(
//               height: 3,
//               decoration: BoxDecoration(
//                 color: tone.withValues(alpha: critical ? 0.34 : 0.24),
//                 borderRadius: BorderRadius.circular(999),
//               ),
//             ),
//           ),
//           Align(
//             alignment: AlignmentDirectional(markerAlignment * 2 - 1, 0),
//             child: Container(
//               width: 7,
//               height: 7,
//               decoration: BoxDecoration(
//                 color: tone,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: AppColors.surface, width: 1.2),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DeltaPill extends StatelessWidget {
//   const _DeltaPill({
//     required this.label,
//     required this.caption,
//     required this.tone,
//     required this.critical,
//   });

//   final String label;
//   final String caption;
//   final Color tone;
//   final bool critical;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.sm,
//         vertical: AppSpacing.xs,
//       ),
//       decoration: BoxDecoration(
//         color: tone.withValues(alpha: critical ? 0.12 : 0.08),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: tone.withValues(alpha: 0.18), width: 0.7),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             critical ? Icons.trending_up_rounded : Icons.show_chart_rounded,
//             color: tone,
//             size: 13,
//           ),
//           const SizedBox(width: 3),
//           Text(
//             label,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: tone,
//               fontWeight: FontWeight.w800,
//               height: 1,
//             ),
//           ),
//           const SizedBox(width: 3),
//           Text(
//             caption,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.placeholder,
//               fontWeight: FontWeight.w700,
//               height: 1,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _VitalsChartCard extends StatelessWidget {
//   const _VitalsChartCard();

//   static const _trends = [
//     _TrendItem(
//       labelKey: AppTextKey.vitalsChartGlucoseTrend,
//       current: '2.18 g/L',
//       delta: '+24%',
//       values: [
//         0.20,
//         0.27,
//         0.31,
//         0.38,
//         0.43,
//         0.49,
//         0.56,
//         0.62,
//         0.69,
//         0.74,
//         0.82,
//         0.88,
//       ],
//       tone: AppColors.critical,
//       critical: true,
//     ),
//     _TrendItem(
//       labelKey: AppTextKey.vitalsChartPressureTrend,
//       current: '150/95',
//       delta: '+12%',
//       values: [
//         0.32,
//         0.35,
//         0.40,
//         0.45,
//         0.48,
//         0.52,
//         0.57,
//         0.61,
//         0.64,
//         0.68,
//         0.73,
//         0.78,
//       ],
//       tone: AppColors.critical,
//       critical: true,
//     ),
//     _TrendItem(
//       labelKey: AppTextKey.vitalsChartOxygenTrend,
//       current: '97%',
//       delta: '-1%',
//       values: [
//         0.72,
//         0.73,
//         0.72,
//         0.74,
//         0.73,
//         0.72,
//         0.74,
//         0.73,
//         0.75,
//         0.74,
//         0.73,
//         0.73,
//       ],
//       tone: AppColors.primary,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.vitalsChartTitle),
//       subtitle: context.tr(AppTextKey.vitalsChartSubtitle),
//       minHeight: _VitalsLayout.chartMinHeight,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               for (int i = 0; i < _trends.length; i++) ...[
//                 _TrendSummaryPill(item: _trends[i]),
//                 if (i < _trends.length - 1)
//                   const SizedBox(width: AppSpacing.sm),
//               ],
//             ],
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           _VitalsFlowChart(trends: _trends),
//         ],
//       ),
//     );
//   }
// }

// class _TrendSummaryPill extends StatelessWidget {
//   const _TrendSummaryPill({required this.item});

//   final _TrendItem item;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.md,
//         vertical: AppSpacing.sm,
//       ),
//       decoration: BoxDecoration(
//         color: item.tone.withValues(alpha: item.critical ? 0.08 : 0.06),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: item.tone.withValues(alpha: 0.14)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 7,
//             height: 7,
//             decoration: BoxDecoration(color: item.tone, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Text(
//             context.tr(item.labelKey),
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(width: AppSpacing.xs),
//           Text(
//             item.current,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: item.tone,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _VitalsFlowChart extends StatelessWidget {
//   const _VitalsFlowChart({required this.trends});

//   final List<_TrendItem> trends;

//   @override
//   Widget build(BuildContext context) {
//     final maxPoints = trends
//         .map((trend) => trend.values.length)
//         .fold<int>(0, (max, length) => math.max(max, length));
//     if (maxPoints == 0) return const SizedBox.shrink();

//     return SizedBox(
//       height: 214,
//       width: double.infinity,
//       child: Column(
//         children: [
//           Expanded(
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: CustomPaint(
//                     painter: const _VitalsChartBackdropPainter(),
//                   ),
//                 ),
//                 Positioned.fill(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         for (
//                           var pointIndex = 0;
//                           pointIndex < maxPoints;
//                           pointIndex++
//                         )
//                           Expanded(
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 2.5,
//                               ),
//                               child: _VitalsTrendGroup(
//                                 trends: trends,
//                                 pointIndex: pointIndex,
//                                 isLatest: pointIndex == maxPoints - 1,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: AppSpacing.xs),
//           SizedBox(
//             height: 14,
//             child: Row(
//               children: [
//                 for (var i = 0; i < maxPoints; i++)
//                   Expanded(
//                     child: Text(
//                       i.isEven ? '${i + 1}' : '',
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: AppColors.placeholder,
//                         fontSize: 9,
//                         fontWeight: FontWeight.w700,
//                         height: 1,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _VitalsTrendGroup extends StatelessWidget {
//   const _VitalsTrendGroup({
//     required this.trends,
//     required this.pointIndex,
//     required this.isLatest,
//   });

//   final List<_TrendItem> trends;
//   final int pointIndex;
//   final bool isLatest;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.borderFaint.withValues(alpha: 0.44),
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 2.5),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             for (final trend in trends)
//               Expanded(
//                 child: Align(
//                   alignment: Alignment.bottomCenter,
//                   child: FractionallySizedBox(
//                     heightFactor: pointIndex < trend.values.length
//                         ? trend.values[pointIndex].clamp(0.0, 1.0)
//                         : 0,
//                     widthFactor: 0.82,
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                         color: trend.tone.withValues(
//                           alpha: isLatest ? 0.95 : 0.42,
//                         ),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _VitalsChartBackdropPainter extends CustomPainter {
//   const _VitalsChartBackdropPainter();

//   @override
//   void paint(Canvas canvas, Size size) {
//     final chart = Rect.fromLTWH(0, 0, size.width, size.height);
//     final targetBand = Rect.fromLTWH(
//       chart.left,
//       chart.top + chart.height * 0.38,
//       chart.width,
//       chart.height * 0.22,
//     );
//     final bandPaint = Paint()
//       ..color = AppColors.primary.withValues(alpha: 0.055)
//       ..style = PaintingStyle.fill;
//     final gridPaint = Paint()
//       ..color = AppColors.borderFaint
//       ..strokeWidth = 0.7;
//     final targetPaint = Paint()
//       ..color = AppColors.primary.withValues(alpha: 0.42)
//       ..strokeWidth = 1.2
//       ..strokeCap = StrokeCap.round;

//     canvas.drawRRect(
//       RRect.fromRectAndRadius(targetBand, const Radius.circular(8)),
//       bandPaint,
//     );

//     for (final y in [0.25, 0.50, 0.75]) {
//       final dy = chart.top + chart.height * y;
//       canvas.drawLine(
//         Offset(chart.left, dy),
//         Offset(chart.right, dy),
//         gridPaint,
//       );
//     }

//     final targetY = chart.top + chart.height * 0.38;
//     canvas.drawLine(
//       Offset(chart.left, targetY),
//       Offset(chart.right, targetY),
//       targetPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _VitalsChartBackdropPainter oldDelegate) =>
//       false;
// }

// class _VitalsGaugeCard extends StatelessWidget {
//   const _VitalsGaugeCard();

//   @override
//   Widget build(BuildContext context) {
//     final criticalCount = _VitalsSummaryCard.items
//         .where((item) => item.critical)
//         .length;
//     final total = _VitalsSummaryCard.items.length;

//     return SectionCard(
//       title: context.tr(AppTextKey.vitalsClinicalBadge),
//       subtitle: context.tr(AppTextKey.vitalsCriticalBannerTitle),
//       minHeight: _VitalsLayout.gaugeMinHeight,
//       child: Column(
//         children: [
//           SizedBox(
//             height: 150,
//             child: CustomPaint(
//               painter: _VitalsGaugePainter(
//                 criticalCount: criticalCount,
//                 total: total,
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       '$criticalCount/$total',
//                       style: Theme.of(context).textTheme.headlineMedium
//                           ?.copyWith(
//                             color: AppColors.ink,
//                             fontWeight: FontWeight.w900,
//                           ),
//                     ),
//                     Text(
//                       context.tr(AppTextKey.vitalsCriticalState),
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: AppColors.mutedInk,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const Divider(height: AppSpacing.lg, thickness: 0.5),
//           _GaugeLegend(
//             color: AppColors.critical,
//             label: context.tr(AppTextKey.vitalsCriticalState),
//             value: criticalCount.toString(),
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           _GaugeLegend(
//             color: AppColors.primary,
//             label: context.tr(AppTextKey.vitalsNormalState),
//             value: (total - criticalCount).toString(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _VitalsGaugePainter extends CustomPainter {
//   const _VitalsGaugePainter({required this.criticalCount, required this.total});

//   final int criticalCount;
//   final int total;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = math.min(size.width, size.height) / 2 - 10;
//     final strokeWidth = radius * 0.16;
//     final basePaint = Paint()
//       ..color = AppColors.primary.withValues(alpha: 0.14)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//     final criticalPaint = Paint()
//       ..color = AppColors.critical
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//     final rect = Rect.fromCircle(center: center, radius: radius);
//     const start = -math.pi * 0.72;
//     const sweep = math.pi * 1.44;
//     canvas.drawArc(rect, start, sweep, false, basePaint);
//     final criticalSweep = total == 0 ? 0.0 : sweep * (criticalCount / total);
//     canvas.drawArc(rect, start, criticalSweep, false, criticalPaint);
//   }

//   @override
//   bool shouldRepaint(covariant _VitalsGaugePainter oldDelegate) {
//     return oldDelegate.criticalCount != criticalCount ||
//         oldDelegate.total != total;
//   }
// }

// class _GaugeLegend extends StatelessWidget {
//   const _GaugeLegend({
//     required this.color,
//     required this.label,
//     required this.value,
//   });

//   final Color color;
//   final String label;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 7,
//           height: 7,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: AppSpacing.sm),
//         Expanded(
//           child: Text(
//             label,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.mutedInk,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//             color: AppColors.ink,
//             fontWeight: FontWeight.w900,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _VitalsReadingsCard extends StatelessWidget {
//   const _VitalsReadingsCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.vitalsSummaryTitle),
//       subtitle: context.tr(AppTextKey.vitalsSummarySubtitle),
//       minHeight: _VitalsLayout.readingsMinHeight,
//       padding: EdgeInsets.zero,
//       child: Column(
//         children: [
//           for (int i = 0; i < _VitalsSummaryCard.items.length; i++) ...[
//             _VitalsReadingRow(item: _VitalsSummaryCard.items[i]),
//             if (i < _VitalsSummaryCard.items.length - 1)
//               const Divider(height: 1, thickness: 0.5),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _VitalsReadingRow extends StatelessWidget {
//   const _VitalsReadingRow({required this.item});

//   final _VitalItem item;

//   @override
//   Widget build(BuildContext context) {
//     final tone = item.critical ? AppColors.critical : AppColors.primary;
//     return SizedBox(
//       height: 42,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
//         child: Row(
//           children: [
//             Icon(item.icon, color: tone, size: 15),
//             const SizedBox(width: AppSpacing.md),
//             Expanded(
//               child: Text(
//                 context.tr(item.titleKey),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: AppColors.ink,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//             Text(
//               context.tr(item.valueKey),
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: item.critical ? AppColors.critical : AppColors.ink,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//             const SizedBox(width: AppSpacing.md),
//             _DeltaPill(
//               label: item.delta,
//               caption: item.direction,
//               tone: tone,
//               critical: item.critical,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _VitalsPolicyCard extends StatelessWidget {
//   const _VitalsPolicyCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.vitalsPolicyTitle),
//       minHeight: _VitalsLayout.policyMinHeight,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.vitalsClinicalBadge),
//         tone: BadgeTone.primary,
//         icon: Icons.verified_user_outlined,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             context.tr(AppTextKey.vitalsPolicyBody),
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.mutedInk,
//               height: 1.45,
//             ),
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           _PolicySignal(
//             icon: Icons.priority_high_rounded,
//             title: context.tr(AppTextKey.vitalsEscalationTitle),
//             body: context.tr(AppTextKey.vitalsEscalationBody),
//             tone: AppColors.critical,
//           ),
//           const Divider(height: AppSpacing.md, thickness: 0.5),
//           _PolicySignal(
//             icon: Icons.timeline_rounded,
//             title: context.tr(AppTextKey.vitalsReadingTitle),
//             body: context.tr(AppTextKey.vitalsReadingBody),
//             tone: AppColors.primary,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PolicySignal extends StatelessWidget {
//   const _PolicySignal({
//     required this.icon,
//     required this.title,
//     required this.body,
//     required this.tone,
//   });

//   final IconData icon;
//   final String title;
//   final String body;
//   final Color tone;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsetsDirectional.only(
//         start: AppSpacing.md,
//         top: AppSpacing.xs,
//         bottom: AppSpacing.xs,
//       ),
//       decoration: BoxDecoration(
//         border: BorderDirectional(
//           start: BorderSide(color: tone.withValues(alpha: 0.66), width: 2.5),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16, color: tone),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   body,
//                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                     color: AppColors.mutedInk,
//                     height: 1.35,
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
