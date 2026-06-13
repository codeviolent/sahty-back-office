// lib/features/medical_record/presentation/widgets/section_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../features/medical_record/data/models/dossier_models.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_bloc.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_event.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_state.dart';

// ── section en cours de chargement ───────────────────────────────
bool isSectionLoading(DossierState state, DossierSection section) =>
    state is DossierLoadingSection && state.section == section;

// ── section en erreur ─────────────────────────────────────────────
bool isSectionError(DossierState state, DossierSection section) =>
    state is DossierSectionError && state.section == section;

// ── message d'erreur ──────────────────────────────────────────────
String getSectionError(DossierState state) =>
    state is DossierSectionError ? state.message : 'Erreur inconnue';

// ── données List d'une section (toutes sauf overview) ─────────────
List<dynamic>? getSectionData(DossierState state, DossierSection section) {
  if (state is DossierSectionLoaded) {
    if (state.cache.containsKey(section)) return state.cache[section];
    if (state.currentSection == section) return state.sectionData;
  }
  return null;
}

// ── données overview — lit depuis n'importe quel état ─────────────
// L'overviewData est préservé dans DossierState.overviewData
PatientOverviewData? getOverviewData(DossierState state) => state.overviewData;

// ══════════════════════════════════════════════════════════════════
// Widgets
// ══════════════════════════════════════════════════════════════════

class SectionLoading extends StatelessWidget {
  final String? label;
  const SectionLoading({this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                label!,
                style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionErrorView extends StatelessWidget {
  final String message;
  final DossierSection section;
  const SectionErrorView({
    required this.message,
    required this.section,
    super.key,
  });

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
              size: 48,
              color: AppColors.mutedInk,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.read<DossierBloc>().add(
                DossierSectionRequested(section),
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

class SectionEmpty extends StatelessWidget {
  final String label;
  const SectionEmpty({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.mutedInk,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun(e) $label enregistré(e)',
              style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
