// lib/features/patients/presentation/screens/patient_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/datasource/patient_search_datasource.dart';
import '../../data/models/patient_search_models.dart';
import '../bloc/patient_search_bloc.dart';
import '../bloc/patient_search_event.dart';
import '../bloc/patient_search_state.dart';

// Layout — inchangé
abstract final class _PatientSearchLayout {
  static const double controlCardMinHeight = 188;
  static const double resultsCardMinHeight = 260;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

// ── Screen ─────────────────────────────────────────────────────────
class PatientSearchScreen extends StatelessWidget {
  const PatientSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PatientSearchBloc(const PatientSearchDatasource())
            ..add(PatientSearchLoadRequested()),
      child: const _PatientSearchView(),
    );
  }
}

class _PatientSearchView extends StatelessWidget {
  const _PatientSearchView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SearchControlCard(),
        SizedBox(height: AppSpacing.xl),
        _ResultsCard(),
      ],
    );
  }
}

// ── Card recherche — câblée au BLoC ───────────────────────────────
class _SearchControlCard extends StatefulWidget {
  const _SearchControlCard();
  @override
  State<_SearchControlCard> createState() => _SearchControlCardState();
}

class _SearchControlCardState extends State<_SearchControlCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientSearchBloc, PatientSearchBlocState>(
      builder: (ctx, state) {
        final count = state is PatientSearchLoaded
            ? state.displayed.length
            : null;

        return SectionCard(
          title: context.tr(AppTextKey.patientSearchCardTitle),
          subtitle: context.tr(AppTextKey.patientSearchCardSubtitle),
          minHeight: _PatientSearchLayout.controlCardMinHeight,
          trailing: count != null
              ? StatusBadge(label: '$count patient(s)', tone: BadgeTone.info)
              : StatusBadge(
                  label: context.tr(AppTextKey.patientSearchReadOnlyPreview),
                  tone: BadgeTone.neutral,
                  icon: Icons.visibility_outlined,
                ),
          child: Column(
            children: [
              // ── Champ de recherche câblé ──────────────────────
              TextField(
                controller: _ctrl,
                onChanged: (v) => ctx.read<PatientSearchBloc>().add(
                  PatientSearchQueryChanged(v),
                ),
                decoration: InputDecoration(
                  hintText: context.tr(AppTextKey.patientSearchHint),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _ctrl.clear();
                            ctx.read<PatientSearchBloc>().add(
                              PatientSearchQueryChanged(''),
                            );
                          },
                        )
                      : IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.tune_rounded, size: 18),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Filtres rapides — inchangés ────────────────────
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _FilterChip(
                    labelKey: AppTextKey.patientSearchFilterAge,
                    icon: Icons.cake_outlined,
                  ),
                  _FilterChip(
                    labelKey: AppTextKey.patientSearchFilterSex,
                    icon: Icons.wc_outlined,
                  ),
                  _FilterChip(
                    labelKey: AppTextKey.patientSearchFilterLastVisit,
                    icon: Icons.history,
                  ),
                  _FilterChip(
                    labelKey: AppTextKey.patientSearchFilterDoctor,
                    icon: Icons.badge,
                  ),
                  _FilterChip(
                    labelKey: AppTextKey.patientSearchFilterActiveSession,
                    icon: Icons.lock_clock,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── _FilterChip — inchangé ─────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.labelKey, required this.icon});
  final AppTextKey labelKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: context.tr(labelKey),
      tone: BadgeTone.neutral,
      icon: icon,
    );
  }
}

// ── Card résultats dynamique ───────────────────────────────────────
class _ResultsCard extends StatelessWidget {
  const _ResultsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientSearchBloc, PatientSearchBlocState>(
      builder: (ctx, state) => switch (state) {
        PatientSearchLoading() => const _ResultsLoading(),
        PatientSearchError() => _ResultsError(
          message: state.message,
          onRetry: () =>
              ctx.read<PatientSearchBloc>().add(PatientSearchLoadRequested()),
        ),
        PatientSearchLoaded() => _ResultsTable(
          patients: state.displayed,
          query: state.query,
        ),
        _ => const _ResultsLoading(),
      },
    );
  }
}

class _ResultsTable extends StatelessWidget {
  final List<PatientSearchResult> patients;
  final String query;
  const _ResultsTable({required this.patients, required this.query});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.patientSearchResultsTitle),
      subtitle: context.tr(AppTextKey.patientSearchResultsSubtitle),
      minHeight: _PatientSearchLayout.resultsCardMinHeight,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ── En-têtes colonnes — structure inchangée ────────────
          const _TableHeader(
            columns: [
              AppTextKey.patientSearchColumnPatient,
              AppTextKey.patientSearchColumnRecordNni,
              AppTextKey.patientSearchColumnAge,
              AppTextKey.patientSearchColumnLastVisit,
              AppTextKey.patientSearchColumnAccess,
            ],
            flexes: [3, 3, 1, 2, 2],
          ),

          // ── Pas de résultats ───────────────────────────────────
          if (patients.isEmpty)
            _EmptyResults(query: query)
          else
            for (int i = 0; i < patients.length; i++) ...[
              _PatientRow(patient: patients[i]),
              if (i < patients.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
        ],
      ),
    );
  }
}

// ── Ligne patient — données réelles ───────────────────────────────
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});
  final PatientSearchResult patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _PatientSearchLayout.rowHeight,
        child: Row(
          children: [
            // ── Nom avec avatar ─────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // Petit avatar avec initiales
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        patient.initials,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      patient.fullName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── NNI masqué ──────────────────────────────────────
            Expanded(
              flex: 3,
              child: Text(
                patient.nniMasked,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Âge ─────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Text(
                patient.age != null
                    ? '${patient.age} ${context.tr(AppTextKey.patientSearchAgeSuffix)}'
                    : '—',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            // ── Dernière visite dynamique ────────────────────────
            Expanded(
              flex: 2,
              child: Text(
                patient.lastVisitLabel, // ← DYNAMIQUE
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Badge statut accès ───────────────────────────────
            Expanded(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: StatusBadge(
                  label: patient.accessStatus.label, // ← DYNAMIQUE
                  tone: patient.accessStatus.tone, // ← DYNAMIQUE
                  icon: switch (patient.accessStatus) {
                    PatientAccessStatus.activeSession =>
                      Icons.lock_open_outlined,
                    PatientAccessStatus.needsReason => Icons.qr_code_outlined,
                    PatientAccessStatus.restricted => Icons.lock_outlined,
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _TableHeader — inchangé ────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns, required this.flexes});
  final List<AppTextKey> columns;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _PatientSearchLayout.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.65),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < columns.length; i++)
            Expanded(
              flex: flexes[i],
              child: Text(
                context.tr(columns[i]).toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ── États ──────────────────────────────────────────────────────────
class _ResultsLoading extends StatelessWidget {
  const _ResultsLoading();
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.patientSearchResultsTitle),
      minHeight: _PatientSearchLayout.resultsCardMinHeight,
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.sm,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
            ),
            child: Container(
              height: _PatientSearchLayout.rowHeight,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.mutedInk,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              query.isNotEmpty
                  ? 'Aucun patient pour "$query"'
                  : 'Aucun patient trouvé',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ResultsError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.patientSearchResultsTitle),
      minHeight: _PatientSearchLayout.resultsCardMinHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.mutedInk,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Réessayer'),
            ),
          ],
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
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';

// enum _AccessStatus { activeSession, needsReason, restricted }

// abstract final class _PatientSearchLayout {
//   static const double controlCardMinHeight = 188;
//   static const double resultsCardMinHeight = 260;
//   static const double rowHeight = 46;
//   static const double headerHeight = 38;
// }

// class _PatientResult {
//   const _PatientResult({
//     required this.nameKey,
//     required this.fileNo,
//     required this.maskedNni,
//     required this.age,
//     required this.lastVisitKey,
//     required this.status,
//   });

//   final AppTextKey nameKey;
//   final String fileNo;
//   final String maskedNni;
//   final int age;
//   final AppTextKey lastVisitKey;
//   final _AccessStatus status;
// }

// abstract final class _PatientSearchMock {
//   static const results = [
//     _PatientResult(
//       nameKey: AppTextKey.patientSearchPatientFatima,
//       fileNo: 'MR-2048',
//       maskedNni: '**** **** 4821',
//       age: 56,
//       lastVisitKey: AppTextKey.patientSearchVisitApr13,
//       status: _AccessStatus.needsReason,
//     ),
//     _PatientResult(
//       nameKey: AppTextKey.patientSearchPatientAli,
//       fileNo: 'MR-1182',
//       maskedNni: '**** **** 9134',
//       age: 44,
//       lastVisitKey: AppTextKey.patientSearchVisitApr11,
//       status: _AccessStatus.activeSession,
//     ),
//     _PatientResult(
//       nameKey: AppTextKey.patientSearchPatientMariam,
//       fileNo: 'MR-0931',
//       maskedNni: '**** **** 2049',
//       age: 63,
//       lastVisitKey: AppTextKey.patientSearchVisitApr08,
//       status: _AccessStatus.restricted,
//     ),
//   ];
// }

// class PatientSearchScreen extends StatelessWidget {
//   const PatientSearchScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(  
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _SearchControlCard(),
//         const SizedBox(height: AppSpacing.xl),
//         _ResultsCard(results: _PatientSearchMock.results),
//       ],
//     );
//   }
// }

// class _SearchControlCard extends StatelessWidget {
//   const _SearchControlCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.patientSearchCardTitle),
//       subtitle: context.tr(AppTextKey.patientSearchCardSubtitle),
//       minHeight: _PatientSearchLayout.controlCardMinHeight,
//       trailing: StatusBadge(
//         label: context.tr(AppTextKey.patientSearchReadOnlyPreview),
//         tone: BadgeTone.neutral,
//         icon: Icons.visibility_outlined,
//       ),
//       child: Column(
//         children: [
//           TextField(
//             decoration: InputDecoration(
//               hintText: context.tr(AppTextKey.patientSearchHint),
//               prefixIcon: const Icon(Icons.search_rounded),
//               suffixIcon: IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.tune_rounded, size: 18),
//               ),
//             ),
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           Wrap(
//             spacing: AppSpacing.sm,
//             runSpacing: AppSpacing.sm,
//             children: const [
//               _FilterChip(
//                 labelKey: AppTextKey.patientSearchFilterAge,
//                 icon: Icons.cake_outlined,
//               ),
//               _FilterChip(
//                 labelKey: AppTextKey.patientSearchFilterSex,
//                 icon: Icons.wc_outlined,
//               ),
//               _FilterChip(
//                 labelKey: AppTextKey.patientSearchFilterLastVisit,
//                 icon: Icons.history,
//               ),
//               _FilterChip(
//                 labelKey: AppTextKey.patientSearchFilterDoctor,
//                 icon: Icons.badge,
//               ),
//               _FilterChip(
//                 labelKey: AppTextKey.patientSearchFilterActiveSession,
//                 icon: Icons.lock_clock,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _FilterChip extends StatelessWidget {
//   const _FilterChip({required this.labelKey, required this.icon});

//   final AppTextKey labelKey;
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return StatusBadge(
//       label: context.tr(labelKey),
//       tone: BadgeTone.neutral,
//       icon: icon,
//     );
//   }
// }

// class _ResultsCard extends StatelessWidget {
//   const _ResultsCard({required this.results});

//   final List<_PatientResult> results;

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.patientSearchResultsTitle),
//       subtitle: context.tr(AppTextKey.patientSearchResultsSubtitle),
//       minHeight: _PatientSearchLayout.resultsCardMinHeight,
//       padding: EdgeInsets.zero,
//       child: Column(
//         children: [
//           const _TableHeader(
//             columns: [
//               AppTextKey.patientSearchColumnPatient,
//               AppTextKey.patientSearchColumnRecordNni,
//               AppTextKey.patientSearchColumnAge,
//               AppTextKey.patientSearchColumnLastVisit,
//               AppTextKey.patientSearchColumnAccess,
//             ],
//             flexes: [3, 3, 1, 2, 2],
//           ),
//           for (int i = 0; i < results.length; i++) ...[
//             _PatientRow(patient: results[i]),
//             if (i < results.length - 1)
//               const Divider(
//                 height: 1,
//                 thickness: 0.5,
//                 indent: 16,
//                 endIndent: 16,
//               ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _PatientRow extends StatelessWidget {
//   const _PatientRow({required this.patient});

//   final _PatientResult patient;

//   @override
//   Widget build(BuildContext context) {
//     final (labelKey, tone) = switch (patient.status) {
//       _AccessStatus.activeSession => (
//         AppTextKey.patientSearchStatusOpen,
//         BadgeTone.neutral,
//       ),
//       _AccessStatus.needsReason => (
//         AppTextKey.patientSearchStatusReason,
//         BadgeTone.neutral,
//       ),
//       _AccessStatus.restricted => (
//         AppTextKey.patientSearchStatusRestricted,
//         BadgeTone.critical,
//       ),
//     };

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//       child: SizedBox(
//         height: _PatientSearchLayout.rowHeight,
//         child: Row(
//           children: [
//             Expanded(
//               flex: 3,
//               child: Text(
//                 context.tr(patient.nameKey),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.ink,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Expanded(
//               flex: 3,
//               child: Text(
//                 '${patient.fileNo}  ·  ${patient.maskedNni}',
//                 style: Theme.of(context).textTheme.bodySmall,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Expanded(
//               flex: 1,
//               child: Text(
//                 '${patient.age} ${context.tr(AppTextKey.patientSearchAgeSuffix)}',
//               ),
//             ),
//             Expanded(
//               flex: 2,
//               child: Text(
//                 context.tr(patient.lastVisitKey),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Expanded(
//               flex: 2,
//               child: Align(
//                 alignment: AlignmentDirectional.centerEnd,
//                 child: StatusBadge(label: context.tr(labelKey), tone: tone),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TableHeader extends StatelessWidget {
//   const _TableHeader({required this.columns, required this.flexes});

//   final List<AppTextKey> columns;
//   final List<int> flexes;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: _PatientSearchLayout.headerHeight,
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//       decoration: BoxDecoration(
//         color: AppColors.canvas.withValues(alpha: 0.65),
//         border: const Border(
//           bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
//         ),
//       ),
//       child: Row(
//         children: [
//           for (int i = 0; i < columns.length; i++)
//             Expanded(
//               flex: flexes[i],
//               child: Text(
//                 context.tr(columns[i]).toUpperCase(),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: AppColors.mutedInk,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 10,
//                   letterSpacing: 0.6,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
