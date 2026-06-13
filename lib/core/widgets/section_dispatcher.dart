import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/medical_record/data/models/dossier_models.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_bloc.dart';
import '../../features/medical_record/presentation/bloc/dossier/dossier_state.dart';
import 'section_helpers.dart';

class SectionDispatcher extends StatelessWidget {
  final DossierSection section;
  final Widget Function(
    BuildContext   ctx,
    DossierState   state,
    PatientSession session,
  ) builder;

  const SectionDispatcher({
    required this.section,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DossierBloc, DossierState>(
      buildWhen: (prev, next) => _shouldRebuild(prev, next),
      builder: (ctx, state) => _build(ctx, state),
    );
  }

  // ── Rebuild uniquement quand les données de CETTE section changent ─
  bool _shouldRebuild(DossierState prev, DossierState next) {
    // Toujours si session change (expiration, fermeture)
    if (next is DossierSessionExpiredState || next is DossierNoSession) return true;

    // Toujours si l'overview passe de loading à loaded/error
    final prevLoading = prev is DossierLoadingSection;
    final nextLoading = next is DossierLoadingSection;
    if (prevLoading != nextLoading) return true;

    // Overview section : déclencher sur changement d'overviewData
    if (section == DossierSection.overview) {
      return prev.overviewData != next.overviewData ||
             isSectionError(prev, section) != isSectionError(next, section);
    }

    // Autres sections : déclencher sur changement des données en cache
    final prevData = getSectionData(prev, section);
    final nextData = getSectionData(next, section);
    if (prevData != nextData) return true;

    // Déclencher sur changement d'erreur pour cette section
    if (isSectionError(prev, section) != isSectionError(next, section)) return true;

    return false;
  }

  Widget _build(BuildContext ctx, DossierState state) {
    final session = state.activeSession;
    if (session == null || session.isExpired) {
      return const SizedBox.shrink();
    }

    // ── Overview en cours de chargement ───────────────────────────
    // Toutes les sections attendent l'overview
    if (state is DossierLoadingSection) {
      return SectionLoading(
          label: 'Chargement du dossier médical...');
    }

    // ── Erreur sur l'overview → toutes les sections en erreur ─────
    if (state is DossierSectionError &&
        state.section == DossierSection.overview) {
      return SectionErrorView(
        message: state.message,
        section: DossierSection.overview,
      );
    }

    // ── Section overview ──────────────────────────────────────────
    if (section == DossierSection.overview) {
      // Erreur spécifique overview déjà gérée ci-dessus
      // Si overviewData null ici → loading encore (ne devrait pas arriver)
      if (state.overviewData == null) {
        return const SectionLoading(label: 'Chargement du résumé...');
      }
      return builder(ctx, state, session);
    }

    // ── Autres sections : erreur individuelle (après retry) ───────
    if (isSectionError(state, section)) {
      return SectionErrorView(
        message: getSectionError(state),
        section: section,
      );
    }

    // ── Chargement individuel (fallback/retry en cours) ───────────
    if (isSectionLoading(state, section)) {
      return SectionLoading(
          label: 'Chargement de ${section.label}...');
    }

    // ── Données disponibles (depuis le cache pré-peuplé) ──────────
    final data = getSectionData(state, section);
    if (data == null) {
      // Ne devrait pas arriver si overview est complet
      // Afficher chargement silencieux
      return SectionLoading(label: 'Chargement de ${section.label}...');
    }

    return builder(ctx, state, session);
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../features/medical_record/data/models/dossier_models.dart';
// import '../../features/medical_record/presentation/bloc/dossier/dossier_bloc.dart';
// import '../../features/medical_record/presentation/bloc/dossier/dossier_event.dart';
// import '../../features/medical_record/presentation/bloc/dossier/dossier_state.dart';
// import 'section_helpers.dart';

// class SectionDispatcher extends StatefulWidget {
//   final DossierSection section;
//   final Widget Function(
//     BuildContext ctx, DossierState state, PatientSession session) builder;
//   final Widget? loadingWidget;
//   final Widget? errorWidget;

//   const SectionDispatcher({
//     required this.section,
//     required this.builder,
//     this.loadingWidget,
//     this.errorWidget,
//     super.key,
//   });

//   @override
//   State<SectionDispatcher> createState() => _SectionDispatcherState();
// }

// class _SectionDispatcherState extends State<SectionDispatcher> {
//   bool _dispatched = false;

//   @override
//   void initState() {
//     super.initState();
//     // addPostFrameCallback dans initState = exécuté UNE SEULE FOIS
//     // (pas dans build/BlocBuilder.builder qui s'exécute à chaque rebuild)
//     WidgetsBinding.instance.addPostFrameCallback((_) => _tryDispatch());
//   }

//   void _tryDispatch() {
//     if (!mounted || _dispatched) return;

//     final bloc  = context.read<DossierBloc>();
//     final state = bloc.state;

//     if (!state.hasActiveSession) return;

//     // ── CAS OVERVIEW : vérifier overviewData, pas getSectionData ──
//     // getSectionData(state, overview) retourne [] dans l'état initial
//     // (currentSection = overview, sectionData = []) → non null → blocage
//     if (widget.section == DossierSection.overview) {
//       if (state.overviewData != null) {
//         debugPrint('[SectionDispatcher] Résumé: overviewData déjà chargé');
//         _dispatched = true;
//         return;
//       }
//       // Vérifier si un chargement est déjà en cours
//       if (isSectionLoading(state, DossierSection.overview)) {
//         debugPrint('[SectionDispatcher] Résumé: chargement en cours — pas de dispatch');
//         _dispatched = true;
//         return;
//       }
//       _dispatched = true;
//       debugPrint('[SectionDispatcher] dispatch Résumé');
//       bloc.add(const DossierSectionRequested(DossierSection.overview));
//       return;
//     }

//     // ── AUTRES SECTIONS : vérifier le cache ───────────────────────
//     final data = getSectionData(state, widget.section);
//     if (data != null) {
//       debugPrint('[SectionDispatcher] ${widget.section.label}: '
//           'déjà dans le cache (${data.length} éléments) — pas de dispatch');
//       _dispatched = true;
//       return;
//     }

//     // Vérifier si un chargement est déjà en cours pour cette section
//     if (isSectionLoading(state, widget.section)) {
//       debugPrint('[SectionDispatcher] ${widget.section.label}: '
//           'chargement en cours — pas de dispatch');
//       _dispatched = true;
//       return;
//     }

//     _dispatched = true;
//     debugPrint('[SectionDispatcher] dispatch ${widget.section.label}');
//     bloc.add(DossierSectionRequested(widget.section));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<DossierBloc, DossierState>(
//       buildWhen: (prev, next) {
//         // Pas de session → toujours rebuilder
//         if (next is DossierSessionExpiredState ||
//             next is DossierNoSession) return true;

//         // ── CAS OVERVIEW ──────────────────────────────────────────
//         if (widget.section == DossierSection.overview) {
//           // Rebuilder quand overviewData change (chargé ou effacé)
//           if (prev.overviewData != next.overviewData) return true;
//           // Rebuilder pour loading/error de overview
//           if (isSectionLoading(prev, DossierSection.overview) !=
//               isSectionLoading(next, DossierSection.overview)) return true;
//           if (isSectionError(prev, DossierSection.overview) !=
//               isSectionError(next, DossierSection.overview)) return true;
//           return false;
//         }

//         // ── AUTRES SECTIONS ───────────────────────────────────────
//         final prevData = getSectionData(prev, widget.section);
//         final nextData = getSectionData(next, widget.section);
//         if (prevData != nextData) return true;
//         if (isSectionLoading(prev, widget.section) !=
//             isSectionLoading(next, widget.section)) return true;
//         if (isSectionError(prev, widget.section) !=
//             isSectionError(next, widget.section)) return true;
//         return false;
//       },
//       builder: (ctx, state) {
//         final session = state.activeSession;
//         if (session == null || session.isExpired) {
//           return const SizedBox.shrink();
//         }

//         // ── Chargement ────────────────────────────────────────────
//         if (isSectionLoading(state, widget.section)) {
//           return widget.loadingWidget ??
//               SectionLoading(
//                   label: 'Chargement de ${widget.section.label}...');
//         }

//         // ── Erreur ────────────────────────────────────────────────
//         if (isSectionError(state, widget.section)) {
//           return widget.errorWidget ??
//               SectionErrorView(
//                   message: getSectionError(state),
//                   section: widget.section);
//         }

//         // ── CAS OVERVIEW : données dans overviewData ──────────────
//         if (widget.section == DossierSection.overview) {
//           if (state.overviewData == null) {
//             // Pas encore chargé — afficher loading
//             return widget.loadingWidget ??
//                 const SectionLoading(label: 'Chargement du résumé médical...');
//           }
//           return widget.builder(ctx, state, session);
//         }

//         // ── AUTRES SECTIONS : données dans cache ou sectionData ───
//         final data = getSectionData(state, widget.section);
//         if (data == null) {
//           // Pas encore chargé — afficher loading
//           return widget.loadingWidget ??
//               SectionLoading(
//                   label: 'Chargement de ${widget.section.label}...');
//         }
//         return widget.builder(ctx, state, session);
//       },
//     );
//   }
// }