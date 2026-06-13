// lib/features/medical_record/presentation/screens/diagnoses_screen.dart

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

abstract final class _Layout {
  static const double heroMinHeight = 438;
  static const double sidePanelMinHeight = 220;
  static const double previousMinHeight = 206;
  static const double chartHeight = 138;
  static const double tileMinH = 126;
  static const double roadmapH = 360;
}

// ══════════════════════════════════════════════════════════════════
class DiagnosesScreen extends StatelessWidget {
  const DiagnosesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      ClinicalSessionGate(builder: (s) => _DiagnosesBlocView(session: s));
}

// ══════════════════════════════════════════════════════════════════
class _DiagnosesBlocView extends StatelessWidget {
  final PatientSession session;
  const _DiagnosesBlocView({required this.session});
  static const _section = DossierSection.medicalRecords;

  @override
  Widget build(BuildContext context) {
    return SectionDispatcher(
      section: DossierSection.medicalRecords,
      builder: (ctx, state, session) {
        final raw = getSectionData(state, DossierSection.medicalRecords) ?? [];
        final all = raw
            .map((e) => MedicalRecordItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final current = all
            .where(
              (r) =>
                  r.recordType == 'diagnosis' || r.recordType == 'consultation',
            )
            .toList();
        final archived = all
            .where(
              (r) =>
                  r.recordType != 'diagnosis' && r.recordType != 'consultation',
            )
            .toList();

        return _DiagnosesContent(
          session: session,
          current: current,
          archived: archived,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
class _DiagnosesContent extends StatelessWidget {
  final PatientSession session;
  final List<MedicalRecordItem> current;
  final List<MedicalRecordItem> archived;
  const _DiagnosesContent({
    required this.session,
    required this.current,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiagnosesToolbar(currentCount: current.length),
        const SizedBox(height: AppSpacing.lg),
        _DiagnosesClinicalHeader(current: current, archived: archived),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 9, child: _CurrentDiagnosesBoard(items: current)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _DiagnosisTrendCard(
                    currentCount: current.length,
                    archivedCount: archived.length,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _DiagnosesPolicyCard(),
                ],
              ),
            ),
          ],
        ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _PreviousDiagnosesCard(items: archived),
        ],
      ],
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────
class _DiagnosesToolbar extends StatelessWidget {
  final int currentCount;
  const _DiagnosesToolbar({required this.currentCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderFaint, width: 0.7),
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          _Chip(
            icon: Icons.tune_rounded,
            label: context.tr(AppTextKey.diagnosesColumnStatus),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            icon: Icons.calendar_month_outlined,
            label: context.tr(AppTextKey.diagnosesColumnDate),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            icon: Icons.shield_outlined,
            label: context.tr(AppTextKey.diagnosesReadOnly),
          ),
          const Spacer(),
          StatusBadge(
            label: '$currentCount diagnostic(s)',
            tone: BadgeTone.neutral,
            icon: Icons.medical_information_outlined,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.mutedInk),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clinical Header ────────────────────────────────────────────────
class _DiagnosesClinicalHeader extends StatelessWidget {
  final List<MedicalRecordItem> current;
  final List<MedicalRecordItem> archived;
  const _DiagnosesClinicalHeader({
    required this.current,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderFaint, width: 0.7),
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          _Metric(
            label: context.tr(AppTextKey.diagnosesCurrentTitle),
            value: current.length.toString(),
            tone: AppColors.critical,
          ),
          const SizedBox(width: AppSpacing.xl),
          _Metric(
            label: context.tr(AppTextKey.diagnosesPreviousTitle),
            value: archived.length.toString(),
            tone: AppColors.primary,
          ),
          const Spacer(),
          for (final item in current.take(2)) ...[
            _DiagnosisTag(item: item),
            const SizedBox(width: AppSpacing.sm),
          ],
          StatusBadge(
            label: context.tr(AppTextKey.diagnosesReadOnly),
            tone: BadgeTone.neutral,
            icon: Icons.visibility_outlined,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  const _Metric({required this.label, required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisTag extends StatelessWidget {
  final MedicalRecordItem item;
  const _DiagnosisTag({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.recordType == 'diagnosis'
        ? AppColors.critical
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_information_outlined, color: color, size: 14),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              item.title.isNotEmpty ? item.title : item.recordType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Roadmap Board ──────────────────────────────────────────────────
class _CurrentDiagnosesBoard extends StatelessWidget {
  final List<MedicalRecordItem> items;
  const _CurrentDiagnosesBoard({required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.diagnosesCurrentTitle),
      subtitle: context.tr(AppTextKey.diagnosesCurrentSubtitle),
      minHeight: _Layout.heroMinHeight,
      padding: EdgeInsets.zero,
      trailing: items.isNotEmpty
          ? StatusBadge(
              label: context.tr(AppTextKey.diagnosesSeverityHigh),
              tone: BadgeTone.critical,
            )
          : null,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: SectionEmpty(label: 'diagnostic actif'),
            )
          : SizedBox(
              height: _Layout.roadmapH,
              child: _DiagnosisRoadmap(items: items.take(3).toList()),
            ),
    );
  }
}

class _DiagnosisRoadmap extends StatelessWidget {
  final List<MedicalRecordItem> items;
  const _DiagnosisRoadmap({required this.items});

  static const _pos1 = [0.50];
  static const _pos2 = [0.25, 0.75];
  static const _pos3 = [0.14, 0.50, 0.82];

  List<double> get _positions {
    if (items.length >= 3) return _pos3;
    if (items.length == 2) return _pos2;
    return _pos1;
  }

  @override
  Widget build(BuildContext context) {
    final pos = _positions;
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RoadmapPainter(nodes: pos)),
            ),
            for (int i = 0; i < items.length; i++)
              Positioned(
                left: (w * pos[i] + AppSpacing.sm).clamp(0, w - 136),
                top: 12,
                child: _DateNode(item: items[i]),
              ),
            ..._tiles(w, pos),
          ],
        );
      },
    );
  }

  List<Widget> _tiles(double w, List<double> pos) {
    if (items.length == 1) {
      return [
        Positioned(
          left: w * 0.35,
          top: 126,
          width: w * 0.30,
          child: _DiagnosisTile(item: items[0], highlighted: true),
        ),
      ];
    }
    if (items.length == 2) {
      return [
        Positioned(
          left: AppSpacing.lg,
          top: 126,
          width: w * 0.40,
          child: _DiagnosisTile(item: items[0]),
        ),
        Positioned(
          right: AppSpacing.lg,
          top: 126,
          width: w * 0.40,
          child: _DiagnosisTile(item: items[1], highlighted: true),
        ),
      ];
    }
    return [
      Positioned(
        left: AppSpacing.lg,
        top: 126,
        width: w * 0.29,
        child: _DiagnosisTile(item: items[0]),
      ),
      Positioned(
        left: w * 0.35,
        top: 176,
        width: w * 0.30,
        child: _DiagnosisTile(item: items[1]),
      ),
      Positioned(
        right: AppSpacing.lg,
        top: 126,
        width: w * 0.30,
        child: _DiagnosisTile(item: items[2], highlighted: true),
      ),
    ];
  }
}

class _DateNode extends StatelessWidget {
  final MedicalRecordItem item;
  const _DateNode({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.formattedDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            switch (item.recordType) {
              'diagnosis' => 'Diagnostic',
              'consultation' => 'Consultation',
              _ => item.recordType,
            },
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapPainter extends CustomPainter {
  final List<double> nodes;
  const _RoadmapPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    const ty = 35.0;
    final linePt = Paint()
      ..color = AppColors.borderSoft
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final connPt = Paint()
      ..color = AppColors.borderSoft
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final fillPt = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final strokePt = Paint()
      ..color = AppColors.borderSoft
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, ty), Offset(size.width, ty), linePt);
    for (int i = 0; i < nodes.length; i++) {
      final x = size.width * nodes[i];
      final bottom = (i == 1 && nodes.length == 3) ? 176.0 : 126.0;
      canvas.drawCircle(Offset(x, ty), 5, fillPt);
      canvas.drawCircle(Offset(x, ty), 5, strokePt);
      final path = Path()
        ..moveTo(x, ty + 5)
        ..cubicTo(x, ty + 42, x - 42, bottom - 30, x, bottom);
      canvas.drawPath(path, connPt);
    }
  }

  @override
  bool shouldRepaint(_RoadmapPainter o) => o.nodes != nodes;
}

class _DiagnosisTile extends StatelessWidget {
  final MedicalRecordItem item;
  final bool highlighted;
  const _DiagnosisTile({required this.item, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.critical : AppColors.primary;
    final borderColor = highlighted
        ? color.withValues(alpha: 0.24)
        : AppColors.borderFaint;

    return Container(
      constraints: const BoxConstraints(minHeight: _Layout.tileMinH),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              highlighted
                  ? Icons.bloodtype_outlined
                  : Icons.monitor_heart_outlined,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : 'Dossier médical',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: highlighted ? AppColors.critical : AppColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  label: switch (item.recordType) {
                    'diagnosis' => 'Diagnostic',
                    'consultation' => 'Consultation',
                    _ => 'Actif',
                  },
                  tone: highlighted ? BadgeTone.critical : BadgeTone.neutral,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (item.notes.isNotEmpty)
                  Text(
                    item.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MetaPill(
                      icon: Icons.event_available_outlined,
                      label: item.formattedDate,
                    ),
                    _MetaPill(
                      icon: Icons.person_outlined,
                      label: item.doctorName,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderFaint),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.mutedInk),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedInk,
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

// ── Trend Card ─────────────────────────────────────────────────────
class _DiagnosisTrendCard extends StatelessWidget {
  final int currentCount;
  final int archivedCount;
  const _DiagnosisTrendCard({
    required this.currentCount,
    required this.archivedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = currentCount + archivedCount;
    final hCurrent = total > 0 ? (currentCount / total).clamp(0.1, 0.9) : 0.1;
    final hArchived = total > 0 ? (archivedCount / total).clamp(0.1, 0.9) : 0.1;

    return SectionCard(
      title: context.tr(AppTextKey.diagnosesColumnSeverity),
      subtitle: context.tr(AppTextKey.diagnosesSubtitle),
      minHeight: _Layout.sidePanelMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.diagnosesReadOnly),
        tone: BadgeTone.neutral,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SeverityMetric(
                label: context.tr(AppTextKey.diagnosesCurrentTitle),
                value: currentCount.toString(),
                tone: AppColors.critical,
              ),
              const SizedBox(width: AppSpacing.sm),
              _SeverityMetric(
                label: context.tr(AppTextKey.diagnosesPreviousTitle),
                value: archivedCount.toString(),
                tone: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: _Layout.chartHeight,
            child: CustomPaint(
              painter: const _DiagnosisTrendPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TrendBar(
                      label: 'Archivés',
                      heightFactor: hArchived,
                      tone: AppColors.mutedInk,
                    ),
                    _TrendBar(
                      label: 'En cours',
                      heightFactor: hCurrent,
                      tone: AppColors.critical,
                      highlighted: currentCount > 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  const _SeverityMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderFaint),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: tone.withValues(
                  alpha: tone == AppColors.critical ? 0.72 : 0.42,
                ),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  final String label;
  final double heightFactor;
  final Color tone;
  final bool highlighted;
  const _TrendBar({
    required this.label,
    required this.heightFactor,
    required this.tone,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: heightFactor,
                    widthFactor: highlighted ? 0.18 : 0.14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tone.withValues(
                          alpha: highlighted ? 0.32 : 0.20,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(0, 1 - (heightFactor * 2)),
                    child: Container(
                      width: highlighted ? 6 : 5,
                      height: highlighted ? 6 : 5,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? AppColors.critical
                            : AppColors.mutedInk,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisTrendPainter extends CustomPainter {
  const _DiagnosisTrendPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.borderFaint.withValues(alpha: 0.50)
      ..strokeWidth = 0.35;
    for (final f in const [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagnosisTrendPainter _) => false;
}

// ── Previous Diagnoses ─────────────────────────────────────────────
class _PreviousDiagnosesCard extends StatelessWidget {
  final List<MedicalRecordItem> items;
  const _PreviousDiagnosesCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.diagnosesPreviousTitle),
      subtitle: context.tr(AppTextKey.diagnosesPreviousSubtitle),
      minHeight: _Layout.previousMinHeight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: items
            .take(4)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.canvas.withValues(alpha: 0.54),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.borderFaint),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.mutedInk.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          color: AppColors.mutedInk,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title.isNotEmpty
                                  ? item.title
                                  : 'Dossier médical',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.notes.isNotEmpty
                                  ? item.notes
                                  : item.doctorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatusBadge(
                        label: switch (item.recordType) {
                          'lab' => 'Analyse',
                          'imaging' => 'Imagerie',
                          _ => 'Autre',
                        },
                        tone: BadgeTone.neutral,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _MetaPill(
                        icon: Icons.event_available_outlined,
                        label: item.formattedDate,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Policy Card ────────────────────────────────────────────────────
class _DiagnosesPolicyCard extends StatelessWidget {
  const _DiagnosesPolicyCard();
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.diagnosesPolicyTitle),
      minHeight: _Layout.sidePanelMinHeight,
      trailing: StatusBadge(
        label: context.tr(AppTextKey.diagnosesReadOnly),
        tone: BadgeTone.neutral,
        icon: Icons.lock_outline,
      ),
      child: Text(
        context.tr(AppTextKey.diagnosesPolicyBody),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedInk,
          height: 1.45,
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/clinical_session_gate.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';
// import '../../data/models/dossier_models.dart';

// abstract final class _DiagnosesLayout {
//   static const double heroMinHeight = 438;
//   static const double sidePanelMinHeight = 220;
//   static const double previousMinHeight = 206;
//   static const double chartHeight = 138;
//   static const double diagnosisTileMinHeight = 126;
// }

// class DiagnosesScreen extends StatelessWidget {
//   const DiagnosesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ClinicalSessionGate(builder: (s) => _DiagnosesContent(session: s));
//   }
// }

// class _DiagnosesContent extends StatelessWidget {
//   final PatientSession session;
//   const _DiagnosesContent({required this.session});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _DiagnosesToolbar(),
//         const SizedBox(height: AppSpacing.lg),
//         const _DiagnosesClinicalHeader(),
//         const SizedBox(height: AppSpacing.lg),
//         const Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(flex: 9, child: _CurrentDiagnosesBoard()),
//             SizedBox(width: AppSpacing.lg),
//             Expanded(
//               flex: 4,
//               child: Column(
//                 children: [
//                   _DiagnosisTrendCard(),
//                   SizedBox(height: AppSpacing.lg),
//                   _DiagnosesPolicyCard(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: AppSpacing.lg),
//         const _PreviousDiagnosesCard(),
//       ],
//     );
//   }
// }

// class _DiagnosisItem {
//   const _DiagnosisItem({
//     required this.titleKey,
//     required this.statusKey,
//     required this.severityKey,
//     required this.dateKey,
//     required this.noteKey,
//     required this.icon,
//     required this.tone,
//     this.critical = false,
//   });

//   final AppTextKey titleKey;
//   final AppTextKey statusKey;
//   final AppTextKey severityKey;
//   final AppTextKey dateKey;
//   final AppTextKey noteKey;
//   final IconData icon;
//   final Color tone;
//   final bool critical;
// }

// abstract final class _DiagnosesData {
//   static const items = [
//     _DiagnosisItem(
//       titleKey: AppTextKey.diagnosesDiabetesTitle,
//       statusKey: AppTextKey.diagnosesStatusCurrent,
//       severityKey: AppTextKey.diagnosesSeverityHigh,
//       dateKey: AppTextKey.diagnosesDateApr13,
//       noteKey: AppTextKey.diagnosesNoteDiabetes,
//       icon: Icons.bloodtype_outlined,
//       tone: AppColors.critical,
//       critical: true,
//     ),
//     _DiagnosisItem(
//       titleKey: AppTextKey.diagnosesHypertensionTitle,
//       statusKey: AppTextKey.diagnosesStatusCurrent,
//       severityKey: AppTextKey.diagnosesSeverityMedium,
//       dateKey: AppTextKey.diagnosesDateMar02,
//       noteKey: AppTextKey.diagnosesNoteHypertension,
//       icon: Icons.monitor_heart_outlined,
//       tone: AppColors.primary,
//     ),
//   ];

//   static const previousItems = [
//     _DiagnosisItem(
//       titleKey: AppTextKey.diagnosesAsthmaTitle,
//       statusKey: AppTextKey.diagnosesStatusPrevious,
//       severityKey: AppTextKey.diagnosesSeverityLow,
//       dateKey: AppTextKey.diagnosesDateJan18,
//       noteKey: AppTextKey.diagnosesNoteAsthma,
//       icon: Icons.air_outlined,
//       tone: AppColors.mutedInk,
//     ),
//   ];
// }

// class _DiagnosesToolbar extends StatelessWidget {
//   const _DiagnosesToolbar();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.lg,
//         vertical: AppSpacing.sm,
//       ),
//       decoration: const BoxDecoration(
//         border: Border(
//           top: BorderSide(color: AppColors.borderFaint, width: 0.7),
//           bottom: BorderSide(color: AppColors.borderFaint, width: 0.7),
//         ),
//       ),
//       child: Row(
//         children: [
//           _ToolbarChip(
//             icon: Icons.tune_rounded,
//             label: context.tr(AppTextKey.diagnosesColumnStatus),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _ToolbarChip(
//             icon: Icons.calendar_month_outlined,
//             label: context.tr(AppTextKey.diagnosesColumnDate),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _ToolbarChip(
//             icon: Icons.shield_outlined,
//             label: context.tr(AppTextKey.diagnosesReadOnly),
//           ),
//           const Spacer(),
//           StatusBadge(
//             label: context.tr(AppTextKey.diagnosesCurrentTitle),
//             tone: BadgeTone.neutral,
//             icon: Icons.medical_information_outlined,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ToolbarChip extends StatelessWidget {
//   const _ToolbarChip({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.md,
//         vertical: AppSpacing.sm,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.glassSurfaceStrong,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 15, color: AppColors.mutedInk),
//           const SizedBox(width: AppSpacing.xs),
//           Text(
//             label,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DiagnosesClinicalHeader extends StatelessWidget {
//   const _DiagnosesClinicalHeader();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.lg,
//         vertical: AppSpacing.md,
//       ),
//       decoration: const BoxDecoration(
//         border: Border(
//           top: BorderSide(color: AppColors.borderFaint, width: 0.7),
//           bottom: BorderSide(color: AppColors.borderFaint, width: 0.7),
//         ),
//       ),
//       child: Row(
//         children: [
//           _ClinicalHeaderMetric(
//             label: context.tr(AppTextKey.diagnosesCurrentTitle),
//             value: _DiagnosesData.items.length.toString(),
//             tone: AppColors.critical,
//           ),
//           const SizedBox(width: AppSpacing.xl),
//           _ClinicalHeaderMetric(
//             label: context.tr(AppTextKey.diagnosesPreviousTitle),
//             value: _DiagnosesData.previousItems.length.toString(),
//             tone: AppColors.primary,
//           ),
//           const SizedBox(width: AppSpacing.xl),
//           _ClinicalHeaderMetric(
//             label: context.tr(AppTextKey.diagnosesColumnSeverity),
//             value: context.tr(AppTextKey.diagnosesSeverityHigh),
//             tone: AppColors.critical,
//             compact: true,
//           ),
//           const Spacer(),
//           for (final item in _DiagnosesData.items) ...[
//             _HeaderDiagnosisChip(item: item),
//             const SizedBox(width: AppSpacing.sm),
//           ],
//           StatusBadge(
//             label: context.tr(AppTextKey.diagnosesReadOnly),
//             tone: BadgeTone.neutral,
//             icon: Icons.visibility_outlined,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ClinicalHeaderMetric extends StatelessWidget {
//   const _ClinicalHeaderMetric({
//     required this.label,
//     required this.value,
//     required this.tone,
//     this.compact = false,
//   });

//   final String label;
//   final String value;
//   final Color tone;
//   final bool compact;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: compact ? 128 : 92,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.mutedInk,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 3),
//           Text(
//             value,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               color: tone,
//               fontWeight: FontWeight.w900,
//               letterSpacing: -0.2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _HeaderDiagnosisChip extends StatelessWidget {
//   const _HeaderDiagnosisChip({required this.item});

//   final _DiagnosisItem item;

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
//           Icon(item.icon, color: item.tone, size: 14),
//           const SizedBox(width: AppSpacing.xs),
//           Text(
//             context.tr(item.titleKey),
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CurrentDiagnosesBoard extends StatelessWidget {
//   const _CurrentDiagnosesBoard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.diagnosesCurrentTitle),
//       subtitle: context.tr(AppTextKey.diagnosesCurrentSubtitle),
//       minHeight: _DiagnosesLayout.heroMinHeight,
//       padding: EdgeInsets.zero,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.diagnosesSeverityHigh),
//         tone: BadgeTone.critical,
//       ),
//       child: const SizedBox(height: 360, child: _DiagnosisRoadmap()),
//     );
//   }
// }

// class _DiagnosisRoadmap extends StatelessWidget {
//   const _DiagnosisRoadmap();

//   static const _previousX = 0.14;
//   static const _hypertensionX = 0.50;
//   static const _diabetesX = 0.82;

//   @override
//   Widget build(BuildContext context) {
//     final previous = _DiagnosesData.previousItems.first;
//     final hypertension = _DiagnosesData.items[1];
//     final diabetes = _DiagnosesData.items[0];

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final width = constraints.maxWidth;
//         return Stack(
//           children: [
//             Positioned.fill(
//               child: CustomPaint(
//                 painter: const _DiagnosisRoadmapPainter(
//                   nodes: [_previousX, _hypertensionX, _diabetesX],
//                 ),
//               ),
//             ),
//             Positioned(
//               left: width * _previousX + AppSpacing.sm,
//               top: 12,
//               child: _RoadmapDateNode(item: previous),
//             ),
//             Positioned(
//               left: width * _hypertensionX + AppSpacing.sm,
//               top: 12,
//               child: _RoadmapDateNode(item: hypertension),
//             ),
//             Positioned(
//               left: width * _diabetesX + AppSpacing.sm,
//               top: 12,
//               child: _RoadmapDateNode(item: diabetes, highlighted: true),
//             ),
//             Positioned(
//               left: AppSpacing.lg,
//               top: 126,
//               width: width * 0.29,
//               child: _DiagnosisTile(item: previous),
//             ),
//             Positioned(
//               left: width * 0.35,
//               top: 176,
//               width: width * 0.30,
//               child: _DiagnosisTile(item: hypertension),
//             ),
//             Positioned(
//               right: AppSpacing.lg,
//               top: 126,
//               width: width * 0.30,
//               child: _DiagnosisTile(item: diabetes, highlighted: true),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _RoadmapDateNode extends StatelessWidget {
//   const _RoadmapDateNode({required this.item, this.highlighted = false});

//   final _DiagnosisItem item;
//   final bool highlighted;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 132,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             context.tr(item.dateKey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             context.tr(item.statusKey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.mutedInk,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DiagnosisRoadmapPainter extends CustomPainter {
//   const _DiagnosisRoadmapPainter({required this.nodes});

//   final List<double> nodes;

//   @override
//   void paint(Canvas canvas, Size size) {
//     const timelineY = 35.0;
//     final linePaint = Paint()
//       ..color = AppColors.borderSoft
//       ..strokeWidth = 1
//       ..strokeCap = StrokeCap.round;
//     final connectorPaint = Paint()
//       ..color = AppColors.borderSoft
//       ..strokeWidth = 1
//       ..style = PaintingStyle.stroke;
//     final nodePaint = Paint()
//       ..color = AppColors.surface
//       ..style = PaintingStyle.fill;
//     final nodeStrokePaint = Paint()
//       ..color = AppColors.borderSoft
//       ..strokeWidth = 1
//       ..style = PaintingStyle.stroke;

//     canvas.drawLine(
//       Offset(0, timelineY),
//       Offset(size.width, timelineY),
//       linePaint,
//     );

//     for (final node in nodes) {
//       final x = size.width * node;
//       canvas.drawCircle(Offset(x, timelineY), 5, nodePaint);
//       canvas.drawCircle(Offset(x, timelineY), 5, nodeStrokePaint);
//     }

//     final connectors = [
//       (x: size.width * nodes[0], top: timelineY + 5, bottom: 126.0),
//       (x: size.width * nodes[1], top: timelineY + 5, bottom: 176.0),
//       (x: size.width * nodes[2], top: timelineY + 5, bottom: 126.0),
//     ];

//     for (final connector in connectors) {
//       final path = Path()
//         ..moveTo(connector.x, connector.top)
//         ..cubicTo(
//           connector.x,
//           connector.top + 42,
//           connector.x - 42,
//           connector.bottom - 30,
//           connector.x,
//           connector.bottom,
//         );
//       canvas.drawPath(path, connectorPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _DiagnosisRoadmapPainter oldDelegate) {
//     return oldDelegate.nodes != nodes;
//   }
// }

// class _DiagnosisTile extends StatelessWidget {
//   const _DiagnosisTile({required this.item, this.highlighted = false});

//   final _DiagnosisItem item;
//   final bool highlighted;

//   @override
//   Widget build(BuildContext context) {
//     final borderColor = highlighted
//         ? item.tone.withValues(alpha: 0.24)
//         : AppColors.borderFaint;

//     return Container(
//       constraints: const BoxConstraints(
//         minHeight: _DiagnosesLayout.diagnosisTileMinHeight,
//       ),
//       padding: const EdgeInsets.all(AppSpacing.md),
//       decoration: BoxDecoration(
//         color: AppColors.glassSurfaceStrong,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: borderColor),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: item.tone.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(item.icon, color: item.tone, size: 17),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(item.titleKey),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: item.critical ? AppColors.critical : AppColors.ink,
//                     fontWeight: FontWeight.w900,
//                     height: 1.15,
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.xs),
//                 StatusBadge(
//                   label: context.tr(item.severityKey),
//                   tone: item.critical ? BadgeTone.critical : BadgeTone.neutral,
//                 ),
//                 const SizedBox(height: AppSpacing.sm),
//                 Text(
//                   context.tr(item.noteKey),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.mutedInk,
//                     height: 1.35,
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.sm),
//                 Wrap(
//                   spacing: AppSpacing.xs,
//                   runSpacing: AppSpacing.xs,
//                   children: [
//                     _DiagnosisMetaPill(
//                       icon: Icons.event_available_outlined,
//                       label: context.tr(item.dateKey),
//                     ),
//                     _DiagnosisMetaPill(
//                       icon: Icons.verified_outlined,
//                       label: context.tr(item.statusKey),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DiagnosisMetaPill extends StatelessWidget {
//   const _DiagnosisMetaPill({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 124),
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.sm,
//           vertical: AppSpacing.xs,
//         ),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(color: AppColors.borderFaint),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 13, color: AppColors.mutedInk),
//             const SizedBox(width: 4),
//             Flexible(
//               child: Text(
//                 label,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                   color: AppColors.mutedInk,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DiagnosisTrendCard extends StatelessWidget {
//   const _DiagnosisTrendCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.diagnosesColumnSeverity),
//       subtitle: context.tr(AppTextKey.diagnosesSubtitle),
//       minHeight: _DiagnosesLayout.sidePanelMinHeight,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.diagnosesReadOnly),
//         tone: BadgeTone.neutral,
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               _SeverityMetric(
//                 label: context.tr(AppTextKey.diagnosesCurrentTitle),
//                 value: _DiagnosesData.items.length.toString(),
//                 tone: AppColors.critical,
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               _SeverityMetric(
//                 label: context.tr(AppTextKey.diagnosesPreviousTitle),
//                 value: _DiagnosesData.previousItems.length.toString(),
//                 tone: AppColors.primary,
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           SizedBox(
//             height: _DiagnosesLayout.chartHeight,
//             child: CustomPaint(
//               painter: const _DiagnosisTrendPainter(),
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: const [
//                     _TrendBar(
//                       labelKey: AppTextKey.diagnosesDateJan18,
//                       heightFactor: 0.32,
//                       tone: AppColors.mutedInk,
//                     ),
//                     _TrendBar(
//                       labelKey: AppTextKey.diagnosesDateMar02,
//                       heightFactor: 0.58,
//                       tone: AppColors.primary,
//                     ),
//                     _TrendBar(
//                       labelKey: AppTextKey.diagnosesDateApr13,
//                       heightFactor: 0.88,
//                       tone: AppColors.critical,
//                       highlighted: true,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SeverityMetric extends StatelessWidget {
//   const _SeverityMetric({
//     required this.label,
//     required this.value,
//     required this.tone,
//   });

//   final String label;
//   final String value;
//   final Color tone;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.md,
//           vertical: AppSpacing.sm,
//         ),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.borderFaint),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 7,
//               height: 7,
//               decoration: BoxDecoration(
//                 color: tone.withValues(
//                   alpha: tone == AppColors.critical ? 0.72 : 0.42,
//                 ),
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: AppSpacing.sm),
//             Expanded(
//               child: Text(
//                 label,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                   color: AppColors.mutedInk,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: tone,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TrendBar extends StatelessWidget {
//   const _TrendBar({
//     required this.labelKey,
//     required this.heightFactor,
//     required this.tone,
//     this.highlighted = false,
//   });

//   final AppTextKey labelKey;
//   final double heightFactor;
//   final Color tone;
//   final bool highlighted;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
//               child: Stack(
//                 alignment: Alignment.bottomCenter,
//                 children: [
//                   FractionallySizedBox(
//                     heightFactor: heightFactor,
//                     widthFactor: highlighted ? 0.18 : 0.14,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: tone.withValues(
//                           alpha: highlighted ? 0.32 : 0.20,
//                         ),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                     ),
//                   ),
//                   Align(
//                     alignment: Alignment(0, 1 - (heightFactor * 2)),
//                     child: Container(
//                       width: highlighted ? 6 : 5,
//                       height: highlighted ? 6 : 5,
//                       decoration: BoxDecoration(
//                         color: highlighted
//                             ? AppColors.critical
//                             : AppColors.mutedInk,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           Text(
//             context.tr(labelKey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.mutedInk,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DiagnosisTrendPainter extends CustomPainter {
//   const _DiagnosisTrendPainter();

//   @override
//   void paint(Canvas canvas, Size size) {
//     final gridPaint = Paint()
//       ..color = AppColors.borderFaint.withValues(alpha: 0.50)
//       ..strokeWidth = 0.35;
//     final bandPaint = Paint()
//       ..color = Colors.transparent
//       ..style = PaintingStyle.fill;
//     final trendPaint = Paint()
//       ..color = AppColors.critical.withValues(alpha: 0.28)
//       ..strokeWidth = 0.7
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;
//     final faintTrendPaint = Paint()
//       ..color = AppColors.mutedInk.withValues(alpha: 0.10)
//       ..strokeWidth = 0.55
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;

//     final band = Rect.fromLTWH(
//       0,
//       size.height * 0.17,
//       size.width,
//       size.height * 0.28,
//     );
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(band, const Radius.circular(10)),
//       bandPaint,
//     );

//     for (final factor in const [0.25, 0.5, 0.75]) {
//       final y = size.height * factor;
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }

//     final points = [
//       Offset(size.width * 0.17, size.height * (1 - 0.32)),
//       Offset(size.width * 0.50, size.height * (1 - 0.58)),
//       Offset(size.width * 0.83, size.height * (1 - 0.88)),
//     ];
//     final path = Path()
//       ..moveTo(points[0].dx, points[0].dy)
//       ..cubicTo(
//         size.width * 0.30,
//         points[0].dy,
//         size.width * 0.36,
//         points[1].dy,
//         points[1].dx,
//         points[1].dy,
//       )
//       ..cubicTo(
//         size.width * 0.64,
//         points[1].dy,
//         size.width * 0.70,
//         points[2].dy,
//         points[2].dx,
//         points[2].dy,
//       );
//     canvas.drawPath(path, faintTrendPaint);
//     canvas.drawPath(path, trendPaint);

//     for (var i = 0; i < points.length; i++) {
//       final point = points[i];
//       final critical = i == points.length - 1;
//       canvas.drawCircle(
//         point,
//         critical ? 2.8 : 2.2,
//         Paint()
//           ..color = critical
//               ? AppColors.critical.withValues(alpha: 0.62)
//               : AppColors.mutedInk.withValues(alpha: 0.32)
//           ..style = PaintingStyle.fill,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _DiagnosisTrendPainter oldDelegate) => false;
// }

// class _PreviousDiagnosesCard extends StatelessWidget {
//   const _PreviousDiagnosesCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.diagnosesPreviousTitle),
//       subtitle: context.tr(AppTextKey.diagnosesPreviousSubtitle),
//       minHeight: _DiagnosesLayout.previousMinHeight,
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       child: Column(
//         children: [
//           for (final item in _DiagnosesData.previousItems)
//             _DiagnosisArchiveTile(item: item),
//         ],
//       ),
//     );
//   }
// }

// class _DiagnosisArchiveTile extends StatelessWidget {
//   const _DiagnosisArchiveTile({required this.item});

//   final _DiagnosisItem item;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.canvas.withValues(alpha: 0.54),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               color: item.tone.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(item.icon, color: item.tone, size: 19),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(item.titleKey),
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   context.tr(item.noteKey),
//                   style: Theme.of(
//                     context,
//                   ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           StatusBadge(
//             label: context.tr(item.severityKey),
//             tone: BadgeTone.neutral,
//           ),
//           const SizedBox(width: AppSpacing.md),
//           _DiagnosisMetaPill(
//             icon: Icons.event_available_outlined,
//             label: context.tr(item.dateKey),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DiagnosesPolicyCard extends StatelessWidget {
//   const _DiagnosesPolicyCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.diagnosesPolicyTitle),
//       minHeight: _DiagnosesLayout.sidePanelMinHeight,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.diagnosesReadOnly),
//         tone: BadgeTone.neutral,
//         icon: Icons.lock_outline,
//       ),
//       child: Text(
//         context.tr(AppTextKey.diagnosesPolicyBody),
//         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//           color: AppColors.mutedInk,
//           height: 1.45,
//         ),
//       ),
//     );
//   }
// }
