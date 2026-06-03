import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/datasource/QueueDatasource/queue_datasource.dart';
import '../../data/models/queue_models.dart';
import '../bloc/queue/queue_bloc.dart';
import '../bloc/queue/queue_event.dart';
import '../bloc/queue/queue_state.dart';

abstract final class _QueueLayout {
  static const double queueMinHeight = 300;
  static const double rowHeight = 46;
  static const double policyMinHeight = 118;
}

// ── Screen ─────────────────────────────────────────────────────────
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          QueueBloc(const QueueDatasource())..add(QueueLoadRequested()),
      child: const _QueueView(),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _QueueCard(),
        SizedBox(height: AppSpacing.xl),
        _QueuePolicyCard(),
      ],
    );
  }
}

// ── QueueCard — contenu dynamique ─────────────────────────────────
class _QueueCard extends StatelessWidget {
  const _QueueCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (ctx, state) {
        // Titre avec compteur dynamique
        final count = state is QueueLoaded ? state.items.length : 0;

        return SectionCard(
          title: context.tr(AppTextKey.queueTitle),
          subtitle: context.tr(AppTextKey.queueSubtitle),
          trailing: state is QueueLoaded
              ? StatusBadge(label: '$count patient(s)', tone: BadgeTone.info)
              : null,
          minHeight: _QueueLayout.queueMinHeight,
          child: switch (state) {
            QueueLoading() => const _QueueLoadingSkeleton(),
            QueueError() => _QueueErrorView(
              message: state.message,
              onRetry: () => ctx.read<QueueBloc>().add(QueueLoadRequested()),
            ),
            QueueLoaded() => _QueueList(state: state),
            _ => const _QueueLoadingSkeleton(),
          },
        );
      },
    );
  }
}

// ── Liste de la file ───────────────────────────────────────────────
class _QueueList extends StatelessWidget {
  final QueueLoaded state;
  const _QueueList({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 40,
                color: AppColors.normal,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'File d\'attente vide',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Priorité haute (> 30 min) ─────────────────────────
        if (state.highPriority.isNotEmpty) ...[
          _PrioritySection(
            label: 'Priorité haute',
            count: state.highPriority.length,
            tone: BadgeTone.critical,
            color: AppColors.critical,
            items: state.highPriority,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Priorité moyenne (15–30 min) ──────────────────────
        if (state.mediumPriority.isNotEmpty) ...[
          _PrioritySection(
            label: 'Priorité moyenne',
            count: state.mediumPriority.length,
            tone: BadgeTone.neutral,
            color: AppColors.warning,
            items: state.mediumPriority,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Priorité basse (< 15 min) ─────────────────────────
        if (state.lowPriority.isNotEmpty)
          _PrioritySection(
            label: 'Priorité basse',
            count: state.lowPriority.length,
            tone: BadgeTone.info,
            color: AppColors.mutedInk,
            items: state.lowPriority,
          ),
      ],
    );
  }
}

// ── Section par priorité ───────────────────────────────────────────
class _PrioritySection extends StatelessWidget {
  final String label;
  final int count;
  final BadgeTone tone;
  final Color color;
  final List<QueueItem> items;

  const _PrioritySection({
    required this.label,
    required this.count,
    required this.tone,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label de section
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(label: '$count', tone: tone),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Lignes patients
        Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _QueueRow(item: item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Ligne patient dans la file ─────────────────────────────────────
class _QueueRow extends StatelessWidget {
  final QueueItem item;
  const _QueueRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final priority = item.currentPriority;
    final isCritical = priority == QueuePriority.high;
    final isWarning = priority == QueuePriority.medium;

    final color = switch (priority) {
      QueuePriority.high => AppColors.critical,
      QueuePriority.medium => AppColors.warning,
      QueuePriority.low => AppColors.mutedInk,
    };

    final (priorityLabel, priorityTone) = switch (priority) {
      QueuePriority.high => ('Haute', BadgeTone.critical),
      QueuePriority.medium => ('Moyenne', BadgeTone.neutral),
      QueuePriority.low => ('Basse', BadgeTone.info),
    };

    return Container(
      height: _QueueLayout.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCritical ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          // Icône drag (conservée de l'UI existante)
          Icon(Icons.drag_indicator_rounded, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 38,
            child: Text(
              item.scheduledTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Nom du patient
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.patientName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.reason.isNotEmpty)
                  Text(
                    item.reason,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Badge priorité
          StatusBadge(label: priorityLabel, tone: priorityTone),
          const SizedBox(width: AppSpacing.sm),

          // Temps d'attente dynamique
          _WaitTimeLabel(item: item),
        ],
      ),
    );
  }
}

// ── Timer local pour le temps d'attente ───────────────────────────
// Rebuilt chaque minute grâce au QueueBloc ticker
class _WaitTimeLabel extends StatelessWidget {
  final QueueItem item;
  const _WaitTimeLabel({required this.item});

  @override
  Widget build(BuildContext context) {
    final priority = item.currentPriority;

    final color = switch (priority) {
      QueuePriority.high => AppColors.critical,
      QueuePriority.medium => AppColors.warning,
      QueuePriority.low => AppColors.mutedInk,
    };

    return Text(
      item.waitLabel, // ← DYNAMIQUE : recalculé à chaque rebuild
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Policy Card — inchangée ────────────────────────────────────────
class _QueuePolicyCard extends StatelessWidget {
  const _QueuePolicyCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.queuePolicyTitle),
      minHeight: _QueueLayout.policyMinHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(AppTextKey.queuePolicyBody)),
          const SizedBox(height: AppSpacing.md),
          // Légende des priorités (dynamique)
          const _PriorityLegend(),
        ],
      ),
    );
  }
}

class _PriorityLegend extends StatelessWidget {
  const _PriorityLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(color: AppColors.critical, label: '> 30 min — Haute'),
        const SizedBox(width: AppSpacing.lg),
        _LegendItem(color: AppColors.warning, label: '15–30 min — Moyenne'),
        const SizedBox(width: AppSpacing.lg),
        _LegendItem(color: AppColors.mutedInk, label: '< 15 min — Basse'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
        ),
      ],
    );
  }
}

// ── Loading skeleton ───────────────────────────────────────────────
class _QueueLoadingSkeleton extends StatelessWidget {
  const _QueueLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            height: _QueueLayout.rowHeight,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────
class _QueueErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _QueueErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.mutedInk),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Réessayer'),
          ),
        ],
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

// abstract final class _QueueLayout {
//   static const double queueMinHeight = 300;
//   static const double rowHeight = 46;
//   static const double policyMinHeight = 118;
// }

// class QueueScreen extends StatelessWidget {
//   const QueueScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _QueueCard(),
//         const SizedBox(height: AppSpacing.xl),
//         const _QueuePolicyCard(),
//       ],
//     );
//   }
// }

// class _QueueCard extends StatelessWidget {
//   const _QueueCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.queueTitle),
//       subtitle: context.tr(AppTextKey.queueSubtitle),
//       minHeight: _QueueLayout.queueMinHeight,
//       child: const Column(
//         children: [
//           _QueueRow(
//             patientKey: AppTextKey.appointmentsPatientMariam,
//             priorityKey: AppTextKey.queueHighPriority,
//             waitKey: AppTextKey.queueWaitLong,
//             critical: true,
//           ),
//           SizedBox(height: AppSpacing.md),
//           _QueueRow(
//             patientKey: AppTextKey.appointmentsPatientFatima,
//             priorityKey: AppTextKey.queueMediumPriority,
//             waitKey: AppTextKey.queueWaitMedium,
//           ),
//           SizedBox(height: AppSpacing.md),
//           _QueueRow(
//             patientKey: AppTextKey.appointmentsPatientAli,
//             priorityKey: AppTextKey.queueLowPriority,
//             waitKey: AppTextKey.queueWaitShort,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QueueRow extends StatelessWidget {
//   const _QueueRow({
//     required this.patientKey,
//     required this.priorityKey,
//     required this.waitKey,
//     this.critical = false,
//   });

//   final AppTextKey patientKey;
//   final AppTextKey priorityKey;
//   final AppTextKey waitKey;
//   final bool critical;

//   @override
//   Widget build(BuildContext context) {
//     final color = critical ? AppColors.critical : AppColors.mutedInk;

//     return Container(
//       height: _QueueLayout.rowHeight,
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: critical ? 0.06 : 0.04),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: color.withValues(alpha: 0.14)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.drag_indicator_rounded, color: color, size: 20),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Text(
//               context.tr(patientKey),
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
//             ),
//           ),
//           StatusBadge(
//             label: context.tr(priorityKey),
//             tone: critical ? BadgeTone.critical : BadgeTone.neutral,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Text(context.tr(waitKey)),
//         ],
//       ),
//     );
//   }
// }

// class _QueuePolicyCard extends StatelessWidget {
//   const _QueuePolicyCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.queuePolicyTitle),
//       minHeight: _QueueLayout.policyMinHeight,
//       child: Text(context.tr(AppTextKey.queuePolicyBody)),
//     );
//   }
// }
