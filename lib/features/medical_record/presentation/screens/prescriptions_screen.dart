// lib/features/medical_record/presentation/screens/prescriptions_screen.dart

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

abstract final class _PrescriptionsLayout {
  static const double tableMinHeight = 260;
  static const double actionMinHeight = 188;
  static const double rowHeight = 46;
  static const double headerHeight = 38;
}

// ══════════════════════════════════════════════════════════════════
// Screen — StatelessWidget pur
// ══════════════════════════════════════════════════════════════════
class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClinicalSessionGate(
      builder: (session) => _PrescriptionsBlocView(session: session),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Vue BLoC — dispatch via addPostFrameCallback
// ══════════════════════════════════════════════════════════════════
class _PrescriptionsBlocView extends StatelessWidget {
  final PatientSession session;
  const _PrescriptionsBlocView({required this.session});
  @override
  Widget build(BuildContext context) {
    return SectionDispatcher(
      section: DossierSection.prescriptions,
      builder: (ctx, state, session) {
       final raw   = getSectionData(state, DossierSection.prescriptions) ?? [];
       final items = raw.map((e) =>
          PrescriptionItem.fromJson(e as Map<String, dynamic>)).toList();
        return _PrescriptionsContent(session: session, items: items);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Contenu — données réelles
// ══════════════════════════════════════════════════════════════════
class _PrescriptionsContent extends StatelessWidget {
  final PatientSession session;
  final List<PrescriptionItem> items;
  const _PrescriptionsContent({required this.session, required this.items});

  @override
  Widget build(BuildContext context) {
    final active = items.where((i) => i.status == 'active').toList();
    final completed = items
        .where((i) => i.status == 'completed' || i.status == 'cancelled')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Alerte allergies critiques de la session ───────────────
        if (session.criticalAllergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Container(
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
                    Icons.warning_amber_rounded,
                    color: AppColors.critical,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Vérifier interactions avec allergies : '
                      '${session.criticalAllergies.map((a) => a.allergen).join(", ")}',
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
          ),

        // ── Ordonnances actives ────────────────────────────────────
        SectionCard(
          title: context.tr(AppTextKey.prescriptionsListTitle),
          subtitle: context.tr(AppTextKey.prescriptionsListSubtitle),
          minHeight: _PrescriptionsLayout.tableMinHeight,
          padding: EdgeInsets.zero,
          trailing: active.isNotEmpty
              ? StatusBadge(
                  label: '${active.length} active(s)',
                  tone: BadgeTone.normal,
                  icon: Icons.medication_outlined,
                )
              : null,
          child: active.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: SectionEmpty(label: 'ordonnance active'),
                )
              : Column(
                  children: [
                    const _PrescriptionHeader(),
                    ...active.asMap().entries.map(
                      (e) => Column(
                        children: [
                          _PrescriptionRow(data: e.value),
                          if (e.key < active.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: AppSpacing.lg,
                              endIndent: AppSpacing.lg,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // ── Ordonnances terminées / annulées ───────────────────────
        if (completed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Terminées / Annulées (${completed.length})',
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _PrescriptionHeader(muted: true),
                ...completed.asMap().entries.map(
                  (e) => Column(
                    children: [
                      _PrescriptionRow(data: e.value, muted: true),
                      if (e.key < completed.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Actions + Politique ────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionCard(
                title: context.tr(AppTextKey.prescriptionsActionsTitle),
                subtitle: context.tr(AppTextKey.prescriptionsActionsSubtitle),
                minHeight: _PrescriptionsLayout.actionMinHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.mutedInk,
                              foregroundColor: AppColors.surface,
                            ),
                            onPressed: () => _confirmExport(context, () {}),
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: Text(
                              context.tr(AppTextKey.prescriptionsPrint),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.mutedInk,
                              side: const BorderSide(
                                color: AppColors.borderSoft,
                              ),
                            ),
                            onPressed: () => _confirmExport(context, () {}),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                            label: Text(
                              context.tr(AppTextKey.prescriptionsPdf),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(context.tr(AppTextKey.prescriptionsReadOnlyPolicy)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: SectionCard(
                title: context.tr(AppTextKey.prescriptionsInteractionTitle),
                minHeight: _PrescriptionsLayout.actionMinHeight,
                child: Text(
                  context.tr(AppTextKey.prescriptionsInteractionBody),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── En-tête de la table ────────────────────────────────────────────
class _PrescriptionHeader extends StatelessWidget {
  final bool muted;
  const _PrescriptionHeader({this.muted = false});

  @override
  Widget build(BuildContext context) {
    const columns = [
      AppTextKey.prescriptionsColumnMedication,
      AppTextKey.prescriptionsColumnDose,
      AppTextKey.prescriptionsColumnFrequency,
      AppTextKey.prescriptionsColumnDuration,
      AppTextKey.prescriptionsColumnStatus,
    ];
    return Container(
      height: _PrescriptionsLayout.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.65),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
        ),
      ),
      child: Row(
        children: columns
            .map(
              (k) => Expanded(
                child: Text(
                  context.tr(k).toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Ligne de la table — données réelles ───────────────────────────
class _PrescriptionRow extends StatelessWidget {
  final PrescriptionItem data;
  final bool muted;
  const _PrescriptionRow({required this.data, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusTone) = switch (data.status) {
      'active' => (
        context.tr(AppTextKey.prescriptionsStatusActive),
        BadgeTone.neutral,
      ),
      'completed' => (
        context.tr(AppTextKey.prescriptionsStatusCompleted),
        BadgeTone.neutral,
      ),
      _ => ('Annulé', BadgeTone.critical),
    };

    // Durée = start_date → end_date ou "En cours"
    // final duration = data.endDate.isNotEmpty
    //     ? '${_formatDate(data.startDate)} → ${_formatDate(data.endDate)}'
    //     : context.tr(AppTextKey.prescriptionsDurationOngoing);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SizedBox(
        height: _PrescriptionsLayout.rowHeight,
        child: Row(
          children: [
            // Médicament
            Expanded(
              child: Text(
                data.medicationName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted ? AppColors.mutedInk : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Dosage
            Expanded(
              child: Text(
                data.dosage.isNotEmpty ? data.dosage : '—',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Fréquence
            Expanded(
              child: Text(
                data.frequency.isNotEmpty ? data.frequency : '—',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Durée
            Expanded(
              child: Text(
                '${data.startDate.year}-${data.startDate.month.toString().padLeft(2, '0')}-${data.startDate.day.toString().padLeft(2, '0')} - ',
                //                 '${data.endDate.year}-${data.endDate.month.toString().padLeft(2, '0')}-${data.endDate.day.toString().padLeft(2, '0')}',,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Statut
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(label: statusLabel, tone: statusTone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Confirmation export ────────────────────────────────────────────
void _confirmExport(BuildContext context, VoidCallback onConfirm) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr(AppTextKey.prescriptionsConfirmExportTitle)),
      content: Text(ctx.tr(AppTextKey.prescriptionsConfirmExportBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.tr(AppTextKey.prescriptionsCancelAction)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.mutedInk),
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: Text(ctx.tr(AppTextKey.prescriptionsConfirmAction)),
        ),
      ],
    ),
  );
}

// import 'package:flutter/material.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/clinical_alert_banner.dart';
// import '../../../../core/widgets/clinical_session_gate.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';
// import '../../data/models/dossier_models.dart';
// import '../bloc/dossier/dossier_bloc.dart';

// abstract final class _PrescriptionsLayout {
//   static const double tableMinHeight = 260;
//   static const double actionCardMinHeight = 188;
//   static const double rowHeight = 46;
//   static const double headerHeight = 38;
// }

// class PrescriptionsScreen extends StatelessWidget {
//   const PrescriptionsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ClinicalSessionGate(
//       builder: (s) => _PrescriptionsContent(session: s),
//     );
//   }
// }

// class _PrescriptionsContent extends StatelessWidget {
//   final PatientSession session;
//   const _PrescriptionsContent({required this.session});

//   @override
//   Widget build(BuildContext context) {
//     final PatientOverviewData data;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ClinicalAlertBanner(
//           title: context.tr(AppTextKey.prescriptionsWarningTitle),
//           message: context.tr(AppTextKey.prescriptionsWarningMessage),
//           isCritical: true,
//         ),
//         const SizedBox(height: AppSpacing.xl),
//         _PrescriptionTable(
//           data: session,
//           prescriptions: session.activePrescriptions,
//         ),
//         const SizedBox(height: AppSpacing.xl),
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(child: _PrescriptionActionsCard()),
//             SizedBox(width: AppSpacing.xl),
//             Expanded(child: _InteractionPolicyCard()),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _PrescriptionData {
//   const _PrescriptionData({
//     required this.medicationKey,
//     required this.doseKey,
//     required this.frequencyKey,
//     required this.durationKey,
//     required this.statusKey,
//   });

//   final String medicationKey;
//   final String doseKey;
//   final String frequencyKey;
//   final String durationKey;
//   final String statusKey;
// }

// class _PrescriptionTable extends StatelessWidget {
//   final PatientSession data;
//   final List<PrescriptionItem> prescriptions;
//   const _PrescriptionTable({required this.data, required this.prescriptions});

//   // static const _items = [
//   //   // _PrescriptionData(
//   //   //   medicationKey: AppTextKey.prescriptionsMedicationMetformin,
//   //   //   doseKey: AppTextKey.prescriptionsDoseMetformin,
//   //   //   frequencyKey: AppTextKey.prescriptionsFrequencyTwice,
//   //   //   durationKey: AppTextKey.prescriptionsDurationOngoing,
//   //   //   statusKey: AppTextKey.prescriptionsStatusActive,
//   //   // ),
//   //   // _PrescriptionData(
//   //   //   medicationKey: AppTextKey.prescriptionsMedicationInsulin,
//   //   //   doseKey: AppTextKey.prescriptionsDoseInsulin,
//   //   //   frequencyKey: AppTextKey.prescriptionsFrequencyEvening,
//   //   //   durationKey: AppTextKey.prescriptionsDurationOngoing,
//   //   //   statusKey: AppTextKey.prescriptionsStatusMonitoring,
//   //   // ),
//   //   // _PrescriptionData(
//   //   //   medicationKey: AppTextKey.prescriptionsMedicationAtorvastatin,
//   //   //   doseKey: AppTextKey.prescriptionsDoseAtorvastatin,
//   //   //   frequencyKey: AppTextKey.prescriptionsFrequencyEvening,
//   //   //   durationKey: AppTextKey.prescriptionsDurationOngoing,
//   //   //   statusKey: AppTextKey.prescriptionsStatusCompleted,
//   //   // ),
//   // ];

//   @override
//   Widget build(BuildContext context) {
//     final activePrescriptions = prescriptions
//         .map(
//           (p) => _PrescriptionData(
//             medicationKey: p.medicationName,
//             doseKey: p.dosage,
//             frequencyKey: p.frequency,
//             durationKey:
//                 '${p.startDate.year}-${p.startDate.month.toString().padLeft(2, '0')}-${p.startDate.day.toString().padLeft(2, '0')} - '
//                 '${p.endDate.year}-${p.endDate.month.toString().padLeft(2, '0')}-${p.endDate.day.toString().padLeft(2, '0')}',
//             statusKey: p.status,
//           ),
//         )
//         .toList();
//     return SectionCard(
//       title: context.tr(AppTextKey.prescriptionsListTitle),
//       subtitle: context.tr(AppTextKey.prescriptionsListSubtitle),
//       minHeight: _PrescriptionsLayout.tableMinHeight,
//       padding: EdgeInsets.zero,
//       child: Column(
//         children: [
//           const _PrescriptionHeader(),
//           for (int i = 0; i < activePrescriptions.length; i++) ...[
//             _PrescriptionRow(data: activePrescriptions[i]),
//             if (i < activePrescriptions.length - 1)
//               const Divider(
//                 height: 1,
//                 thickness: 0.5,
//                 indent: AppSpacing.lg,
//                 endIndent: AppSpacing.lg,
//               ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _PrescriptionHeader extends StatelessWidget {
//   const _PrescriptionHeader();

//   @override
//   Widget build(BuildContext context) {
//     const columns = [
//       AppTextKey.prescriptionsColumnMedication,
//       AppTextKey.prescriptionsColumnDose,
//       AppTextKey.prescriptionsColumnFrequency,
//       AppTextKey.prescriptionsColumnDuration,
//       AppTextKey.prescriptionsColumnStatus,
//     ];

//     return Container(
//       height: _PrescriptionsLayout.headerHeight,
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//       decoration: BoxDecoration(
//         color: AppColors.canvas.withValues(alpha: 0.65),
//         border: const Border(
//           bottom: BorderSide(color: AppColors.borderFaint, width: 0.5),
//         ),
//       ),
//       child: Row(
//         children: [
//           for (final column in columns)
//             Expanded(
//               child: Text(
//                 context.tr(column).toUpperCase(),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: AppColors.mutedInk,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.6,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _PrescriptionRow extends StatelessWidget {
//   const _PrescriptionRow({required this.data});

//   final _PrescriptionData data;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//       child: SizedBox(
//         height: _PrescriptionsLayout.rowHeight,
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 data.medicationKey,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: AppColors.ink,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//             Expanded(child: Text(data.doseKey)),
//             Expanded(child: Text(data.frequencyKey)),
//             Expanded(child: Text(data.durationKey)),
//             Expanded(
//               child: Align(
//                 alignment: AlignmentDirectional.centerStart,
//                 child: StatusBadge(
//                   label: data.statusKey,
//                   tone: BadgeTone.neutral,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PrescriptionActionsCard extends StatelessWidget {
//   const _PrescriptionActionsCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.prescriptionsActionsTitle),
//       subtitle: context.tr(AppTextKey.prescriptionsActionsSubtitle),
//       minHeight: _PrescriptionsLayout.actionCardMinHeight,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: FilledButton.icon(
//                   style: FilledButton.styleFrom(
//                     backgroundColor: AppColors.mutedInk,
//                     foregroundColor: AppColors.surface,
//                   ),
//                   onPressed: () => _confirmExport(
//                     context,
//                     onConfirm: () {
//                       // Mock: in production this calls the print API
//                     },
//                   ),
//                   icon: const Icon(Icons.print_outlined, size: 18),
//                   label: Text(context.tr(AppTextKey.prescriptionsPrint)),
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               Expanded(
//                 child: OutlinedButton.icon(
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColors.mutedInk,
//                     side: const BorderSide(color: AppColors.borderSoft),
//                   ),
//                   onPressed: () => _confirmExport(
//                     context,
//                     onConfirm: () {
//                       // Mock: in production this calls the PDF generation API
//                     },
//                   ),
//                   icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
//                   label: Text(context.tr(AppTextKey.prescriptionsPdf)),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           Text(context.tr(AppTextKey.prescriptionsReadOnlyPolicy)),
//         ],
//       ),
//     );
//   }
// }

// /// Shows a confirmation dialog before any medical data export/print — spec §6 requirement.
// void _confirmExport(BuildContext context, {required VoidCallback onConfirm}) {
//   showDialog<void>(
//     context: context,
//     builder: (ctx) => AlertDialog(
//       title: Text(ctx.tr(AppTextKey.prescriptionsConfirmExportTitle)),
//       content: Text(ctx.tr(AppTextKey.prescriptionsConfirmExportBody)),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(ctx).pop(),
//           child: Text(ctx.tr(AppTextKey.prescriptionsCancelAction)),
//         ),
//         FilledButton(
//           style: FilledButton.styleFrom(backgroundColor: AppColors.mutedInk),
//           onPressed: () {
//             Navigator.of(ctx).pop();
//             onConfirm();
//           },
//           child: Text(ctx.tr(AppTextKey.prescriptionsConfirmAction)),
//         ),
//       ],
//     ),
//   );
// }

// class _InteractionPolicyCard extends StatelessWidget {
//   const _InteractionPolicyCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.prescriptionsInteractionTitle),
//       minHeight: _PrescriptionsLayout.actionCardMinHeight,
//       child: Text(context.tr(AppTextKey.prescriptionsInteractionBody)),
//     );
//   }
// }
