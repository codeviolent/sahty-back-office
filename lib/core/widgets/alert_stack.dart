import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'clinical_alert_banner.dart';

// ──────────────────────────────────────────────────────────────────────────────

/// Data for a single clinical alert.
class AlertData {
  const AlertData({
    required this.title,
    required this.message,
    this.isCritical = false,
  });

  final String title;
  final String message;
  final bool isCritical;
}

// ──────────────────────────────────────────────────────────────────────────────

/// Visible alert group in a "stacked cards" pattern — up to 3 alerts.
///
/// ─── Animation approach ───────────────────────────────────────────────────
/// Single source of truth: [AnimationController] drives all animated elements
/// in perfect sync. No [Future.delayed] or separate implicit animations.
///
/// Stagger is achieved with [Interval]:
///   • Nearest card (depth 1): starts expanding as soon as motion begins.
///   • Farthest card (depth 2): starts with a 15% delay — follows the first.
///
/// Collapse is the reverse:
///   • Farthest card finishes collapsing at ctrl = 15% — retracts first.
///   • Nearest card takes the full duration.
///
/// Actual front-card height is measured with [GlobalKey] after the first frame —
/// no arbitrary height estimate.
class AlertStack extends StatefulWidget {
  const AlertStack({super.key, required this.alerts});

  final List<AlertData> alerts;

  @override
  State<AlertStack> createState() => _AlertStackState();
}

class _AlertStackState extends State<AlertStack>
    with SingleTickerProviderStateMixin {
  // ── Layout constants ──────────────────────────────────────────
  static const _kGap = 10.0; // gap between cards in the expanded state
  static const _kCollapsedOffset = 12.0; // visible peek of each background card when collapsed
  static const _kInset = 8.0; // horizontal inset per depth level (subtle depth effect)
  static const _kEstH = 76.0; // initial height estimate (corrected after first frame)

  // ── Animation ─────────────────────────────────────────────────
  late final AnimationController _ctrl;

  /// progress[i] tracks card position at depth = i+1 (value from 0 to 1).
  late List<Animation<double>> _progress;

  // ── Height measurement ────────────────────────────────────────
  double _cardH = _kEstH;
  final _frontKey = GlobalKey();

  // ── Visible alerts ────────────────────────────────────────────
  // Computed once per widget configuration, never inside AnimatedBuilder.
  // The getter pattern (take(3).toList()) was allocating a new List on
  // every call inside _buildStack() which runs on every animation frame.
  late List<AlertData> _visibleAlerts;
  int get _n => _visibleAlerts.length;

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _visibleAlerts = widget.alerts.take(3).toList();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
      reverseDuration: const Duration(milliseconds: 340),
    );

    _buildAnims();

    // Measure actual front-card height after the first frame
    WidgetsBinding.instance.addPostFrameCallback(_measureFront);
  }

  void _buildAnims() {
    final n = _n;

    // ── Position animations ────────────────────────────────────
    // curve  : card at depth=i starts with delay (i-1)×15%
    // reverseCurve: card at depth=i finishes collapsing at ctrl=(i-1)×15%
    _progress = [
      for (int i = 1; i < n; i++)
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(
            (i - 1) * 0.15,
            1.0,
            curve: const Cubic(0.16, 1.0, 0.3, 1.0), // Apple spring ease
          ),
          reverseCurve: Interval(
            (i - 1) * 0.15,
            1.0,
            curve: Curves.easeInCubic,
          ),
        ),
    ];
  }

  @override
  void didUpdateWidget(covariant AlertStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.alerts != widget.alerts) {
      _visibleAlerts = widget.alerts.take(3).toList();
    }

    final previousVisibleCount = oldWidget.alerts.take(3).length;
    if (previousVisibleCount != _n) {
      _buildAnims();
      if (_n <= 1) _ctrl.value = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback(_measureFront);
  }

  void _measureFront(_) {
    final box = _frontKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if (h > 1 && (h - _cardH).abs() > 1) setState(() => _cardH = h);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Interaction
  // ─────────────────────────────────────────────────────────────

  void _onTap() {
    if (_ctrl.isAnimating) {
      // Immediate reversal mid-animation — preserves momentum
      if (_ctrl.velocity > 0) {
        _ctrl.reverse();
      } else {
        _ctrl.forward();
      }
      return;
    }
    if (_ctrl.value < 0.5) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_n == 0) {
      return const SizedBox.shrink();
    }

    if (_n == 1) {
      return ClinicalAlertBanner(
        title: _visibleAlerts[0].title,
        message: _visibleAlerts[0].message,
        isCritical: _visibleAlerts[0].isCritical,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => _buildStack(),
        ),
      ),
    );
  }

  Widget _buildStack() {
    final n = _n;
    final t = _ctrl.value;
    final extentT = Curves.easeOutCubic.transform(t);
    final h = _cardH;

    // Stack height transitions between a real pile and fully open cards.
    final collapsedH = h + _kCollapsedOffset * (n - 1);
    final expandedH = n * h + (n - 1) * _kGap;
    final stackH = lerpDouble(collapsedH, expandedH, extentT)!;

    // ── Single shadow on the whole component + clip ─────────────────────────
    // No per-card shadow → avoids visual clutter during the gesture
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: SizedBox(
            height: stackH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Farthest card drawn first, then nearer ones, then the front card.
                for (int i = n - 1; i >= 1; i--) _buildBack(i),

                // Front card: z-top, shadow: false (shadow lives on the outer container)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClinicalAlertBanner(
                    key: _frontKey,
                    title: _visibleAlerts[0].title,
                    message: _visibleAlerts[0].message,
                    isCritical: _visibleAlerts[0].isCritical,
                    shadow: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBack(int i) {
    final alert = _visibleAlerts[i];
    final pos = _progress[i - 1].value;
    // ── Vertical position ─────────────────────────────────────────
    // collapsed: cards stacked with a small offset that reveals depth only
    // expanded : full card at its position in the column
    final collapsedTop = i * _kCollapsedOffset;
    final expandedTop = i * (_cardH + _kGap);
    final top = lerpDouble(collapsedTop, expandedTop, pos)!;

    // ── Horizontal inset ────────────────────────────────────────
    // background cards are slightly narrower in the collapsed state
    final inset = lerpDouble(_kInset * i.toDouble(), 0.0, pos)!;

    return Positioned(
      top: top,
      left: inset,
      right: inset,
      height: _cardH,
      // shadow: false — prevents background card shadows from burying the gesture area
      child: _BackAlertCard(alert: alert, revealProgress: pos),
    );
  }
}

class _BackAlertCard extends StatelessWidget {
  const _BackAlertCard({required this.alert, required this.revealProgress});

  final AlertData alert;
  final double revealProgress;

  @override
  Widget build(BuildContext context) {
    final color = alert.isCritical ? AppColors.critical : AppColors.warning;
    final icon = alert.isCritical
        ? Icons.warning_rounded
        : Icons.notifications_outlined;
    final chipLabel = alert.isCritical ? 'CRITIQUE' : 'ATTENTION';
    final showContent = revealProgress > 0.18;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showContent)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.lg,
                  end: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.mutedInk,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        chipLabel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                        ),
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
