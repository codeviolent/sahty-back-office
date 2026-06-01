import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sahty_back_office/features/dashboard/presentation/bloc/dashboard_state.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/alert_stack.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/datasource/dashboard_datasource.dart';
import '../../data/models/dashboard_models.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';

// ──────────────────────────── Mock data (self-contained) ───────────────────────────────

enum _RecordStatus { validated, alert, blocked, sent, read }

class _Appointment {
  const _Appointment({
    required this.time,
    required this.patient,
    required this.motif,
    required this.status,
  });

  final String time;
  final String patient;
  final String motif;
  final _RecordStatus status;
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.time,
    required this.event,
    required this.actor,
    required this.status,
  });

  final String time;
  final String event;
  final String actor;
  final _RecordStatus status;
}

abstract final class _DashboardMock {
  // ── Clinical alerts — displayed in a stack (max 3) ─────────────────────────
  static const clinicalAlerts = [
    AlertData(
      title: 'Résultat critique : HbA1c 11.2 %',
      message:
          'Fatima Mint Cheikh — Seuil dépassé, intervention médicale immédiate requise.',
      isCritical: true,
    ),
    AlertData(
      title: 'Connexion suspecte détectée',
      message:
          'Appareil inconnu — IP 192.168.1.44. Vérification administrateur requise.',
      isCritical: true,
    ),
    AlertData(
      title: 'Renouvellement ordonnance en attente',
      message:
          'Ali Ould Hassan — Ordonnance expirée depuis 3 jours. Validation requise.',
    ),
  ];

  static const appointments = [
    _Appointment(
      time: '08:30',
      patient: 'Mariam Bent Salem',
      motif: 'Suivi diabète',
      status: _RecordStatus.validated,
    ),
    _Appointment(
      time: '09:00',
      patient: 'Oumar Ould Bilal',
      motif: 'Consultation cardiologie',
      status: _RecordStatus.validated,
    ),
    _Appointment(
      time: '09:45',
      patient: 'Fatima Mint Cheikh',
      motif: 'Résultat HbA1c — critique',
      status: _RecordStatus.alert,
    ),
    _Appointment(
      time: '10:30',
      patient: 'Ali Ould Hassan',
      motif: 'Renouvellement ordonnance',
      status: _RecordStatus.validated,
    ),
    _Appointment(
      time: '11:15',
      patient: 'Aïcha Bint Moussa',
      motif: 'Consultation en ligne',
      status: _RecordStatus.sent,
    ),
  ];

  static const activityLog = [
    _ActivityEntry(
      time: '10:14',
      event: 'Session ouverte — Mariam Bent Salem',
      actor: 'Dr. Nichols',
      status: _RecordStatus.validated,
    ),
    _ActivityEntry(
      time: '09:47',
      event: 'Résultat labo hors seuil: HbA1c 11.2%',
      actor: 'Système',
      status: _RecordStatus.alert,
    ),
    _ActivityEntry(
      time: '09:23',
      event: 'Tentative connexion — appareil inconnu',
      actor: 'IP: 192.168.1.44',
      status: _RecordStatus.blocked,
    ),
    _ActivityEntry(
      time: '08:55',
      event: 'Ordonnance créée — Ali Ould Hassan',
      actor: 'Dr. Nichols',
      status: _RecordStatus.sent,
    ),
    _ActivityEntry(
      time: '08:30',
      event: 'Dossier consulté — Fatima Mint Cheikh',
      actor: 'Dr. Nichols',
      status: _RecordStatus.read,
    ),
  ];
}

// ──────────────────────────────────────────────────────────────────────────────

/// Screen 3 — dashboard.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardBloc(const DashboardDatasource())
            ..add(DashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (ctx, state) => switch (state) {
        DashboardLoading() => _LoadingSkeleton(),
        DashboardError() => _ErrorView(
          message: state.message,
          onRetry: () =>
              ctx.read<DashboardBloc>().add(DashboardLoadRequested()),
        ),
        DashboardLoaded() => _DashboardContent(data: state.data),
        _ => _LoadingSkeleton(),
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<DashboardBloc>().add(DashboardRefreshRequested());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(doctor: data.doctor),
          const SizedBox(height: AppSpacing.lg),

          // Critical alerts — stacked cards, always at the top of the page
          ///AlertStack(alerts: _DashboardMock.clinicalAlerts),
          if (data.criticalAlerts.isNotEmpty)
            AlertStack(
              alerts: data.criticalAlerts.map((alert) {
                return alert.toAlertData();
              }).toList(),
            ),

          const SizedBox(height: AppSpacing.xl),
          _SummaryStrip(kpis: data.kpis),
          const SizedBox(height: AppSpacing.xl),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _AppointmentsCard(rdvs: data.rdvDuJour)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 5,
                child: _ActivityFeedCard(activities: data.recentActivity),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final DoctorInfo doctor;
  const _PageHeader({required this.doctor});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatted = DateFormat(
      'd MMMM yyyy, h:mm a',
      'fr_FR',
    ).format(now);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${doctor.greeting}, Dr. ${doctor.firstName} ${doctor.lastName}\u00A0!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr(AppTextKey.dashboardSubhead),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: dateFormatted,
          tone: BadgeTone.info,
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }
}

// ── Loading Skeleton ───────────────────────────────────────────────
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

// ── Summary Strip — Premium KPI Cards ─────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final List<KpiItem> kpis;
  const _SummaryStrip({required this.kpis});
  @override
  Widget build(BuildContext context) {
    final metriques = kpis
        .map(
          (kpi) => _KpiMetric(
            icon: kpi.icon,
            value: kpi.value, // ← valeur réelle depuis l'API
            label: kpi.label, // ← label depuis le modèle
            tone: kpi.tone,
          ),
        )
        .toList();
    final metrics = [
      _KpiMetric(
        icon: Icons.groups_rounded,
        value: '42',
        label: context.tr(AppTextKey.totalPatients),
        tone: AppColors.primary,
      ),
      _KpiMetric(
        icon: Icons.list_alt_rounded,
        value: '9',
        label: context.tr(AppTextKey.queueToday),
        tone: AppColors.warning,
      ),
      _KpiMetric(
        icon: Icons.calendar_month_rounded,
        value: '18',
        label: context.tr(AppTextKey.appointmentsToday),
        tone: AppColors.info,
      ),
      _KpiMetric(
        icon: Icons.mark_email_unread_rounded,
        value: '16',
        label: context.tr(AppTextKey.unreadMessages),
        tone: AppColors.info,
      ),
      _KpiMetric(
        icon: Icons.warning_rounded,
        value: '3',
        label: context.tr(AppTextKey.criticalAlerts),
        tone: AppColors.critical,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < metriques.length; i++) ...[
          Expanded(child: _KpiCell(metric: metriques[i])),
          if (i < metriques.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _KpiMetric {
  const _KpiMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tone;
}

class _KpiCell extends StatefulWidget {
  const _KpiCell({required this.metric});

  final _KpiMetric metric;

  @override
  State<_KpiCell> createState() => _KpiCellState();
}

class _KpiCellState extends State<_KpiCell>
    with SingleTickerProviderStateMixin {
  // Shared static decorations that don't depend on instance data.
  static final _kShadow1Dec = BoxDecoration(
    color: const Color(0xFFF0F2F4),
    borderRadius: BorderRadius.circular(16),
  );
  static final _kShadow2Dec = BoxDecoration(
    color: const Color(0xFFF8F9FA),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFF0F2F4)),
  );
  static final _kCardDec = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: const Color(0xFFE7EAEE)),
  );

  // Per-instance decorations computed once in initState from the clinical state.
  late final BoxDecoration _iconDec;
  late final BoxDecoration _badgeDec;

  late final AnimationController _hoverCtrl;
  late final Animation<double> _hoverAnim;

  @override
  void initState() {
    super.initState();
    final isCritical = widget.metric.tone == AppColors.critical;
    _iconDec = BoxDecoration(
      color: AppColors.ink.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
    );
    _badgeDec = BoxDecoration(
      shape: BoxShape.circle,
      color: isCritical ? AppColors.critical : AppColors.sidebar,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.70),
        width: 1.2,
      ),
    );
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _hoverAnim = CurvedAnimation(
      parent: _hoverCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    const cardTop = 7.0;
    const cardBottom = 4.0;
    const badgeSize = 25.0;
    const badgeEndInset = -4.0;

    return MouseRegion(
      // No setState — forward/reverse the controller directly.
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _hoverAnim,
        // Static child — rebuilt only when metric changes, never on hover frames.
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                top: cardTop + 2,
                bottom: cardBottom - 2,
                start: -1,
                end: 0,
                child: DecoratedBox(decoration: _kShadow1Dec),
              ),
              PositionedDirectional(
                top: cardTop,
                bottom: cardBottom + 2,
                start: 2,
                end: 3,
                child: DecoratedBox(decoration: _kShadow2Dec),
              ),
              PositionedDirectional(
                top: cardTop,
                bottom: cardBottom,
                start: 0,
                end: 0,
                child: DecoratedBox(
                  decoration: _kCardDec,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.md,
                      end: badgeSize + AppSpacing.xs,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: _iconDec,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: Icon(
                              metric.icon,
                              color: AppColors.ink,
                              size: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            metric.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                  height: 1.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: cardTop - (badgeSize / 2),
                end: badgeEndInset,
                child: DecoratedBox(
                  decoration: _badgeDec,
                  child: SizedBox(
                    width: badgeSize,
                    height: badgeSize,
                    child: Center(
                      child: Text(
                        metric.value,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: -0.2,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -2 * _hoverAnim.value),
          child: child,
        ),
      ),
    );
  }
}

// ── Appointments Table ────────────────────────────────────────────────────────

class _AppointmentsCard extends StatelessWidget {
  final List<RdvItem> rdvs;
  const _AppointmentsCard({required this.rdvs});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.appointmentsToday),
      trailing: StatusBadge(label: '${rdvs.length}', tone: BadgeTone.info),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _CleanTableHeader(
            columns: [
              context.tr(AppTextKey.tableColTime),
              context.tr(AppTextKey.tableColPatient),
              context.tr(AppTextKey.tableColReason),
              context.tr(AppTextKey.tableColStatus),
            ],
            flexes: const [1, 3, 3, 2],
          ),
          if (rdvs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'Aucun rendez-vous aujourd\'hui',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
                ),
              ),
            )
          else
            for (int i = 0; i < rdvs.length; i++) ...[
              _RdvRealRow(rdv: rdvs[i]),
              if (i < rdvs.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.apt});

  final _Appointment apt;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appLocale == AppLocale.ar;
    final (statusLabel, tone) = switch (apt.status) {
      _RecordStatus.validated => (
        isArabic ? 'مؤكد' : 'Confirmé',
        BadgeTone.normal,
      ),
      _RecordStatus.alert => (
        isArabic ? 'حرج' : 'Critique',
        BadgeTone.critical,
      ),
      _RecordStatus.sent => (isArabic ? 'عن بُعد' : 'En ligne', BadgeTone.info),
      _RecordStatus.blocked => (
        isArabic ? 'محجوب' : 'Bloqué',
        BadgeTone.critical,
      ),
      _RecordStatus.read => (
        isArabic ? 'تمت المراجعة' : 'Consulté',
        BadgeTone.neutral,
      ),
    };

    final isAlert = apt.status == _RecordStatus.alert;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      color: isAlert ? AppColors.critical.withValues(alpha: 0.03) : null,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              apt.time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.mutedInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              apt.patient,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              apt.motif,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusBadge(label: statusLabel, tone: tone),
            ),
          ),
        ],
      ),
    );
  }
}

class _RdvRealRow extends StatelessWidget {
  final RdvItem rdv;
  const _RdvRealRow({required this.rdv});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appLocale == AppLocale.ar;

    final (statusLabel, tone) = switch (rdv.status) {
      'confirmed' => (isArabic ? 'مؤكد' : 'Confirmé', BadgeTone.normal),
      'critical' => (isArabic ? 'حرج' : 'Critique', BadgeTone.critical),
      'teleconsult' => (isArabic ? 'عن بُعد' : 'En ligne', BadgeTone.info),
      'cancelled' => (isArabic ? 'ملغى' : 'Annulé', BadgeTone.critical),
      'completed' => (
        isArabic ? 'تمت المراجعة' : 'Consulté',
        BadgeTone.neutral,
      ),
      'no_show' => (isArabic ? 'غائب' : 'Absent', BadgeTone.neutral),
      _ => (isArabic ? 'في الانتظار' : 'En attente', BadgeTone.neutral),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      color: rdv.isCritique ? AppColors.critical.withValues(alpha: 0.03) : null,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              rdv.time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.mutedInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              rdv.patientName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              rdv.motif.isEmpty ? '—' : rdv.motif,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusBadge(label: statusLabel, tone: tone),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Feed Table ───────────────────────────────────────────────────────

class _ActivityFeedCard extends StatelessWidget {
  final List<ActivityItem> activities;
  const _ActivityFeedCard({required this.activities});
  @override
  Widget build(BuildContext context) {
    final headers = context.appLocale == AppLocale.ar
        ? const ['الوقت', 'الحدث', 'المنفّذ', 'الحالة']
        : const ['Heure', 'Événement', 'Acteur', 'État'];
    return SectionCard(
      title: context.tr(AppTextKey.activityFeed),
      trailing: StatusBadge(
        label: context.tr(AppTextKey.dailyActivity),
        tone: BadgeTone.neutral,
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _CleanTableHeader(columns: headers, flexes: const [1, 4, 2, 2]),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'Aucune activité récente',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
                ),
              ),
            )
          else
            for (int i = 0; i < activities.length; i++) ...[
              _ActivityRealRow(entry: activities[i]),
              if (i < activities.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appLocale == AppLocale.ar;
    final (statusLabel, tone) = switch (entry.status) {
      _RecordStatus.validated => (
        isArabic ? 'معتمد' : 'Validé',
        BadgeTone.normal,
      ),
      _RecordStatus.alert => (
        isArabic ? 'تنبيه' : 'Alerte',
        BadgeTone.critical,
      ),
      _RecordStatus.blocked => (
        isArabic ? 'محجوب' : 'Bloqué',
        BadgeTone.critical,
      ),
      _RecordStatus.sent => (isArabic ? 'مرسل' : 'Envoyé', BadgeTone.info),
      _RecordStatus.read => (isArabic ? 'مقروء' : 'Lecture', BadgeTone.neutral),
    };

    final isCritical =
        entry.status == _RecordStatus.alert ||
        entry.status == _RecordStatus.blocked;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      color: isCritical ? AppColors.critical.withValues(alpha: 0.03) : null,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              entry.time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.mutedInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              entry.event,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.actor,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusBadge(label: statusLabel, tone: tone),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRealRow extends StatelessWidget {
  final ActivityItem entry;
  const _ActivityRealRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appLocale == AppLocale.ar;

    final (statusLabel, tone) = switch (entry.status) {
      'valide' => (isArabic ? 'معتمد' : 'Validé', BadgeTone.normal),
      'alerte' => (isArabic ? 'تنبيه' : 'Alerte', BadgeTone.critical),
      'bloque' => (isArabic ? 'محجوب' : 'Bloqué', BadgeTone.critical),
      'envoye' => (isArabic ? 'مرسل' : 'Envoyé', BadgeTone.info),
      _ => (isArabic ? 'مقروء' : 'Lecture', BadgeTone.neutral),
    };

    final isCritical = entry.status == 'alerte' || entry.status == 'bloque';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      color: isCritical ? AppColors.critical.withValues(alpha: 0.03) : null,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              entry.time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.mutedInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              entry.event,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.actor,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusBadge(label: statusLabel, tone: tone),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clean Table Header ────────────────────────────────────────────────────────
//
// Inspired by Claude/Linear: uppercase label text with a bottom divider —
// no background fill, no border box. Crisp and minimal.

class _CleanTableHeader extends StatelessWidget {
  const _CleanTableHeader({required this.columns, required this.flexes});

  final List<String> columns;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    assert(columns.length == flexes.length);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.6),
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
                columns[i].toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
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

// ── Error View ─────────────────────────────────────────────────────
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
