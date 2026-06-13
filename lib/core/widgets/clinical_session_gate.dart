import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/medical_record/presentation/bloc/dossier/dossier_bloc.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_event.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/medical_record/data/models/dossier_models.dart';

/// Gate appliqué sur chaque screen du dossier clinique.
/// Gère 3 cas :
///   1. Pas de session        → _NoSessionPlaceholder
///   2. Session expirée       → _ExpiredBanner puis NoSession
///   3. Session active        → BandeauPatient + contenu du screen
class ClinicalSessionGate extends StatelessWidget {
  /// Le contenu du screen — reçoit la session active
  final Widget Function(PatientSession session)
  builder;

  const ClinicalSessionGate({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DossierBloc, DossierState>(
      // listener : gérer les transitions d'état (expiration, fermeture)
      listener: (ctx, state) {
        if (state is DossierSessionExpiredState) {
          // Afficher un snackbar d'expiration
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer_off_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Session expirée — dossier fermé automatiquement'),
                ],
              ),
              backgroundColor: AppColors.critical,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (ctx, state) {
        // ── Expiration en cours ──────────────────────────────
        if (state is DossierSessionExpiredState) {
          return const _ExpiredBanner();
        }

        // ── Pas de session ───────────────────────────────────
        if (state is DossierNoSession) {
          return const _NoSessionPlaceholder();
        }

        // ── Session active ────────────────────────────────────
        final session = state.activeSession;
        if (session == null || session.isExpired) {
          return const _NoSessionPlaceholder();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau permanent avec info patient + countdown
              _PatientBanner(session: session),
              const SizedBox(height: AppSpacing.lg),
              builder(session)
            ],
          ),
        );
      },
    );
  }
}

// ── Bandeau patient ────────────────────────────────────────────────
class _PatientBanner extends StatelessWidget {
  final PatientSession session;
  const _PatientBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final isWarning = session.isWarning;
    final accentColor = isWarning ? AppColors.critical : AppColors.normal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar initiales
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                session.initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Infos patient
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  [
                    'GS: ${session.bloodType}',
                    if (session.criticalAllergies.isNotEmpty)
                      'Allergie: ${session.criticalAllergies.map((a) => a.allergen).join(", ")}',
                    session.durationLabel,
                  ].join('  ·  '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),

          // Countdown
          _CountdownBadge(session: session),
          const SizedBox(width: AppSpacing.sm),

          // Bouton fermer
          Tooltip(
            message: 'Fermer la session',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  context.read<DossierBloc>().add(DossierSessionClosed()),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.critical.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.critical.withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.critical,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge countdown ────────────────────────────────────────────────
class _CountdownBadge extends StatelessWidget {
  final PatientSession session;
  const _CountdownBadge({required this.session});

  @override
  Widget build(BuildContext context) {
    final isWarning = session.isWarning;
    final color = isWarning ? AppColors.critical : AppColors.normal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.timer_outlined : Icons.lock_clock_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            session.remainingLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder "Aucun dossier ouvert" ────────────────────────────
class _NoSessionPlaceholder extends StatelessWidget {
  const _NoSessionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.folder_off_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              const Text(
                'Aucun dossier ouvert',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              const Text(
                'Pour consulter les données cliniques d\'un patient, '
                'ouvrez une session via la page "Accès Patient".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedInk,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Étapes
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _StepRow(
                      number: '1',
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scanner le QR Code sur le téléphone du patient',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _StepRow(
                      number: '2',
                      icon: Icons.pin_outlined,
                      label: 'Saisir le PIN à 4 chiffres du patient',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _StepRow(
                      number: '3',
                      icon: Icons.schedule_outlined,
                      label: 'Session active pendant 30 minutes',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _StepRow(
                      number: '4',
                      icon: Icons.notifications_outlined,
                      label: 'Le patient est notifié de chaque accès',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final IconData icon;
  final String label;
  const _StepRow({
    required this.number,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(icon, size: 16, color: AppColors.mutedInk),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedInk),
          ),
        ),
      ],
    );
  }
}

// ── Banner expiration ──────────────────────────────────────────────
class _ExpiredBanner extends StatelessWidget {
  const _ExpiredBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_off_outlined,
              size: 64,
              color: AppColors.critical,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Session expirée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.critical,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'La session de 30 minutes est terminée. '
              'Le dossier a été fermé automatiquement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedInk, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading section ────────────────────────────────────────────────
class _SectionLoadingIndicator extends StatelessWidget {
  const _SectionLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

// ── Erreur section ─────────────────────────────────────────────────
class _SectionErrorView extends StatelessWidget {
  final DossierSectionError state;
  const _SectionErrorView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.mutedInk,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              state.message,
              style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.read<DossierBloc>().add(
                DossierSectionRequested(state.section),
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
