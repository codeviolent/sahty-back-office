import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/clinical_alert_banner.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _LabsLayout {
  static const double overviewMinHeight = 118;
  static const double chartMinHeight = 314;
  static const double resultsMinHeight = 236;
  static const double sideCardMinHeight = 314;
  static const double markersMinHeight = 236;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

class LabsScreen extends StatelessWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClinicalAlertBanner(
          title: context.tr(AppTextKey.labsCriticalTitle),
          message: context.tr(AppTextKey.labsCriticalMessage),
          isCritical: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _LabsOverviewStrip(),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _LabTrendCard()),
            SizedBox(width: AppSpacing.lg),
            Expanded(flex: 4, child: _ComparisonCard()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _LabResultsCard()),
            SizedBox(width: AppSpacing.lg),
            Expanded(flex: 4, child: _SafetyMarkersCard()),
          ],
        ),
      ],
    );
  }
}

class _LabResult {
  const _LabResult({
    required this.testKey,
    required this.resultKey,
    required this.referenceKey,
    required this.previousKey,
    required this.riskKey,
    required this.currentValue,
    required this.previousValue,
    required this.referenceValue,
    this.critical = false,
    this.outOfRange = false,
  });

  final AppTextKey testKey;
  final AppTextKey resultKey;
  final AppTextKey referenceKey;
  final AppTextKey previousKey;
  final AppTextKey riskKey;
  final double currentValue;
  final double previousValue;
  final double referenceValue;
  final bool critical;
  final bool outOfRange;

  Color get tone {
    if (critical) return AppColors.critical;
    if (outOfRange) return AppColors.primary;
    return AppColors.mutedInk;
  }
}

class _LabsOverviewStrip extends StatelessWidget {
  const _LabsOverviewStrip();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.labsResultsTitle),
      subtitle: context.tr(AppTextKey.labsResultsSubtitle),
      minHeight: _LabsLayout.overviewMinHeight,
      child: Row(
        children: [
          for (int i = 0; i < _LabResultsCard.results.length; i++) ...[
            Expanded(child: _LabMetricTile(result: _LabResultsCard.results[i])),
            if (i < _LabResultsCard.results.length - 1)
              const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _LabMetricTile extends StatelessWidget {
  const _LabMetricTile({required this.result});

  final _LabResult result;

  @override
  Widget build(BuildContext context) {
    final tone = result.tone;
    final delta = result.currentValue - result.previousValue;
    final deltaText = delta >= 0
        ? '+${delta.toStringAsFixed(result.currentValue > 3 ? 1 : 2)}'
        : delta.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr(result.testKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.north_east_rounded, size: 13, color: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr(result.resultKey),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: result.critical ? AppColors.critical : AppColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$deltaText  ·  ${context.tr(result.riskKey)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabResultsCard extends StatelessWidget {
  const _LabResultsCard();

  static const results = [
    _LabResult(
      testKey: AppTextKey.labsTestHba1c,
      resultKey: AppTextKey.labsResultHba1c,
      referenceKey: AppTextKey.labsReferenceHba1c,
      previousKey: AppTextKey.labsPreviousHba1c,
      riskKey: AppTextKey.labsRiskCritical,
      currentValue: 11.2,
      previousValue: 9.8,
      referenceValue: 7.0,
      critical: true,
    ),
    _LabResult(
      testKey: AppTextKey.labsTestGlucose,
      resultKey: AppTextKey.labsResultGlucose,
      referenceKey: AppTextKey.labsReferenceGlucose,
      previousKey: AppTextKey.labsPreviousGlucose,
      riskKey: AppTextKey.labsRiskOutOfRange,
      currentValue: 2.18,
      previousValue: 1.74,
      referenceValue: 1.10,
      outOfRange: true,
    ),
    _LabResult(
      testKey: AppTextKey.labsTestCreatinine,
      resultKey: AppTextKey.labsResultCreatinine,
      referenceKey: AppTextKey.labsReferenceCreatinine,
      previousKey: AppTextKey.labsPreviousCreatinine,
      riskKey: AppTextKey.labsRiskStable,
      currentValue: 0.9,
      previousValue: 0.8,
      referenceValue: 1.1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.labsResultsTitle),
      subtitle: context.tr(AppTextKey.labsResultsSubtitle),
      minHeight: _LabsLayout.resultsMinHeight,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _LabHeader(),
          for (int i = 0; i < results.length; i++) ...[
            _LabRow(result: results[i]),
            if (i < results.length - 1)
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

class _LabHeader extends StatelessWidget {
  const _LabHeader();

  @override
  Widget build(BuildContext context) {
    const columns = [
      AppTextKey.labsColumnTest,
      AppTextKey.labsColumnResult,
      AppTextKey.labsColumnReference,
      AppTextKey.labsColumnPrevious,
      AppTextKey.labsColumnRisk,
    ];

    return Container(
      height: _LabsLayout.headerHeight,
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

class _LabRow extends StatelessWidget {
  const _LabRow({required this.result});

  final _LabResult result;

  @override
  Widget build(BuildContext context) {
    final textColor = result.critical ? AppColors.critical : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _LabsLayout.rowHeight,
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(result.testKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                context.tr(result.resultKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Text(context.tr(result.referenceKey))),
            Expanded(child: Text(context.tr(result.previousKey))),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(
                  label: context.tr(result.riskKey),
                  tone: result.critical
                      ? BadgeTone.critical
                      : result.outOfRange
                      ? BadgeTone.warning
                      : BadgeTone.neutral,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabTrendCard extends StatelessWidget {
  const _LabTrendCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.labsComparisonTitle),
      subtitle: context.tr(AppTextKey.labsComparisonSubtitle),
      minHeight: _LabsLayout.chartMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.labsRiskCritical),
        tone: BadgeTone.critical,
        icon: Icons.science_outlined,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final result in _LabResultsCard.results) ...[
                _TrendLegend(result: result),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 204,
            width: double.infinity,
            child: CustomPaint(
              painter: const _LabTrendPainter(results: _LabResultsCard.results),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLegend extends StatelessWidget {
  const _TrendLegend({required this.result});

  final _LabResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: result.tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: result.tone.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: result.tone,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.tr(result.testKey),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabTrendPainter extends CustomPainter {
  const _LabTrendPainter({required this.results});

  final List<_LabResult> results;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(26, 6, size.width - 42, size.height - 28);
    final gridPaint = Paint()
      ..color = AppColors.borderFaint
      ..strokeWidth = 0.7;
    final targetPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final axisTextStyle = const TextStyle(
      color: AppColors.placeholder,
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          chart.left,
          chart.top + chart.height * 0.40,
          chart.width,
          chart.height * 0.20,
        ),
        const Radius.circular(10),
      ),
      targetPaint,
    );

    for (final factor in const [0.25, 0.50, 0.75, 1.0]) {
      final y = chart.top + chart.height * factor;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final groupWidth = chart.width / results.length;
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final maxValue = result.currentValue > result.referenceValue
          ? result.currentValue
          : result.referenceValue;
      final previous = (result.previousValue / maxValue).clamp(0.0, 1.0);
      final current = (result.currentValue / maxValue).clamp(0.0, 1.0);
      final reference = (result.referenceValue / maxValue).clamp(0.0, 1.0);
      final center = chart.left + groupWidth * i + groupWidth / 2;
      final barWidth = (groupWidth * 0.16).clamp(9.0, 16.0);
      final previousRect = Rect.fromLTWH(
        center - barWidth - 3,
        chart.bottom - chart.height * previous,
        barWidth,
        chart.height * previous,
      );
      final currentRect = Rect.fromLTWH(
        center + 3,
        chart.bottom - chart.height * current,
        barWidth,
        chart.height * current,
      );
      final previousPaint = Paint()
        ..color = result.tone.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      final currentPaint = Paint()
        ..color = result.tone.withValues(alpha: result.critical ? 0.92 : 0.72)
        ..style = PaintingStyle.fill;
      final referencePaint = Paint()
        ..color = AppColors.ink.withValues(alpha: 0.28)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;

      canvas.drawRRect(
        RRect.fromRectAndRadius(previousRect, const Radius.circular(999)),
        previousPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(currentRect, const Radius.circular(999)),
        currentPaint,
      );

      final referenceY = chart.bottom - chart.height * reference;
      canvas.drawLine(
        Offset(center - groupWidth * 0.24, referenceY),
        Offset(center + groupWidth * 0.24, referenceY),
        referencePaint,
      );

      final label = TextPainter(
        text: TextSpan(text: '${i + 1}', style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(center - label.width / 2, chart.bottom + AppSpacing.xs),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LabTrendPainter oldDelegate) {
    return oldDelegate.results != results;
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.labsComparisonTitle),
      subtitle: context.tr(AppTextKey.labsComparisonSubtitle),
      minHeight: _LabsLayout.sideCardMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.labsColumnRisk),
        tone: BadgeTone.neutral,
      ),
      child: Column(
        children: const [
          _ComparisonProgressRow(
            textKey: AppTextKey.labsComparisonHba1c,
            resultIndex: 0,
            factor: 0.96,
          ),
          SizedBox(height: AppSpacing.lg),
          _ComparisonProgressRow(
            textKey: AppTextKey.labsComparisonGlucose,
            resultIndex: 1,
            factor: 0.78,
          ),
          SizedBox(height: AppSpacing.lg),
          _ComparisonProgressRow(
            textKey: AppTextKey.labsComparisonCreatinine,
            resultIndex: 2,
            factor: 0.42,
          ),
        ],
      ),
    );
  }
}

class _ComparisonProgressRow extends StatelessWidget {
  const _ComparisonProgressRow({
    required this.textKey,
    required this.resultIndex,
    required this.factor,
  });

  final AppTextKey textKey;
  final int resultIndex;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final result = _LabResultsCard.results[resultIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: result.tone.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: result.tone.withValues(alpha: 0.14)),
              ),
              child: Icon(
                result.critical
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded,
                color: result.tone,
                size: 15,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.tr(textKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 7,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.borderFaint.withValues(alpha: 0.72),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: factor,
                  child: ColoredBox(
                    color: result.tone.withValues(
                      alpha: result.critical ? 0.86 : 0.58,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SafetyMarkersCard extends StatelessWidget {
  const _SafetyMarkersCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.labsMarkersTitle),
      subtitle: context.tr(AppTextKey.labsMarkersSubtitle),
      minHeight: _LabsLayout.markersMinHeight,
      child: const Column(
        children: [
          _InfoTile(
            icon: Icons.priority_high_rounded,
            textKey: AppTextKey.labsMarkerCriticalReadable,
            critical: true,
          ),
          SizedBox(height: AppSpacing.md),
          _InfoTile(
            icon: Icons.rule_rounded,
            textKey: AppTextKey.labsMarkerReferenceVisible,
          ),
          SizedBox(height: AppSpacing.md),
          _InfoTile(
            icon: Icons.compare_arrows_rounded,
            textKey: AppTextKey.labsMarkerComparisonVisible,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.textKey,
    this.critical = false,
  });

  final IconData icon;
  final AppTextKey textKey;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? AppColors.critical : AppColors.mutedInk;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: critical ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(context.tr(textKey))),
        ],
      ),
    );
  }
}
