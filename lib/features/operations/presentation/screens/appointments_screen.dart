import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/datasource/AgendaDatasource/agenda_datasource.dart';
import '../../data/models/appointment_item.dart';
import '../bloc/agenda/agenda_bloc.dart';
import '../bloc/agenda/agenda_event.dart';
import '../bloc/agenda/agenda_state.dart';

abstract final class _AppointmentsLayout {
  static const double periodMinHeight = 132;
  static const double listMinHeight = 300;
  static const double rowHeight = 46;
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgendaBloc(AgendaDatasource())..add(AgendaLoadRequested()),
      child: const AppointmentView(),
    );
  }
}

class AppointmentView extends StatelessWidget {
  const AppointmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgendaBloc, AgendaState>(
      builder: (context, state) => switch (state) {
        AgendaLoading() => _LoadingSkeleton(),
        AgendaError() => _ErrorView(
          message: state.message,
          onRetry: () => context.read<AgendaBloc>().add(AgendaLoadRequested()),
        ),
        AgendaLoaded() => AppointementContent(data: state.data),
        _ => _LoadingSkeleton(),
      },
    );
  }
}

class AppointementContent extends StatelessWidget {
  final ListRdv data;
  const AppointementContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<AgendaBloc>().add(AgendaLoadRequested()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PeriodSelectorCard(),
          const SizedBox(height: AppSpacing.xl),
          _AppointmentsCard(data: data.rdvList),
        ],
      ),
    );
  }
}

class _PeriodSelectorCard extends StatelessWidget {
  const _PeriodSelectorCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.appointmentsViewTitle),
      subtitle: context.tr(AppTextKey.appointmentsQueueSubtitle),
      minHeight: _AppointmentsLayout.periodMinHeight,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          StatusBadge(label: context.tr(AppTextKey.appointmentsDay)),
          StatusBadge(label: context.tr(AppTextKey.appointmentsWeek)),
          StatusBadge(label: context.tr(AppTextKey.appointmentsMonth)),
        ],
      ),
    );
  }
}

class _AppointmentItem {
  const _AppointmentItem({
    required this.patientKey,
    required this.timeKey,
    required this.statusKey,
    this.critical = false,
  });

  final AppTextKey patientKey;
  final AppTextKey timeKey;
  final AppTextKey statusKey;
  final bool critical;
}

class _AppointmentsCard extends StatelessWidget {
  final List<AppointmentItem> data;
  const _AppointmentsCard({required this.data});

  static const items = [
    _AppointmentItem(
      patientKey: AppTextKey.appointmentsPatientFatima,
      timeKey: AppTextKey.appointmentsTimeMorning,
      statusKey: AppTextKey.appointmentsStatusConfirmed,
    ),
    _AppointmentItem(
      patientKey: AppTextKey.appointmentsPatientAli,
      timeKey: AppTextKey.appointmentsTimeNoon,
      statusKey: AppTextKey.appointmentsStatusDelayed,
    ),
    _AppointmentItem(
      patientKey: AppTextKey.appointmentsPatientMariam,
      timeKey: AppTextKey.appointmentsTimeLate,
      statusKey: AppTextKey.appointmentsStatusLate,
      critical: true,
    ),
    _AppointmentItem(
      patientKey: AppTextKey.patientSearchPatientMariam,
      timeKey: AppTextKey.appointmentsTimeNoon,
      statusKey: AppTextKey.appointmentsStatusCancelled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.appointmentsListTitle),
      subtitle: context.tr(AppTextKey.appointmentsListSubtitle),
      minHeight: _AppointmentsLayout.listMinHeight,
      child: Column(
        children: [
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Aucun rendez-vous aujourd\'hui',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
              ),
            )
          else
            for (int i = 0; i < data.length; i++) ...[
              _ScheduleRow(item: data[i]),
              if (i < data.length - 1) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item});

  final AppointmentItem item;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appLocale == AppLocale.ar;
    final (statusLabel, tone) = switch (item.status) {
      'confirmed' => (isArabic ? 'مؤكد' : 'Confirmé', BadgeTone.normal),
      'critical' => (isArabic ? 'حرج' : 'Critique', BadgeTone.critical),
      'teleconsult' => (isArabic ? 'عن بُعد' : 'En ligne', BadgeTone.info),
      'cancelled' => (isArabic ? 'ملغى' : 'Annulé', BadgeTone.critical),
      'pending' => (isArabic ? 'في الانتظار' : 'En attente', BadgeTone.warning),
      'completed' => (
        isArabic ? 'تمت المراجعة' : 'Consulté',
        BadgeTone.neutral,
      ),
      'no_show' => (isArabic ? 'غائب' : 'Absent', BadgeTone.neutral),
      _ => (isArabic ? 'في الانتظار' : 'En attente', BadgeTone.neutral),
    };

    return SizedBox(
      height: _AppointmentsLayout.rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              item.time,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                //color: item. ? AppColors.critical : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.patientName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          StatusBadge(
            label: item.statusLabel,
            tone: tone,
            //tone: item.critical ? BadgeTone.critical : BadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Shimmer(width: 220, height: 22),
                  const SizedBox(height: 6),
                  _Shimmer(width: 80, height: 14),
                ],
              ),
              const Spacer(),
              _Shimmer(width: 180, height: 32),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          // KPI skeleton
          Row(
            children: List.generate(
              5,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: _Shimmer(width: double.infinity, height: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Tables skeleton
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _Shimmer(width: double.infinity, height: 280),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                flex: 5,
                child: _Shimmer(width: double.infinity, height: 280),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height;
  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.mutedInk),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.border,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
