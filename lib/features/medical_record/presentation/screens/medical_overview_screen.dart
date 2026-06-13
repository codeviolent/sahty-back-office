import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

abstract final class _MedicalOverviewLayout {
  static const double anatomyMinHeight = 460;
  static const double bottomCardMinHeight = 276;
  static const double summaryTileMinH = 54;
  static const double patientAvatarSize = 56;
  static const double medicationRowHeight = 64;
}

// ── Marqueur anatomique (données dynamiques) ───────────────────────
class _Marker {
  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final Offset anchor;
  final Offset callout;
  const _Marker({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.anchor,
    required this.callout,
  });
}

// ══════════════════════════════════════════════════════════════════
// Screen principal — StatelessWidget pur
// ══════════════════════════════════════════════════════════════════
class MedicalOverviewScreen extends StatelessWidget {
  const MedicalOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClinicalSessionGate(
      builder: (session) => _OverviewBlocView(session: session),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Vue BLoC — StatelessWidget — dispatch via addPostFrameCallback
// ══════════════════════════════════════════════════════════════════
class _OverviewBlocView extends StatelessWidget {
  final PatientSession session;
  const _OverviewBlocView({required this.session});

  @override
  Widget build(BuildContext context) {
    return SectionDispatcher(
      section: DossierSection.overview,
      builder: (ctx, state, session) {
        final data = getOverviewData(state);
        // if (data == null) {
        //   // Ne devrait pas arriver (SectionDispatcher le gère)
        //   return const SectionLoading(label: 'Chargement du résumé médical...');
        // }
        // ── Données disponibles ────────────────────────────────────
        return _OverviewContent(session: session, data: data!);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Contenu — StatelessWidget — données réelles du BLoC
// ══════════════════════════════════════════════════════════════════
class _OverviewContent extends StatelessWidget {
  final PatientSession session;
  final PatientOverviewData data;
  const _OverviewContent({required this.session, required this.data});

  List<_Marker> _buildMarkers() {
    final bp =
        data.latestVital('blood_pressure') ?? data.latestVital('heart_rate');
    return [
      _Marker(
        label: 'Constantes',
        value: bp != null ? '${bp.value} ${bp.unit}' : 'N/D',
        icon: Icons.monitor_heart_outlined,
        tone: AppColors.critical,
        anchor: const Offset(0.47, 0.29),
        callout: const Offset(0.70, 0.20),
      ),
      _Marker(
        label: 'Diagnostics',
        value: '${data.diagnosesCount} actif(s)',
        icon: Icons.medical_information_outlined,
        tone: AppColors.primary,
        anchor: const Offset(0.50, 0.47),
        callout: const Offset(0.08, 0.35),
      ),
      _Marker(
        label: 'Traitements',
        value: '${data.activePrescriptions.length} en cours',
        icon: Icons.medication_outlined,
        tone: AppColors.info,
        anchor: const Offset(0.43, 0.58),
        callout: const Offset(0.69, 0.56),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final criticals = data.allergies
        .where((a) => a.severity == 'high')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Alerte allergies critiques ─────────────────────────────
        _CriticalAllergyBanner(session: session, allergies: criticals),
        const SizedBox(height: AppSpacing.lg),

        // ── Carte anatomique ───────────────────────────────────────
        _AnatomyCard(session: session, data: data, markers: _buildMarkers()),
        const SizedBox(height: AppSpacing.lg),

        // ── Bas de page ───────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _MedicationCard(prescriptions: data.activePrescriptions),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 5,
              child: _LastVisitCard(lastVisit: data.lastAppointment),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Bannière allergies critiques
// ══════════════════════════════════════════════════════════════════
class _CriticalAllergyBanner extends StatelessWidget {
  final PatientSession session;
  final List<AllergyItem> allergies;
  const _CriticalAllergyBanner({
    required this.session,
    required this.allergies,
  });

  @override
  Widget build(BuildContext context) {
    final hasCritical = allergies.isNotEmpty;
    final text = hasCritical
        ? 'ALLERGIE(S) CRITIQUE(S) : '
              '${allergies.map((a) => a.allergen.toUpperCase()).join("  ·  ")}'
        : context.tr(AppTextKey.medicalAllergyTitle);
    final msg = hasCritical
        ? 'Éviter tout contact — mentionner avant toute prescription.'
        : context.tr(AppTextKey.medicalAllergyMessage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.critical,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.critical,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  msg,
                  style: const TextStyle(
                    color: AppColors.critical,
                    fontSize: 11,
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

// ══════════════════════════════════════════════════════════════════
// Carte anatomique avec SVG + marqueurs dynamiques
// ══════════════════════════════════════════════════════════════════
class _AnatomyCard extends StatelessWidget {
  final PatientSession session;
  final PatientOverviewData data;
  final List<_Marker> markers;
  const _AnatomyCard({
    required this.session,
    required this.data,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.medicalSummaryTitle),
      subtitle: context.tr(AppTextKey.medicalSummarySubtitle),
      minHeight: _MedicalOverviewLayout.anatomyMinHeight,
      trailing: const StatusBadge(
        label: 'Lecture seule',
        tone: BadgeTone.neutral,
        icon: Icons.visibility_outlined,
      ),
      child: SizedBox(
        height: 386,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _PatientPanel(session: session, data: data),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 5, child: _HumanAnatomyMap(markers: markers)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 4, child: _ClinicalPanel(data: data)),
          ],
        ),
      ),
    );
  }
}

// ── SVG anatomique ─────────────────────────────────────────────────
class _HumanAnatomyMap extends StatelessWidget {
  final List<_Marker> markers;
  const _HumanAnatomyMap({required this.markers});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.borderFaint),
          ),
          child: Stack(
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/images/human.svg',
                  height: c.maxHeight - AppSpacing.xl,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _AnatomyLinePainter(markers: markers),
                ),
              ),
              for (final m in markers) ...[
                _AnatomyDot(marker: m, canvasSize: size),
                _AnatomyCallout(marker: m, canvasSize: size),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AnatomyDot extends StatelessWidget {
  final _Marker marker;
  final Size canvasSize;
  const _AnatomyDot({required this.marker, required this.canvasSize});

  @override
  Widget build(BuildContext context) {
    const sz = 18.0;
    return Positioned(
      left: canvasSize.width * marker.anchor.dx - sz / 2,
      top: canvasSize.height * marker.anchor.dy - sz / 2,
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: marker.tone, width: 1.5),
          boxShadow: AppColors.cardShadow,
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: marker.tone,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnatomyCallout extends StatelessWidget {
  final _Marker marker;
  final Size canvasSize;
  const _AnatomyCallout({required this.marker, required this.canvasSize});

  @override
  Widget build(BuildContext context) {
    const w = 158.0, h = 58.0;
    return Positioned(
      left: (canvasSize.width * marker.callout.dx).clamp(
        AppSpacing.sm,
        canvasSize.width - w - AppSpacing.sm,
      ),
      top: (canvasSize.height * marker.callout.dy).clamp(
        AppSpacing.sm,
        canvasSize.height - h - AppSpacing.sm,
      ),
      width: w,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: marker.tone.withValues(alpha: 0.22)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(marker.icon, color: marker.tone, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    marker.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    marker.value,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnatomyLinePainter extends CustomPainter {
  final List<_Marker> markers;
  const _AnatomyLinePainter({required this.markers});

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in markers) {
      final start = Offset(size.width * m.anchor.dx, size.height * m.anchor.dy);
      final end = Offset(size.width * m.callout.dx, size.height * m.callout.dy);
      final paint = Paint()
        ..color = m.tone.withValues(alpha: 0.55)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + end.dx) / 2,
          start.dy,
          end.dx,
          end.dy + 20,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AnatomyLinePainter old) => old.markers != markers;
}

// ── Panel gauche : identité patient ───────────────────────────────
class _PatientPanel extends StatelessWidget {
  final PatientSession session;
  final PatientOverviewData data;
  const _PatientPanel({required this.session, required this.data});

  @override
  Widget build(BuildContext context) {
    final ageLabel = data.age != null ? '${data.age} ans' : '—';
    final lastDoc =
        data.lastAppointment?.doctorName ??
        context.tr(AppTextKey.medicalDoctorValue);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(AppTextKey.medicalIdentityTitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(AppTextKey.medicalIdentitySubtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Avatar + nom réel depuis la session
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _MedicalOverviewLayout.patientAvatarSize,
                  height: _MedicalOverviewLayout.patientAvatarSize,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      session.initials,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Patient #${session.patientId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Âge + Groupe sanguin (âge depuis overview, GS depuis session)
          Row(
            children: [
              Expanded(
                child: _IdentityMetricTile(
                  icon: Icons.cake_outlined,
                  label: context.tr(AppTextKey.medicalAgeLabel),
                  value: ageLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _IdentityMetricTile(
                  icon: Icons.bloodtype_outlined,
                  label: context.tr(AppTextKey.medicalBloodTypeLabel),
                  value: session.bloodType,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Dernier médecin
          _IdentityDataRow(
            icon: Icons.medical_services_outlined,
            label: context.tr(AppTextKey.medicalDoctorLabel),
            value: lastDoc,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Session ouverte depuis
          _IdentityDataRow(
            icon: Icons.lock_clock_outlined,
            label: context.tr(AppTextKey.medicalLastOpenLabel),
            value: session.durationLabel,
          ),
          const Spacer(),

          // Rail lecture seule
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.86),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.tr(AppTextKey.medicalReadOnly),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Tags dynamiques
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (data.diagnosesCount > 0)
                StatusBadge(
                  label: '${data.diagnosesCount} diagnostic(s)',
                  tone: BadgeTone.neutral,
                ),
              if (data.activePrescriptions.isNotEmpty)
                StatusBadge(
                  label: '${data.activePrescriptions.length} traitement(s)',
                  tone: BadgeTone.neutral,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _IdentityMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
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
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _IdentityDataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderFaint),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.mutedInk),
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
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel droit : résumé clinique ─────────────────────────────────
class _ClinicalPanel extends StatelessWidget {
  final PatientOverviewData data;
  const _ClinicalPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final bp = data.latestVital('blood_pressure');
    final glucose = data.latestVital('blood_sugar');
    final critVal = bp != null
        ? '${bp.value} ${bp.unit}'
        : (glucose != null ? '${glucose.value} ${glucose.unit}' : 'N/D');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(AppTextKey.medicalSummaryTitle),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr(AppTextKey.medicalSummarySubtitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.sm),

          _SummaryTile(
            icon: Icons.monitor_heart_outlined,
            label: context.tr(AppTextKey.medicalCriticalIndicatorTitle),
            value: critVal,
            tone: BadgeTone.critical,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryTile(
            icon: Icons.medical_information_outlined,
            label: context.tr(AppTextKey.medicalDiagnosisTitle),
            value: '${data.diagnosesCount} actif(s)',
            tone: BadgeTone.neutral,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryTile(
            icon: Icons.medication_outlined,
            label: context.tr(AppTextKey.medicalTreatmentsTitle),
            value: '${data.activePrescriptions.length} en cours',
            tone: BadgeTone.neutral,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryTile(
            icon: Icons.vaccines_outlined,
            label: context.tr(AppTextKey.medicalVaccinesTitle),
            value:
                '${data.completedVaccinesCount}/${data.vaccinesCount} complets',
            tone: BadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BadgeTone tone;
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone == BadgeTone.critical
        ? AppColors.critical
        : AppColors.mutedInk;
    return Container(
      constraints: const BoxConstraints(
        minHeight: _MedicalOverviewLayout.summaryTileMinH,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
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

// ── Médicaments actifs (depuis overviewData.activePrescriptions) ──
class _MedicationCard extends StatelessWidget {
  final List<PrescriptionItem> prescriptions;
  const _MedicationCard({required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.medicalMedicationsTitle),
      subtitle: context.tr(AppTextKey.medicalMedicationsSubtitle),
      minHeight: _MedicalOverviewLayout.bottomCardMinHeight,
      padding: EdgeInsets.zero,
      trailing: prescriptions.isNotEmpty
          ? StatusBadge(
              label: '${prescriptions.length} actif(s)',
              tone: BadgeTone.normal,
            )
          : null,
      child: prescriptions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Text(
                  'Aucun médicament actif',
                  style: TextStyle(color: AppColors.mutedInk, fontSize: 13),
                ),
              ),
            )
          : Column(
              children: prescriptions.take(5).toList().asMap().entries.map((e) {
                return Column(
                  children: [
                    _MedicationRow(item: e.value),
                    if (e.key < prescriptions.take(5).length - 1)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  final PrescriptionItem item;
  const _MedicationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // dosage + frequency concaténés
    final subtitle = [
      if (item.dosage.isNotEmpty) item.dosage,
      if (item.frequency.isNotEmpty) item.frequency,
    ].join(' — ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _MedicalOverviewLayout.medicationRowHeight,
        child: Row(
          children: [
            const Icon(
              Icons.medication_liquid_outlined,
              color: AppColors.mutedInk,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicationName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle.isNotEmpty ? subtitle : '—',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const StatusBadge(label: 'Actif', tone: BadgeTone.normal),
          ],
        ),
      ),
    );
  }
}

// ── Dernière visite (depuis overviewData.lastAppointment) ─────────
class _LastVisitCard extends StatelessWidget {
  final OverviewLastVisit? lastVisit;
  const _LastVisitCard({required this.lastVisit});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.medicalLastVisitTitle),
      subtitle: context.tr(AppTextKey.medicalLastVisitSubtitle),
      minHeight: _MedicalOverviewLayout.bottomCardMinHeight,
      trailing: lastVisit != null
          ? StatusBadge(label: lastVisit!.date, tone: BadgeTone.neutral)
          : null,
      child: lastVisit == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Aucune visite enregistrée',
                  style: TextStyle(color: AppColors.mutedInk, fontSize: 13),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Motif
                Text(
                  lastVisit!.reason?.isNotEmpty == true
                      ? lastVisit!.reason!
                      : 'Consultation médicale',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Médecin
                if (lastVisit!.doctorName != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outlined,
                        size: 14,
                        color: AppColors.mutedInk,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        lastVisit!.doctorName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusBadge(
                      label: context.tr(AppTextKey.medicalTagDiabetesFollowUp),
                      tone: BadgeTone.neutral,
                    ),
                    const StatusBadge(
                      label: 'Lecture seule',
                      tone: BadgeTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:sahty_back_office/core/widgets/clinical_session_gate.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/clinical_alert_banner.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';
// import '../../data/models/dossier_models.dart';

// abstract final class _MedicalOverviewLayout {
//   static const double anatomyMinHeight = 460;
//   static const double bottomCardMinHeight = 276;
//   static const double summaryTileMinHeight = 54;
//   static const double patientAvatarSize = 56;
//   static const double medicationRowHeight = 64;
// }

// class _AnatomyMarkerData {
//   const _AnatomyMarkerData({
//     required this.labelKey,
//     required this.valueKey,
//     required this.icon,
//     required this.tone,
//     required this.anchor,
//     required this.callout,
//   });

//   final AppTextKey labelKey;
//   final AppTextKey valueKey;
//   final IconData icon;
//   final Color tone;
//   final Offset anchor;
//   final Offset callout;
// }

// abstract final class _AnatomyMarkers {
//   // Coordinates are normalized to the anatomy canvas. They map existing
//   // medical content to body regions without adding unrelated data.
//   static const items = [
//     _AnatomyMarkerData(
//       labelKey: AppTextKey.medicalCriticalIndicatorTitle,
//       valueKey: AppTextKey.medicalCriticalIndicatorValue,
//       icon: Icons.monitor_heart_outlined,
//       tone: AppColors.critical,
//       anchor: Offset(0.47, 0.29),
//       callout: Offset(0.70, 0.20),
//     ),
//     _AnatomyMarkerData(
//       labelKey: AppTextKey.medicalDiagnosisTitle,
//       valueKey: AppTextKey.medicalDiagnosisValue,
//       icon: Icons.medical_information_outlined,
//       tone: AppColors.primary,
//       anchor: Offset(0.50, 0.47),
//       callout: Offset(0.08, 0.35),
//     ),
//     _AnatomyMarkerData(
//       labelKey: AppTextKey.medicalTreatmentsTitle,
//       valueKey: AppTextKey.medicalTreatmentsValue,
//       icon: Icons.medication_outlined,
//       tone: AppColors.info,
//       anchor: Offset(0.43, 0.58),
//       callout: Offset(0.69, 0.56),
//     ),
//   ];
// }

// class MedicalOverviewScreen extends StatelessWidget {
//   const MedicalOverviewScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ClinicalSessionGate(
//       builder: (s) => _MedicalOverviewBody(session: s),
//     );
//   }
// }

// class _MedicalOverviewBody extends StatelessWidget {
//   final PatientSession session;
//   const _MedicalOverviewBody({required this.session});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ClinicalAlertBanner(
//           title: session.criticalAllergies.isNotEmpty
//               ? 'Allergies critiques: ${session.criticalAllergies.map((a) => a.allergen).join(', ')}'
//               : context.tr(AppTextKey.medicalAllergyTitle),
//           message: context.tr(AppTextKey.medicalAllergyMessage),
//           isCritical: true,
//         ),
//         const SizedBox(height: AppSpacing.lg),
//         const _AnatomyOverviewCard(),
//         const SizedBox(height: AppSpacing.lg),
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Expanded(flex: 6, child: _MedicationCard()),
//             const SizedBox(width: AppSpacing.lg),
//             Expanded(flex: 5, child: _LastVisitCard()),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _AnatomyOverviewCard extends StatelessWidget {
//   const _AnatomyOverviewCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.medicalSummaryTitle),
//       subtitle: context.tr(AppTextKey.medicalSummarySubtitle),
//       minHeight: _MedicalOverviewLayout.anatomyMinHeight,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.medicalReadOnly),
//         tone: BadgeTone.neutral,
//         icon: Icons.visibility_outlined,
//       ),
//       child: SizedBox(
//         height: 386,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Expanded(flex: 3, child: _PatientOverviewPanel()),
//             const SizedBox(width: AppSpacing.lg),
//             Expanded(
//               flex: 5,
//               child: _HumanAnatomyMap(markers: _AnatomyMarkers.items),
//             ),
//             const SizedBox(width: AppSpacing.lg),
//             const Expanded(flex: 4, child: _ClinicalOverviewPanel()),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _HumanAnatomyMap extends StatelessWidget {
//   const _HumanAnatomyMap({required this.markers});

//   final List<_AnatomyMarkerData> markers;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final size = Size(constraints.maxWidth, constraints.maxHeight);
//         return DecoratedBox(
//           decoration: BoxDecoration(
//             color: AppColors.canvas.withValues(alpha: 0.48),
//             borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//             border: Border.all(color: AppColors.borderFaint),
//           ),
//           child: Stack(
//             children: [
//               Center(
//                 child: SvgPicture.asset(
//                   'assets/images/human.svg',
//                   height: constraints.maxHeight - AppSpacing.xl,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               Positioned.fill(
//                 child: CustomPaint(
//                   painter: _AnatomyLinePainter(markers: markers),
//                 ),
//               ),
//               for (final marker in markers) ...[
//                 _AnatomyAnchor(marker: marker, canvasSize: size),
//                 _AnatomyCallout(marker: marker, canvasSize: size),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _AnatomyAnchor extends StatelessWidget {
//   const _AnatomyAnchor({required this.marker, required this.canvasSize});

//   final _AnatomyMarkerData marker;
//   final Size canvasSize;

//   @override
//   Widget build(BuildContext context) {
//     const markerSize = 18.0;
//     return Positioned(
//       left: (canvasSize.width * marker.anchor.dx) - markerSize / 2,
//       top: (canvasSize.height * marker.anchor.dy) - markerSize / 2,
//       child: Container(
//         width: markerSize,
//         height: markerSize,
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           shape: BoxShape.circle,
//           border: Border.all(color: marker.tone, width: 1.5),
//           boxShadow: AppColors.cardShadow,
//         ),
//         child: Center(
//           child: Container(
//             width: 6,
//             height: 6,
//             decoration: BoxDecoration(
//               color: marker.tone,
//               shape: BoxShape.circle,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AnatomyCallout extends StatelessWidget {
//   const _AnatomyCallout({required this.marker, required this.canvasSize});

//   final _AnatomyMarkerData marker;
//   final Size canvasSize;

//   @override
//   Widget build(BuildContext context) {
//     const width = 158.0;
//     const height = 58.0;
//     return Positioned(
//       left: (canvasSize.width * marker.callout.dx).clamp(
//         AppSpacing.sm,
//         canvasSize.width - width - AppSpacing.sm,
//       ),
//       top: (canvasSize.height * marker.callout.dy).clamp(
//         AppSpacing.sm,
//         canvasSize.height - height - AppSpacing.sm,
//       ),
//       width: width,
//       child: Container(
//         padding: const EdgeInsets.all(AppSpacing.sm + 2),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//           border: Border.all(color: marker.tone.withValues(alpha: 0.22)),
//           boxShadow: AppColors.cardShadow,
//         ),
//         child: Row(
//           children: [
//             Icon(marker.icon, color: marker.tone, size: 18),
//             const SizedBox(width: AppSpacing.sm),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     context.tr(marker.labelKey),
//                     overflow: TextOverflow.ellipsis,
//                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                       color: AppColors.mutedInk,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     context.tr(marker.valueKey),
//                     overflow: TextOverflow.ellipsis,
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: AppColors.ink,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AnatomyLinePainter extends CustomPainter {
//   const _AnatomyLinePainter({required this.markers});

//   final List<_AnatomyMarkerData> markers;

//   @override
//   void paint(Canvas canvas, Size size) {
//     for (final marker in markers) {
//       final start = Offset(
//         size.width * marker.anchor.dx,
//         size.height * marker.anchor.dy,
//       );
//       final end = Offset(
//         size.width * marker.callout.dx,
//         size.height * marker.callout.dy,
//       );
//       final paint = Paint()
//         ..color = marker.tone.withValues(alpha: 0.55)
//         ..strokeWidth = 1.2
//         ..style = PaintingStyle.stroke;
//       final path = Path()
//         ..moveTo(start.dx, start.dy)
//         ..quadraticBezierTo(
//           (start.dx + end.dx) / 2,
//           start.dy,
//           end.dx,
//           end.dy + 20,
//         );
//       canvas.drawPath(path, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _AnatomyLinePainter oldDelegate) {
//     return oldDelegate.markers != markers;
//   }
// }

// class _PatientOverviewPanel extends StatelessWidget {
//   const _PatientOverviewPanel();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.glassSurfaceStrong,
//         borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//         border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       context.tr(AppTextKey.medicalIdentityTitle),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: AppColors.ink,
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       context.tr(AppTextKey.medicalIdentitySubtitle),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: AppColors.mutedInk,
//                         height: 1.25,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withValues(alpha: 0.08),
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: AppColors.primary.withValues(alpha: 0.16),
//                   ),
//                 ),
//                 child: const Icon(
//                   Icons.verified_user_outlined,
//                   color: AppColors.primary,
//                   size: 16,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           Container(
//             padding: const EdgeInsets.all(AppSpacing.md),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withValues(alpha: 0.055),
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(
//                 color: AppColors.primary.withValues(alpha: 0.12),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: _MedicalOverviewLayout.patientAvatarSize,
//                   height: _MedicalOverviewLayout.patientAvatarSize,
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: AppColors.primary.withValues(alpha: 0.18),
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.person_rounded,
//                     color: AppColors.primary,
//                     size: 26,
//                   ),
//                 ),
//                 const SizedBox(width: AppSpacing.md),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         context.tr(AppTextKey.medicalPatientName),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context).textTheme.titleMedium
//                             ?.copyWith(
//                               fontWeight: FontWeight.w900,
//                               color: AppColors.ink,
//                               height: 1.05,
//                             ),
//                       ),
//                       const SizedBox(height: AppSpacing.xs),
//                       Text(
//                         context.tr(AppTextKey.medicalPatientRecord),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                           color: AppColors.mutedInk,
//                           fontWeight: FontWeight.w700,
//                           height: 1.2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: AppSpacing.md),
//           const Row(
//             children: [
//               Expanded(
//                 child: _IdentityMetricTile(
//                   labelKey: AppTextKey.medicalAgeLabel,
//                   valueKey: AppTextKey.medicalAgeValue,
//                   icon: Icons.cake_outlined,
//                 ),
//               ),
//               SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: _IdentityMetricTile(
//                   labelKey: AppTextKey.medicalBloodTypeLabel,
//                   valueKey: AppTextKey.medicalBloodTypeValue,
//                   icon: Icons.bloodtype_outlined,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           const _IdentityDataRow(
//             labelKey: AppTextKey.medicalDoctorLabel,
//             valueKey: AppTextKey.medicalDoctorValue,
//             icon: Icons.medical_services_outlined,
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           const _IdentityDataRow(
//             labelKey: AppTextKey.medicalLastOpenLabel,
//             valueKey: AppTextKey.medicalLastOpenValue,
//             icon: Icons.lock_clock_outlined,
//           ),
//           const Spacer(),
//           const _IdentityAccessRail(),
//           const SizedBox(height: AppSpacing.md),
//           Wrap(
//             spacing: AppSpacing.sm,
//             runSpacing: AppSpacing.sm,
//             children: [
//               StatusBadge(
//                 label: context.tr(AppTextKey.medicalTagDiabetesFollowUp),
//                 tone: BadgeTone.neutral,
//               ),
//               StatusBadge(
//                 label: context.tr(AppTextKey.medicalTagAnalysisRequired),
//                 tone: BadgeTone.neutral,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _IdentityMetricTile extends StatelessWidget {
//   const _IdentityMetricTile({
//     required this.labelKey,
//     required this.valueKey,
//     required this.icon,
//   });

//   final AppTextKey labelKey;
//   final AppTextKey valueKey;
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.sm),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 14, color: AppColors.primary),
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
//           const SizedBox(height: 2),
//           Text(
//             context.tr(valueKey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _IdentityDataRow extends StatelessWidget {
//   const _IdentityDataRow({
//     required this.labelKey,
//     required this.valueKey,
//     required this.icon,
//   });

//   final AppTextKey labelKey;
//   final AppTextKey valueKey;
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.md,
//         vertical: AppSpacing.sm,
//       ),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.borderFaint),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 15, color: AppColors.mutedInk),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Text(
//               context.tr(labelKey),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                 color: AppColors.mutedInk,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Text(
//             context.tr(valueKey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _IdentityAccessRail extends StatelessWidget {
//   const _IdentityAccessRail();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Container(
//             height: 3,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withValues(alpha: 0.72),
//               borderRadius: BorderRadius.circular(999),
//             ),
//           ),
//         ),
//         const SizedBox(width: AppSpacing.sm),
//         Icon(
//           Icons.visibility_outlined,
//           size: 14,
//           color: AppColors.primary.withValues(alpha: 0.86),
//         ),
//         const SizedBox(width: AppSpacing.sm),
//         Text(
//           context.tr(AppTextKey.medicalReadOnly),
//           style: Theme.of(context).textTheme.labelSmall?.copyWith(
//             color: AppColors.primary,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ClinicalOverviewPanel extends StatelessWidget {
//   const _ClinicalOverviewPanel();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             context.tr(AppTextKey.medicalSummaryTitle),
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             context.tr(AppTextKey.medicalSummarySubtitle),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(
//               context,
//             ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           const _SummaryTile(
//             titleKey: AppTextKey.medicalCriticalIndicatorTitle,
//             valueKey: AppTextKey.medicalCriticalIndicatorValue,
//             icon: Icons.monitor_heart_outlined,
//             tone: BadgeTone.critical,
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           const _SummaryTile(
//             titleKey: AppTextKey.medicalDiagnosisTitle,
//             valueKey: AppTextKey.medicalDiagnosisValue,
//             icon: Icons.medical_information_outlined,
//             tone: BadgeTone.neutral,
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           const _SummaryTile(
//             titleKey: AppTextKey.medicalTreatmentsTitle,
//             valueKey: AppTextKey.medicalTreatmentsValue,
//             icon: Icons.medication_outlined,
//             tone: BadgeTone.neutral,
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           const _SummaryTile(
//             titleKey: AppTextKey.medicalVaccinesTitle,
//             valueKey: AppTextKey.medicalVaccinesValue,
//             icon: Icons.vaccines_outlined,
//             tone: BadgeTone.neutral,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SummaryTile extends StatelessWidget {
//   const _SummaryTile({
//     required this.titleKey,
//     required this.valueKey,
//     required this.icon,
//     required this.tone,
//   });

//   final AppTextKey titleKey;
//   final AppTextKey valueKey;
//   final IconData icon;
//   final BadgeTone tone;

//   @override
//   Widget build(BuildContext context) {
//     final color = tone == BadgeTone.critical
//         ? AppColors.critical
//         : AppColors.mutedInk;

//     return Container(
//       constraints: const BoxConstraints(
//         minHeight: _MedicalOverviewLayout.summaryTileMinHeight,
//       ),
//       padding: const EdgeInsets.all(AppSpacing.md),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.06),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: color.withValues(alpha: 0.12)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 16),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(titleKey),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   context.tr(valueKey),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w800,
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

// class _MedicationCard extends StatelessWidget {
//   const _MedicationCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.medicalMedicationsTitle),
//       subtitle: context.tr(AppTextKey.medicalMedicationsSubtitle),
//       minHeight: _MedicalOverviewLayout.bottomCardMinHeight,
//       padding: EdgeInsets.zero,
//       child: Column(
//         children: const [
//           _MedicationRow(
//             nameKey: AppTextKey.medicalMedicationMetformin,
//             doseKey: AppTextKey.medicalMedicationMetforminDose,
//             statusKey: AppTextKey.medicalMedicationActive,
//           ),
//           Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
//           _MedicationRow(
//             nameKey: AppTextKey.medicalMedicationInsulin,
//             doseKey: AppTextKey.medicalMedicationInsulinDose,
//             statusKey: AppTextKey.medicalMedicationMonitoring,
//           ),
//           Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
//           _MedicationRow(
//             nameKey: AppTextKey.medicalMedicationAtorvastatin,
//             doseKey: AppTextKey.medicalMedicationAtorvastatinDose,
//             statusKey: AppTextKey.medicalMedicationActive,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MedicationRow extends StatelessWidget {
//   const _MedicationRow({
//     required this.nameKey,
//     required this.doseKey,
//     required this.statusKey,
//   });

//   final AppTextKey nameKey;
//   final AppTextKey doseKey;
//   final AppTextKey statusKey;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//       child: SizedBox(
//         height: _MedicalOverviewLayout.medicationRowHeight,
//         child: Row(
//           children: [
//             const Icon(
//               Icons.medication_liquid_outlined,
//               color: AppColors.mutedInk,
//               size: 20,
//             ),
//             const SizedBox(width: AppSpacing.md),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     context.tr(nameKey),
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   Text(
//                     context.tr(doseKey),
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//             ),
//             StatusBadge(label: context.tr(statusKey), tone: BadgeTone.neutral),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _LastVisitCard extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.medicalLastVisitTitle),
//       subtitle: context.tr(AppTextKey.medicalLastVisitSubtitle),
//       minHeight: _MedicalOverviewLayout.bottomCardMinHeight,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.medicalLastVisitDate),
//         tone: BadgeTone.neutral,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             context.tr(AppTextKey.medicalLastVisitSummary),
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w800,
//               color: AppColors.ink,
//             ),
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Text(
//             context.tr(AppTextKey.medicalLastVisitPlan),
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),
//           const SizedBox(height: AppSpacing.xl),
//           Wrap(
//             spacing: AppSpacing.sm,
//             runSpacing: AppSpacing.sm,
//             children: [
//               StatusBadge(
//                 label: context.tr(AppTextKey.medicalTagDiabetesFollowUp),
//                 tone: BadgeTone.neutral,
//               ),
//               StatusBadge(
//                 label: context.tr(AppTextKey.medicalTagAnalysisRequired),
//                 tone: BadgeTone.neutral,
//               ),
//               StatusBadge(
//                 label: context.tr(AppTextKey.medicalReadOnly),
//                 tone: BadgeTone.neutral,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
