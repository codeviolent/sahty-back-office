// lib/features/medical_record/presentation/screens/imaging_screen.dart

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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

abstract final class _Layout {
  static const double galleryMinH = 342;
  static const double viewerMinH = 342;
  static const double bottomMinH = 168;
  static const double thumbH = 62;
  static const double galleryListH = 346;
  static const double previewH = 218;
  static const double actionStripH = 58;
}

// ══════════════════════════════════════════════════════════════════
class ImagingScreen extends StatelessWidget {
  const ImagingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      ClinicalSessionGate(builder: (s) => _ImagingBlocView(session: s));
}

// ══════════════════════════════════════════════════════════════════
class _ImagingBlocView extends StatelessWidget {
  final PatientSession session;
  const _ImagingBlocView({required this.session});
  static const _section = DossierSection.imaging;

  @override
  Widget build(BuildContext context) {
    return SectionDispatcher(
      section: DossierSection.imaging,
      builder: (ctx, state, session) {
        final raw   = getSectionData(state, DossierSection.imaging) ?? [];
        final items = raw.map((e) =>
          MedicalRecordItem.fromJson(e as Map<String, dynamic>)).toList();
        if (items.isEmpty) return const SectionEmpty(label: "examen d'imagerie");
        return _ImagingContent(items: items);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// StatefulWidget uniquement pour l'état UI : index sélectionné
// ══════════════════════════════════════════════════════════════════
class _ImagingContent extends StatefulWidget {
  final List<MedicalRecordItem> items;
  const _ImagingContent({required this.items});
  @override
  State<_ImagingContent> createState() => _ImagingContentState();
}

class _ImagingContentState extends State<_ImagingContent> {
  int _selectedIndex = 0;

  void _select(int i) {
    if (_selectedIndex == i) return;
    setState(() => _selectedIndex = i);
  }

  MedicalRecordItem get _selected =>
      widget.items[_selectedIndex.clamp(0, widget.items.length - 1)];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _GalleryCard(
                items: widget.items,
                selectedIndex: _selectedIndex,
                onSelected: _select,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              flex: 7,
              child: _ViewerCard(
                record: _selected,
                onFullscreen: () => _openFullscreen(context),
                onCompare: () => _openComparison(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ComparisonCard(
                record: _selected,
                onCompare: () => _openComparison(context),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            const Expanded(child: _PolicyCard()),
          ],
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _FullscreenViewer(record: _selected),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
    );
  }

  void _openComparison(BuildContext context) {
    if (widget.items.length < 2) return;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _ComparisonViewer(
        items: widget.items,
        initialLeftIndex: _selectedIndex,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
    );
  }
}

// ── Galerie ────────────────────────────────────────────────────────
class _GalleryCard extends StatelessWidget {
  final List<MedicalRecordItem> items;
  final int selectedIndex;
  final void Function(int) onSelected;
  const _GalleryCard({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.imagingGalleryTitle),
      subtitle: '${items.length} examen(s)',
      minHeight: _Layout.galleryMinH,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: math.min(
              _Layout.galleryListH,
              (items.length * (_Layout.thumbH + 1)).toDouble(),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemExtent: _Layout.thumbH + 1,
              itemBuilder: (ctx, i) {
                final isLast = i == items.length - 1;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Thumb(
                      record: items[i],
                      selected: selectedIndex == i,
                      onTap: () => onSelected(i),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: AppSpacing.xl,
                        endIndent: AppSpacing.xl,
                      ),
                  ],
                );
              },
            ),
          ),
          const _GalleryFooter(),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final MedicalRecordItem record;
  final bool selected;
  final VoidCallback onTap;
  const _Thumb({
    required this.record,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.035)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _Layout.thumbH,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                margin: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.image_search_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title.isNotEmpty ? record.title : 'Imagerie',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${record.doctorName} — ${record.formattedDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.chevron_right_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.mutedInk.withValues(alpha: 0.42),
              ),
              const SizedBox(width: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryFooter extends StatelessWidget {
  const _GalleryFooter();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.mutedInk,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.tr(AppTextKey.imagingPolicyBody),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Viewer ─────────────────────────────────────────────────────────
class _ViewerCard extends StatelessWidget {
  final MedicalRecordItem record;
  final VoidCallback onFullscreen;
  final VoidCallback onCompare;
  const _ViewerCard({
    required this.record,
    required this.onFullscreen,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.imagingViewerTitle),
      subtitle: context.tr(AppTextKey.imagingViewerSubtitle),
      minHeight: _Layout.viewerMinH,
      trailing: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onFullscreen,
        child: StatusBadge(
          label: context.tr(AppTextKey.imagingFullscreen),
          tone: BadgeTone.neutral,
          icon: Icons.fullscreen_rounded,
        ),
      ),
      child: Column(
        children: [
          // Zone preview
          Container(
            height: _Layout.previewH,
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _ScanFallbackPainter()),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.22),
                        ],
                      ),
                    ),
                  ),
                  // Titre en haut
                  PositionedDirectional(
                    top: AppSpacing.md,
                    start: AppSpacing.md,
                    child: StatusBadge(
                      label: record.title.isNotEmpty
                          ? record.title
                          : 'Imagerie',
                      tone: BadgeTone.neutral,
                      icon: Icons.image_search_outlined,
                    ),
                  ),
                  // Date en bas
                  PositionedDirectional(
                    end: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: StatusBadge(
                      label: record.formattedDate,
                      tone: BadgeTone.neutral,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Action strip
          SizedBox(
            height: _Layout.actionStripH,
            child: Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.fullscreen_rounded,
                    label: context.tr(AppTextKey.imagingFullscreen),
                    onTap: onFullscreen,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.compare_outlined,
                    label: context.tr(AppTextKey.imagingCompare),
                    onTap: onCompare,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.lock_outline,
                    label: context.tr(AppTextKey.imagingDownload),
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.mutedInk;
    return Material(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: color.withValues(alpha: 0.13)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fullscreen Viewer ──────────────────────────────────────────────
class _FullscreenViewer extends StatefulWidget {
  final MedicalRecordItem record;
  const _FullscreenViewer({required this.record});
  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  static const double _minScale = 0.75;
  static const double _maxScale = 8;
  static const double _step = 1.35;

  final TransformationController _ctrl = TransformationController();
  double _scale = 1.0;
  late final ValueNotifier<double> _scaleNotifier;

  @override
  void initState() {
    super.initState();
    _scaleNotifier = ValueNotifier(1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  void _setScale(double v) {
    final next = v.clamp(_minScale, _maxScale);
    _scale = next;
    _scaleNotifier.value = next;
    _ctrl.value = Matrix4.diagonal3Values(next, next, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Icon(
                      Icons.image_search_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.record.title.isNotEmpty
                              ? widget.record.title
                              : 'Imagerie',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.record.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.62),
                              ),
                        ),
                      ],
                    ),
                  ),
                  _CtrlBtn(
                    icon: Icons.remove_rounded,
                    onPressed: () => _setScale(_scale / _step),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Zoom badge
                  Container(
                    width: 64,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scaleNotifier,
                      builder: (_, s, __) => Text(
                        '${(s * 100).round()}%',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CtrlBtn(
                    icon: Icons.add_rounded,
                    onPressed: () => _setScale(_scale * _step),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CtrlBtn(
                    icon: Icons.center_focus_strong_rounded,
                    onPressed: () => _setScale(1),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _CtrlBtn(
                    icon: Icons.close_rounded,
                    critical: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Viewer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                    child: InteractiveViewer(
                      transformationController: _ctrl,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      boundaryMargin: const EdgeInsets.all(220),
                      onInteractionUpdate: (_) {
                        final c = _ctrl.value.getMaxScaleOnAxis();
                        if ((c - _scale).abs() > 0.01) {
                          _scale = c;
                          _scaleNotifier.value = c;
                        }
                      },
                      child: const SizedBox.expand(
                        child: CustomPaint(painter: _ScanFallbackPainter()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool critical;
  const _CtrlBtn({
    required this.icon,
    required this.onPressed,
    this.critical = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = critical ? AppColors.critical : Colors.white;
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: critical ? 0.14 : 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: color.withValues(alpha: 0.14)),
          ),
        ),
      ),
    );
  }
}

// ── Comparison Viewer ──────────────────────────────────────────────
class _ComparisonViewer extends StatefulWidget {
  final List<MedicalRecordItem> items;
  final int initialLeftIndex;
  const _ComparisonViewer({
    required this.items,
    required this.initialLeftIndex,
  });
  @override
  State<_ComparisonViewer> createState() => _ComparisonViewerState();
}

class _ComparisonViewerState extends State<_ComparisonViewer> {
  static const double _min = 0.75, _max = 6, _step = 1.25;

  late int _leftIndex;
  late int _rightIndex;
  final TransformationController _lCtrl = TransformationController();
  final TransformationController _rCtrl = TransformationController();
  double _scale = 1.0;
  late final ValueNotifier<double> _scaleNotifier;

  @override
  void initState() {
    super.initState();
    _leftIndex = widget.initialLeftIndex;
    _rightIndex = _leftIndex == 0 ? 1 : 0;
    _scaleNotifier = ValueNotifier(1.0);
  }

  @override
  void dispose() {
    _lCtrl.dispose();
    _rCtrl.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  void _setScale(double v) {
    final next = v.clamp(_min, _max);
    _scale = next;
    _scaleNotifier.value = next;
    _lCtrl.value = Matrix4.diagonal3Values(next, next, 1);
    _rCtrl.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _swap() {
    setState(() {
      final tmp = _leftIndex;
      _leftIndex = _rightIndex;
      _rightIndex = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.items[_leftIndex.clamp(0, widget.items.length - 1)];
    final right = widget.items[_rightIndex.clamp(0, widget.items.length - 1)];

    return Material(
      color: AppColors.ink,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      context.tr(AppTextKey.imagingCompare),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _CtrlBtn(
                    icon: Icons.remove_rounded,
                    onPressed: () => _setScale(_scale / _step),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 64,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scaleNotifier,
                      builder: (_, s, __) => Text(
                        '${(s * 100).round()}%',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CtrlBtn(
                    icon: Icons.add_rounded,
                    onPressed: () => _setScale(_scale * _step),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CtrlBtn(
                    icon: Icons.center_focus_strong_rounded,
                    onPressed: () => _setScale(1),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CtrlBtn(icon: Icons.swap_horiz_rounded, onPressed: _swap),
                  const SizedBox(width: AppSpacing.md),
                  _CtrlBtn(
                    icon: Icons.close_rounded,
                    critical: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Sélecteurs (compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: _PanelSelector(
                      label: 'A',
                      items: widget.items,
                      selectedIndex: _leftIndex,
                      blockedIndex: _rightIndex,
                      onSelected: (i) => setState(() => _leftIndex = i),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: _PanelSelector(
                      label: 'B',
                      items: widget.items,
                      selectedIndex: _rightIndex,
                      blockedIndex: _leftIndex,
                      onSelected: (i) => setState(() => _rightIndex = i),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Panels
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ComparisonPanel(
                        label: 'A',
                        record: left,
                        ctrl: _lCtrl,
                        minScale: _min,
                        maxScale: _max,
                        onUpdate: () {
                          final c = _lCtrl.value.getMaxScaleOnAxis();
                          if ((c - _scale).abs() > 0.01) {
                            _scale = c;
                            _scaleNotifier.value = c;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: _ComparisonPanel(
                        label: 'B',
                        record: right,
                        ctrl: _rCtrl,
                        minScale: _min,
                        maxScale: _max,
                        onUpdate: () {
                          final c = _rCtrl.value.getMaxScaleOnAxis();
                          if ((c - _scale).abs() > 0.01) {
                            _scale = c;
                            _scaleNotifier.value = c;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelSelector extends StatelessWidget {
  final String label;
  final List<MedicalRecordItem> items;
  final int selectedIndex;
  final int blockedIndex;
  final void Function(int) onSelected;
  const _PanelSelector({
    required this.label,
    required this.items,
    required this.selectedIndex,
    required this.blockedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    SizedBox(
                      width: 154,
                      child: _SelectorChip(
                        record: items[i],
                        selected: selectedIndex == i,
                        disabled: blockedIndex == i,
                        onTap: () => onSelected(i),
                      ),
                    ),
                    if (i < items.length - 1)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorChip extends StatelessWidget {
  final MedicalRecordItem record;
  final bool selected, disabled;
  final VoidCallback onTap;
  const _SelectorChip({
    required this.record,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: disabled ? null : onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Text(
            record.title.isNotEmpty ? record.title : 'Imagerie',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: disabled
                  ? Colors.white.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: selected ? 0.96 : 0.68),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonPanel extends StatelessWidget {
  final String label;
  final MedicalRecordItem record;
  final TransformationController ctrl;
  final double minScale, maxScale;
  final VoidCallback onUpdate;
  const _ComparisonPanel({
    required this.label,
    required this.record,
    required this.ctrl,
    required this.minScale,
    required this.maxScale,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(
          AppSpacing.panelRadius,
        ).resolve(TextDirection.ltr),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: ctrl,
                minScale: minScale,
                maxScale: maxScale,
                boundaryMargin: const EdgeInsets.all(180),
                onInteractionUpdate: (_) => onUpdate(),
                child: const SizedBox.expand(
                  child: CustomPaint(painter: _ScanFallbackPainter()),
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.md,
              start: AppSpacing.md,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      record.title.isNotEmpty ? record.title : 'Imagerie',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Cards ───────────────────────────────────────────────────
class _ComparisonCard extends StatelessWidget {
  final MedicalRecordItem record;
  final VoidCallback onCompare;
  const _ComparisonCard({required this.record, required this.onCompare});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.imagingComparisonTitle),
      minHeight: _Layout.bottomMinH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.mutedInk.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onCompare,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.mutedInk.withValues(alpha: 0.13),
                  ),
                ),
                child: const Icon(
                  Icons.compare_outlined,
                  color: AppColors.mutedInk,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onCompare,
                  child: StatusBadge(
                    label: context.tr(AppTextKey.imagingCompare),
                    tone: BadgeTone.neutral,
                    icon: Icons.swap_horiz_rounded,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  record.title.isNotEmpty
                      ? record.title
                      : 'Imagerie sélectionnée',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr(AppTextKey.imagingComparisonBody),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.55,
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

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.imagingPolicyTitle),
      minHeight: _Layout.bottomMinH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mutedInk.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.mutedInk.withValues(alpha: 0.13),
              ),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.mutedInk,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              context.tr(AppTextKey.imagingPolicyBody),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback SVG peintre ────────────────────────────────────────────
class _ScanFallbackPainter extends CustomPainter {
  const _ScanFallbackPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final gridP = Paint()
      ..color = AppColors.border.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    final bodyP = Paint()
      ..color = AppColors.mutedInk.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final axisP = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final focusP = Paint()
      ..color = AppColors.critical.withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 4; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP);
    }
    for (var i = 1; i < 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.42,
        height: size.height * 0.66,
      ),
      bodyP,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, center.dy),
      Offset(size.width * 0.82, center.dy),
      axisP,
    );
    canvas.drawLine(
      Offset(center.dx, size.height * 0.18),
      Offset(center.dx, size.height * 0.82),
      axisP,
    );
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size.shortestSide * (0.085 * i), bodyP);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.58, size.height * 0.44),
          width: size.width * 0.13,
          height: size.height * 0.16,
        ),
        const Radius.circular(12),
      ),
      focusP,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// Extension utilitaire pour BorderRadius
extension on double {
  BorderRadius get asBorderRadius => BorderRadius.circular(this);
}

// import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:sahty_back_office/core/widgets/clinical_session_gate.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';
// import '../../data/models/dossier_models.dart';
// import 'imaging_mock_data.dart';

// abstract final class _ImagingLayout {
//   static const double galleryMinHeight = 342;
//   static const double viewerMinHeight = 342;
//   static const double bottomCardMinHeight = 168;
//   static const double thumbnailHeight = 62;
//   static const double galleryListHeight = 346;
//   static const double previewHeight = 218;
//   static const double statusPanelHeight = 58;
// }

// class ImagingScreen extends StatelessWidget {
//   const ImagingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ClinicalSessionGate(builder: (session) => _ImagingContent(session: session));
//   }
// }

// class _ImagingContent extends StatefulWidget {
//   final PatientSession session;
//   const _ImagingContent({required this.session});

//   @override
//   State<_ImagingContent> createState() => _ImagingContentState();
// }

// class _ImagingContentState extends State<_ImagingContent> {
//   int _selectedStudyIndex = 0;

//   void _selectStudy(int index) {
//     if (_selectedStudyIndex == index) return;
//     setState(() => _selectedStudyIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 5,
//               child: _ImageGalleryCard(
//                 selectedIndex: _selectedStudyIndex,
//                 onSelected: _selectStudy,
//               ),
//             ),
//             const SizedBox(width: AppSpacing.xl),
//             Expanded(
//               flex: 7,
//               child: _SecureViewerCard(
//                 study: ImagingMockData.studies[_selectedStudyIndex],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: AppSpacing.xl),
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: _ComparisonCard(
//                 selectedStudy: ImagingMockData.studies[_selectedStudyIndex],
//                 onCompare: () =>
//                     _openComparisonViewer(context, _selectedStudyIndex),
//               ),
//             ),
//             const SizedBox(width: AppSpacing.xl),
//             const Expanded(child: _DownloadPolicyCard()),
//           ],
//         ),
//       ],
//     );
//   }
// }

// AppTextKey _studyOutputLabelKey(ImagingStudy study) {
//   return switch (study.outputType) {
//     ImagingOutputType.image => AppTextKey.imagingOutputImage,
//     ImagingOutputType.report => AppTextKey.imagingOutputReport,
//     ImagingOutputType.waveform => AppTextKey.imagingOutputWaveform,
//   };
// }

// IconData _studyOutputIcon(ImagingStudy study) {
//   return switch (study.outputType) {
//     ImagingOutputType.image => Icons.image_search_outlined,
//     ImagingOutputType.report => Icons.description_outlined,
//     ImagingOutputType.waveform => Icons.show_chart_rounded,
//   };
// }

// class _ImageGalleryCard extends StatelessWidget {
//   const _ImageGalleryCard({
//     required this.selectedIndex,
//     required this.onSelected,
//   });

//   final int selectedIndex;
//   final ValueChanged<int> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.imagingGalleryTitle),
//       subtitle: context.tr(AppTextKey.imagingGallerySubtitle),
//       minHeight: _ImagingLayout.galleryMinHeight,
//       padding: EdgeInsets.zero,
//       child: Column(
//         children: [
//           SizedBox(
//             height: _ImagingLayout.galleryListHeight,
//             // Converted from ListView.separated to ListView.builder so we can
//             // supply itemExtent: fixed-height items let Flutter skip per-item
//             // layout measurement, improving scroll performance.
//             child: ListView.builder(
//               padding: EdgeInsets.zero,
//               itemCount: ImagingMockData.studies.length,
//               itemExtent:
//                   _ImagingLayout.thumbnailHeight + 1, // thumbnail + divider
//               itemBuilder: (context, index) {
//                 final isLast = index == ImagingMockData.studies.length - 1;
//                 return Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _ImageThumb(
//                       study: ImagingMockData.studies[index],
//                       selected: selectedIndex == index,
//                       onTap: () => onSelected(index),
//                     ),
//                     if (!isLast)
//                       const Divider(
//                         height: 1,
//                         thickness: 0.5,
//                         indent: AppSpacing.xl,
//                         endIndent: AppSpacing.xl,
//                       ),
//                   ],
//                 );
//               },
//             ),
//           ),
//           const _GalleryFooter(),
//         ],
//       ),
//     );
//   }
// }

// class _ImageThumb extends StatelessWidget {
//   const _ImageThumb({
//     required this.study,
//     required this.selected,
//     required this.onTap,
//   });

//   final ImagingStudy study;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final color = study.critical ? AppColors.critical : AppColors.mutedInk;

//     return Material(
//       color: selected
//           ? color.withValues(alpha: study.critical ? 0.045 : 0.035)
//           : Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: SizedBox(
//           height: _ImagingLayout.thumbnailHeight,
//           child: Row(
//             children: [
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 width: 4,
//                 margin: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
//                 decoration: BoxDecoration(
//                   color: selected ? color : Colors.transparent,
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: color.withValues(alpha: study.critical ? 0.08 : 0.05),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: color.withValues(alpha: 0.16)),
//                 ),
//                 child: Icon(study.icon, color: color, size: 16),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       context.tr(study.titleKey),
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: AppColors.ink,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.xs),
//                     Text(
//                       context.tr(study.metaKey),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: AppColors.mutedInk,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               if (study.critical)
//                 StatusBadge(
//                   label: context.tr(AppTextKey.labsRiskCritical),
//                   tone: BadgeTone.critical,
//                   icon: Icons.priority_high_rounded,
//                 )
//               else if (study.outputType != ImagingOutputType.image)
//                 StatusBadge(
//                   label: context.tr(_studyOutputLabelKey(study)),
//                   tone: BadgeTone.neutral,
//                   icon: _studyOutputIcon(study),
//                 )
//               else
//                 Icon(
//                   selected
//                       ? Icons.check_circle_outline_rounded
//                       : Icons.chevron_right_rounded,
//                   color: selected
//                       ? color
//                       : AppColors.mutedInk.withValues(alpha: 0.42),
//                 ),
//               const SizedBox(width: AppSpacing.xl),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SecureViewerCard extends StatelessWidget {
//   const _SecureViewerCard({required this.study});

//   final ImagingStudy study;

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.imagingViewerTitle),
//       subtitle: context.tr(AppTextKey.imagingViewerSubtitle),
//       minHeight: _ImagingLayout.viewerMinHeight,
//       trailing: _FullscreenBadge(
//         onPressed: () => _openFullscreenViewer(context, study),
//       ),
//       child: Column(
//         children: [
//           Container(
//             height: _ImagingLayout.previewHeight,
//             width: double.infinity,
//             padding: const EdgeInsets.all(AppSpacing.lg),
//             decoration: BoxDecoration(
//               color: AppColors.ink,
//               borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//               border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   _StudyPreview(study: study, fit: BoxFit.cover),
//                   DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.black.withValues(alpha: 0.18),
//                           Colors.transparent,
//                           Colors.black.withValues(alpha: 0.22),
//                         ],
//                       ),
//                     ),
//                   ),
//                   PositionedDirectional(
//                     top: AppSpacing.md,
//                     start: AppSpacing.md,
//                     child: StatusBadge(
//                       label: context.tr(study.titleKey),
//                       tone: BadgeTone.neutral,
//                       icon: Icons.image_search_outlined,
//                     ),
//                   ),
//                   PositionedDirectional(
//                     end: AppSpacing.md,
//                     bottom: AppSpacing.md,
//                     child: StatusBadge(
//                       label: context.tr(study.metaKey),
//                       tone: BadgeTone.neutral,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           _ViewerActionStrip(
//             onFullscreen: () => _openFullscreenViewer(context, study),
//             onCompare: () => _openComparisonViewer(
//               context,
//               ImagingMockData.studies.indexOf(study),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// void _openFullscreenViewer(BuildContext context, ImagingStudy study) {
//   showGeneralDialog<void>(
//     context: context,
//     barrierDismissible: true,
//     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
//     barrierColor: Colors.black.withValues(alpha: 0.82),
//     transitionDuration: const Duration(milliseconds: 180),
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return _FullscreenImagingViewer(study: study);
//     },
//     transitionBuilder: (context, animation, secondaryAnimation, child) {
//       return FadeTransition(
//         opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
//         child: child,
//       );
//     },
//   );
// }

// void _openComparisonViewer(BuildContext context, int selectedIndex) {
//   showGeneralDialog<void>(
//     context: context,
//     barrierDismissible: true,
//     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
//     barrierColor: Colors.black.withValues(alpha: 0.82),
//     transitionDuration: const Duration(milliseconds: 180),
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return _ComparisonViewer(initialLeftIndex: selectedIndex);
//     },
//     transitionBuilder: (context, animation, secondaryAnimation, child) {
//       return FadeTransition(
//         opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
//         child: child,
//       );
//     },
//   );
// }

// class _FullscreenBadge extends StatelessWidget {
//   const _FullscreenBadge({required this.onPressed});

//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(999),
//       onTap: onPressed,
//       child: StatusBadge(
//         label: context.tr(AppTextKey.imagingFullscreen),
//         tone: BadgeTone.neutral,
//         icon: Icons.fullscreen_rounded,
//       ),
//     );
//   }
// }

// class _StudyPreview extends StatelessWidget {
//   const _StudyPreview({required this.study, required this.fit});

//   final ImagingStudy study;
//   final BoxFit fit;

//   @override
//   Widget build(BuildContext context) {
//     if (study.outputType == ImagingOutputType.report) {
//       return _ReportPreview(study: study);
//     }
//     if (study.outputType == ImagingOutputType.waveform) {
//       return _WaveformPreview(study: study);
//     }

//     final asset = study.previewAsset;
//     if (asset == null) {
//       return const _ImageFallbackPreview();
//     }

//     return Image.asset(
//       asset,
//       fit: fit,
//       alignment: Alignment.center,
//       filterQuality: FilterQuality.high,
//       errorBuilder: (context, error, stackTrace) {
//         return const _ImageFallbackPreview();
//       },
//     );
//   }
// }

// class _ImageFallbackPreview extends StatelessWidget {
//   const _ImageFallbackPreview();

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: const BoxDecoration(color: AppColors.canvas),
//       child: Stack(
//         children: [
//           const Positioned.fill(
//             child: CustomPaint(painter: _ScanFallbackPainter()),
//           ),
//           PositionedDirectional(
//             start: AppSpacing.lg,
//             end: AppSpacing.lg,
//             bottom: AppSpacing.lg,
//             child: Container(
//               padding: const EdgeInsets.all(AppSpacing.md),
//               decoration: BoxDecoration(
//                 color: AppColors.surface.withValues(alpha: 0.92),
//                 borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//                 border: Border.all(color: AppColors.borderFaint),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.info_outline_rounded,
//                     color: AppColors.mutedInk,
//                     size: 18,
//                   ),
//                   const SizedBox(width: AppSpacing.sm),
//                   Expanded(
//                     child: Text(
//                       context.tr(AppTextKey.imagingNoImageFallback),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: AppColors.mutedInk,
//                         height: 1.4,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ReportPreview extends StatelessWidget {
//   const _ReportPreview({required this.study});

//   final ImagingStudy study;

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: const BoxDecoration(color: AppColors.canvas),
//       child: Padding(
//         padding: const EdgeInsets.all(AppSpacing.xl),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _PreviewHeader(
//               icon: _studyOutputIcon(study),
//               title: context.tr(AppTextKey.imagingReportPreviewTitle),
//               subtitle: context.tr(study.metaKey),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//             Expanded(
//               child: ListView.separated(
//                 padding: EdgeInsets.zero,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: study.reportLineKeys.length,
//                 separatorBuilder: (context, index) =>
//                     const SizedBox(height: AppSpacing.md),
//                 itemBuilder: (context, index) {
//                   return _ReportLine(
//                     label: context.tr(study.reportLineKeys[index]),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ReportLine extends StatelessWidget {
//   const _ReportLine({required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.check_circle_outline_rounded,
//             color: AppColors.mutedInk,
//             size: 20,
//           ),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Text(
//               label,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: AppColors.ink,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _WaveformPreview extends StatelessWidget {
//   const _WaveformPreview({required this.study});

//   final ImagingStudy study;

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: const BoxDecoration(color: AppColors.canvas),
//       child: Padding(
//         padding: const EdgeInsets.all(AppSpacing.xl),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _PreviewHeader(
//               icon: _studyOutputIcon(study),
//               title: context.tr(AppTextKey.imagingWaveformPreviewTitle),
//               subtitle: context.tr(study.metaKey),
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             Expanded(
//               child: DecoratedBox(
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//                   border: Border.all(color: AppColors.borderFaint),
//                 ),
//                 child: CustomPaint(
//                   painter: _WaveformPainter(
//                     color: study.outputType == ImagingOutputType.waveform
//                         ? AppColors.mutedInk
//                         : AppColors.primary,
//                   ),
//                   child: const SizedBox.expand(),
//                 ),
//               ),
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             Wrap(
//               spacing: AppSpacing.sm,
//               runSpacing: AppSpacing.sm,
//               children: [
//                 for (final lineKey in study.reportLineKeys)
//                   StatusBadge(
//                     label: context.tr(lineKey),
//                     tone: BadgeTone.neutral,
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PreviewHeader extends StatelessWidget {
//   const _PreviewHeader({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 42,
//           height: 42,
//           decoration: BoxDecoration(
//             color: AppColors.mutedInk.withValues(alpha: 0.07),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(
//               color: AppColors.mutedInk.withValues(alpha: 0.13),
//             ),
//           ),
//           child: Icon(icon, color: AppColors.mutedInk, size: 20),
//         ),
//         const SizedBox(width: AppSpacing.md),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: AppColors.ink,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               const SizedBox(height: AppSpacing.xs),
//               Text(
//                 subtitle,
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _WaveformPainter extends CustomPainter {
//   const _WaveformPainter({required this.color});

//   final Color color;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final gridPaint = Paint()
//       ..color = AppColors.border.withValues(alpha: 0.5)
//       ..strokeWidth = 1;
//     final linePaint = Paint()
//       ..color = color
//       ..strokeWidth = 2.2
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     for (var i = 1; i < 6; i++) {
//       final y = size.height * (i / 6);
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }
//     for (var i = 1; i < 10; i++) {
//       final x = size.width * (i / 10);
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }

//     final baseline = size.height * 0.54;
//     final path = Path()..moveTo(0, baseline);
//     for (var i = 0; i <= 80; i++) {
//       final t = i / 80;
//       final x = size.width * t;
//       final spike = (i % 18 == 0)
//           ? -size.height * 0.30
//           : (i % 18 == 1)
//           ? size.height * 0.20
//           : 0.0;
//       final wave = math.sin(t * math.pi * 10) * size.height * 0.05;
//       path.lineTo(x, baseline + wave + spike);
//     }
//     canvas.drawPath(path, linePaint);
//   }

//   @override
//   bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
//     return oldDelegate.color != color;
//   }
// }

// class _ViewerActionStrip extends StatelessWidget {
//   const _ViewerActionStrip({
//     required this.onFullscreen,
//     required this.onCompare,
//   });

//   final VoidCallback onFullscreen;
//   final VoidCallback onCompare;

//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       (
//         Icons.fullscreen_rounded,
//         context.tr(AppTextKey.imagingFullscreen),
//         AppColors.mutedInk,
//         onFullscreen,
//       ),
//       (
//         Icons.compare_outlined,
//         context.tr(AppTextKey.imagingCompare),
//         AppColors.mutedInk,
//         onCompare,
//       ),
//       (
//         Icons.lock_outline,
//         context.tr(AppTextKey.imagingDownload),
//         AppColors.mutedInk,
//         null,
//       ),
//     ];

//     return SizedBox(
//       height: _ImagingLayout.statusPanelHeight,
//       child: Row(
//         children: [
//           for (int i = 0; i < items.length; i++) ...[
//             Expanded(
//               child: _ViewerActionTile(
//                 icon: items[i].$1,
//                 label: items[i].$2,
//                 color: items[i].$3,
//                 onTap: items[i].$4,
//               ),
//             ),
//             if (i < items.length - 1) const SizedBox(width: AppSpacing.md),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _ViewerActionTile extends StatelessWidget {
//   const _ViewerActionTile({
//     required this.icon,
//     required this.label,
//     required this.color,
//     this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: color.withValues(alpha: 0.05),
//       borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         onTap: onTap,
//         child: Container(
//           height: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//             border: Border.all(color: color.withValues(alpha: 0.13)),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, color: color, size: 21),
//               const SizedBox(width: AppSpacing.md),
//               Expanded(
//                 child: Text(
//                   label,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w800,
//                     height: 1.25,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FullscreenImagingViewer extends StatefulWidget {
//   const _FullscreenImagingViewer({required this.study});

//   final ImagingStudy study;

//   @override
//   State<_FullscreenImagingViewer> createState() =>
//       _FullscreenImagingViewerState();
// }

// class _FullscreenImagingViewerState extends State<_FullscreenImagingViewer> {
//   static const double _minScale = 0.75;
//   static const double _maxScale = 8;
//   static const double _scaleStep = 1.35;

//   final TransformationController _controller = TransformationController();

//   // Internal double for clamp calculations (no build dependency)
//   double _scale = 1.0;

//   // ValueNotifier: only the zoom badge rebuilds when scale changes —
//   // the Scaffold, AppBar, and InteractiveViewer are never touched.
//   late final ValueNotifier<double> _scaleNotifier;

//   @override
//   void initState() {
//     super.initState();
//     _scaleNotifier = ValueNotifier(1.0);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scaleNotifier.dispose();
//     super.dispose();
//   }

//   void _setScale(double value) {
//     final next = value.clamp(_minScale, _maxScale).toDouble();
//     _scale = next;
//     _scaleNotifier.value = next;
//     _controller.value = Matrix4.diagonal3Values(next, next, 1);
//     // No setState — only the zoom badge needs to update
//   }

//   void _zoomIn() => _setScale(_scale * _scaleStep);

//   void _zoomOut() => _setScale(_scale / _scaleStep);

//   void _resetZoom() => _setScale(1);

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: AppColors.ink,
//       child: SafeArea(
//         child: Column(
//           children: [
//             _FullscreenTopBar(
//               study: widget.study,
//               scaleListenable: _scaleNotifier,
//               onClose: () => Navigator.of(context).pop(),
//               onZoomIn: _zoomIn,
//               onZoomOut: _zoomOut,
//               onReset: _resetZoom,
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(
//                   AppSpacing.xl,
//                   AppSpacing.md,
//                   AppSpacing.xl,
//                   AppSpacing.xl,
//                 ),
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//                     border: Border.all(
//                       color: Colors.white.withValues(alpha: 0.12),
//                     ),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//                     child: InteractiveViewer(
//                       transformationController: _controller,
//                       minScale: _minScale,
//                       maxScale: _maxScale,
//                       boundaryMargin: const EdgeInsets.all(220),
//                       panEnabled: true,
//                       scaleEnabled: true,
//                       clipBehavior: Clip.none,
//                       onInteractionUpdate: (_) {
//                         final current = _controller.value.getMaxScaleOnAxis();
//                         if ((current - _scale).abs() > 0.01) {
//                           _scale = current;
//                           _scaleNotifier.value = current;
//                           // No setState — gesture updates only the zoom badge
//                         }
//                       },
//                       child: SizedBox.expand(
//                         child: _StudyPreview(
//                           study: widget.study,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _FullscreenTopBar extends StatelessWidget {
//   const _FullscreenTopBar({
//     required this.study,
//     required this.scaleListenable,
//     required this.onClose,
//     required this.onZoomIn,
//     required this.onZoomOut,
//     required this.onReset,
//   });

//   final ImagingStudy study;
//   final ValueListenable<double> scaleListenable;
//   final VoidCallback onClose;
//   final VoidCallback onZoomIn;
//   final VoidCallback onZoomOut;
//   final VoidCallback onReset;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.xl,
//         AppSpacing.lg,
//         AppSpacing.xl,
//         AppSpacing.sm,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.08),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
//             ),
//             child: Icon(study.icon, color: Colors.white, size: 22),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(study.titleKey),
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.xs),
//                 Text(
//                   context.tr(study.metaKey),
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: Colors.white.withValues(alpha: 0.62),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _FullscreenControlButton(
//             icon: Icons.remove_rounded,
//             onPressed: onZoomOut,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _ZoomLevelBadge(scaleListenable: scaleListenable),
//           const SizedBox(width: AppSpacing.sm),
//           _FullscreenControlButton(
//             icon: Icons.add_rounded,
//             onPressed: onZoomIn,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _FullscreenControlButton(
//             icon: Icons.center_focus_strong_rounded,
//             onPressed: onReset,
//           ),
//           const SizedBox(width: AppSpacing.md),
//           _FullscreenControlButton(
//             icon: Icons.close_rounded,
//             onPressed: onClose,
//             critical: true,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ZoomLevelBadge extends StatelessWidget {
//   const _ZoomLevelBadge({required this.scaleListenable});

//   final ValueListenable<double> scaleListenable;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 64,
//       height: 40,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
//       ),
//       // ValueListenableBuilder: only the Text inside rebuilds on zoom change
//       child: ValueListenableBuilder<double>(
//         valueListenable: scaleListenable,
//         builder: (context, scale, _) => Text(
//           '${(scale * 100).round()}%',
//           style: Theme.of(context).textTheme.labelMedium?.copyWith(
//             color: Colors.white,
//             fontWeight: FontWeight.w900,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FullscreenControlButton extends StatelessWidget {
//   const _FullscreenControlButton({
//     required this.icon,
//     required this.onPressed,
//     this.critical = false,
//   });

//   final IconData icon;
//   final VoidCallback onPressed;
//   final bool critical;

//   @override
//   Widget build(BuildContext context) {
//     final color = critical ? AppColors.critical : Colors.white;
//     return SizedBox(
//       width: 40,
//       height: 40,
//       child: IconButton(
//         onPressed: onPressed,
//         icon: Icon(icon, color: color, size: 20),
//         style: IconButton.styleFrom(
//           backgroundColor: color.withValues(alpha: critical ? 0.14 : 0.08),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(999),
//             side: BorderSide(color: color.withValues(alpha: 0.14)),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ScanFallbackPainter extends CustomPainter {
//   const _ScanFallbackPainter();

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final gridPaint = Paint()
//       ..color = AppColors.border.withValues(alpha: 0.42)
//       ..strokeWidth = 1;
//     final bodyPaint = Paint()
//       ..color = AppColors.mutedInk.withValues(alpha: 0.13)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;
//     final axisPaint = Paint()
//       ..color = AppColors.primary.withValues(alpha: 0.28)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.6
//       ..strokeCap = StrokeCap.round;
//     final focusPaint = Paint()
//       ..color = AppColors.critical.withValues(alpha: 0.56)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.2
//       ..strokeCap = StrokeCap.round;

//     for (var i = 1; i < 4; i++) {
//       final x = size.width * (i / 4);
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }
//     for (var i = 1; i < 3; i++) {
//       final y = size.height * (i / 3);
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }

//     canvas.drawOval(
//       Rect.fromCenter(
//         center: center,
//         width: size.width * 0.42,
//         height: size.height * 0.66,
//       ),
//       bodyPaint,
//     );
//     canvas.drawLine(
//       Offset(size.width * 0.18, center.dy),
//       Offset(size.width * 0.82, center.dy),
//       axisPaint,
//     );
//     canvas.drawLine(
//       Offset(center.dx, size.height * 0.18),
//       Offset(center.dx, size.height * 0.82),
//       axisPaint,
//     );
//     for (var i = 1; i <= 3; i++) {
//       canvas.drawCircle(center, size.shortestSide * (0.085 * i), bodyPaint);
//     }

//     final focusRect = Rect.fromCenter(
//       center: Offset(size.width * 0.58, size.height * 0.44),
//       width: size.width * 0.13,
//       height: size.height * 0.16,
//     );
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(focusRect, const Radius.circular(12)),
//       focusPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class _ComparisonViewer extends StatefulWidget {
//   const _ComparisonViewer({required this.initialLeftIndex});

//   final int initialLeftIndex;

//   @override
//   State<_ComparisonViewer> createState() => _ComparisonViewerState();
// }

// class _ComparisonViewerState extends State<_ComparisonViewer> {
//   static const double _minScale = 0.75;
//   static const double _maxScale = 6;
//   static const double _scaleStep = 1.25;

//   late int _leftIndex;
//   late int _rightIndex;
//   final TransformationController _leftController = TransformationController();
//   final TransformationController _rightController = TransformationController();

//   // Internal double for clamp calculations
//   double _scale = 1.0;

//   // ValueNotifier: only the zoom badge rebuilds on scale change
//   late final ValueNotifier<double> _scaleNotifier;

//   @override
//   void initState() {
//     super.initState();
//     _leftIndex = widget.initialLeftIndex;
//     _rightIndex = _leftIndex == 0 ? 1 : 0;
//     _scaleNotifier = ValueNotifier(1.0);
//   }

//   @override
//   void dispose() {
//     _leftController.dispose();
//     _rightController.dispose();
//     _scaleNotifier.dispose();
//     super.dispose();
//   }

//   void _setScale(double value) {
//     final next = value.clamp(_minScale, _maxScale).toDouble();
//     _scale = next;
//     _scaleNotifier.value = next;
//     _leftController.value = Matrix4.diagonal3Values(next, next, 1);
//     _rightController.value = Matrix4.diagonal3Values(next, next, 1);
//     // No setState — only the zoom badge needs to update
//   }

//   void _zoomIn() => _setScale(_scale * _scaleStep);

//   void _zoomOut() => _setScale(_scale / _scaleStep);

//   void _resetZoom() => _setScale(1);

//   void _swapStudies() {
//     setState(() {
//       final previousLeft = _leftIndex;
//       _leftIndex = _rightIndex;
//       _rightIndex = previousLeft;
//     });
//   }

//   void _selectLeft(int index) {
//     if (index == _rightIndex) return;
//     setState(() => _leftIndex = index);
//   }

//   void _selectRight(int index) {
//     if (index == _leftIndex) return;
//     setState(() => _rightIndex = index);
//   }

//   void _trackScale(TransformationController controller) {
//     final current = controller.value.getMaxScaleOnAxis();
//     if ((current - _scale).abs() > 0.01) {
//       _scale = current;
//       _scaleNotifier.value = current;
//       // No setState — gesture updates only the zoom badge
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final leftStudy = ImagingMockData.studies[_leftIndex];
//     final rightStudy = ImagingMockData.studies[_rightIndex];

//     return Material(
//       color: AppColors.ink,
//       child: SafeArea(
//         child: Column(
//           children: [
//             _ComparisonTopBar(
//               scaleListenable: _scaleNotifier,
//               onClose: () => Navigator.of(context).pop(),
//               onZoomIn: _zoomIn,
//               onZoomOut: _zoomOut,
//               onReset: _resetZoom,
//               onSwap: _swapStudies,
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: _ComparisonStudySelector(
//                       label: 'A',
//                       selectedIndex: _leftIndex,
//                       blockedIndex: _rightIndex,
//                       onSelected: _selectLeft,
//                     ),
//                   ),
//                   const SizedBox(width: AppSpacing.xl),
//                   Expanded(
//                     child: _ComparisonStudySelector(
//                       label: 'B',
//                       selectedIndex: _rightIndex,
//                       blockedIndex: _leftIndex,
//                       onSelected: _selectRight,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(
//                   AppSpacing.xl,
//                   0,
//                   AppSpacing.xl,
//                   AppSpacing.xl,
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: _ComparisonStudyPanel(
//                         label: 'A',
//                         study: leftStudy,
//                         controller: _leftController,
//                         minScale: _minScale,
//                         maxScale: _maxScale,
//                         onInteractionUpdate: () => _trackScale(_leftController),
//                       ),
//                     ),
//                     const SizedBox(width: AppSpacing.xl),
//                     Expanded(
//                       child: _ComparisonStudyPanel(
//                         label: 'B',
//                         study: rightStudy,
//                         controller: _rightController,
//                         minScale: _minScale,
//                         maxScale: _maxScale,
//                         onInteractionUpdate: () =>
//                             _trackScale(_rightController),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ComparisonTopBar extends StatelessWidget {
//   const _ComparisonTopBar({
//     required this.scaleListenable,
//     required this.onClose,
//     required this.onZoomIn,
//     required this.onZoomOut,
//     required this.onReset,
//     required this.onSwap,
//   });

//   final ValueListenable<double> scaleListenable;
//   final VoidCallback onClose;
//   final VoidCallback onZoomIn;
//   final VoidCallback onZoomOut;
//   final VoidCallback onReset;
//   final VoidCallback onSwap;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.xl,
//         AppSpacing.lg,
//         AppSpacing.xl,
//         AppSpacing.md,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.08),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
//             ),
//             child: const Icon(
//               Icons.compare_arrows_rounded,
//               color: Colors.white,
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Text(
//               context.tr(AppTextKey.imagingCompare),
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ),
//           _FullscreenControlButton(
//             icon: Icons.remove_rounded,
//             onPressed: onZoomOut,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _ZoomLevelBadge(scaleListenable: scaleListenable),
//           const SizedBox(width: AppSpacing.sm),
//           _FullscreenControlButton(
//             icon: Icons.add_rounded,
//             onPressed: onZoomIn,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _FullscreenControlButton(
//             icon: Icons.center_focus_strong_rounded,
//             onPressed: onReset,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           _FullscreenControlButton(
//             icon: Icons.swap_horiz_rounded,
//             onPressed: onSwap,
//           ),
//           const SizedBox(width: AppSpacing.md),
//           _FullscreenControlButton(
//             icon: Icons.close_rounded,
//             onPressed: onClose,
//             critical: true,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ComparisonStudySelector extends StatelessWidget {
//   const _ComparisonStudySelector({
//     required this.label,
//     required this.selectedIndex,
//     required this.blockedIndex,
//     required this.onSelected,
//   });

//   final String label;
//   final int selectedIndex;
//   final int blockedIndex;
//   final ValueChanged<int> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.sm),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.06),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.10),
//               shape: BoxShape.circle,
//             ),
//             child: Text(
//               label,
//               style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   for (int i = 0; i < ImagingMockData.studies.length; i++) ...[
//                     SizedBox(
//                       width: 154,
//                       child: _ComparisonStudyChip(
//                         study: ImagingMockData.studies[i],
//                         selected: selectedIndex == i,
//                         disabled: blockedIndex == i,
//                         onTap: () => onSelected(i),
//                       ),
//                     ),
//                     if (i < ImagingMockData.studies.length - 1)
//                       const SizedBox(width: AppSpacing.sm),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ComparisonStudyChip extends StatelessWidget {
//   const _ComparisonStudyChip({
//     required this.study,
//     required this.selected,
//     required this.disabled,
//     required this.onTap,
//   });

//   final ImagingStudy study;
//   final bool selected;
//   final bool disabled;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final color = study.critical ? AppColors.critical : Colors.white;
//     return Material(
//       color: selected
//           ? color.withValues(alpha: study.critical ? 0.16 : 0.12)
//           : Colors.transparent,
//       borderRadius: BorderRadius.circular(999),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(999),
//         onTap: disabled ? null : onTap,
//         child: Container(
//           height: 34,
//           alignment: Alignment.center,
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(999),
//             border: Border.all(
//               color: selected
//                   ? color.withValues(alpha: 0.32)
//                   : Colors.white.withValues(alpha: 0.09),
//             ),
//           ),
//           child: Text(
//             context.tr(study.titleKey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: disabled
//                   ? Colors.white.withValues(alpha: 0.32)
//                   : Colors.white.withValues(alpha: selected ? 0.96 : 0.68),
//               fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ComparisonStudyPanel extends StatelessWidget {
//   const _ComparisonStudyPanel({
//     required this.label,
//     required this.study,
//     required this.controller,
//     required this.minScale,
//     required this.maxScale,
//     required this.onInteractionUpdate,
//   });

//   final String label;
//   final ImagingStudy study;
//   final TransformationController controller;
//   final double minScale;
//   final double maxScale;
//   final VoidCallback onInteractionUpdate;

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: InteractiveViewer(
//                 transformationController: controller,
//                 minScale: minScale,
//                 maxScale: maxScale,
//                 boundaryMargin: const EdgeInsets.all(180),
//                 panEnabled: true,
//                 scaleEnabled: true,
//                 clipBehavior: Clip.none,
//                 onInteractionUpdate: (_) => onInteractionUpdate(),
//                 child: SizedBox.expand(
//                   child: _StudyPreview(study: study, fit: BoxFit.contain),
//                 ),
//               ),
//             ),
//             PositionedDirectional(
//               top: AppSpacing.md,
//               start: AppSpacing.md,
//               child: _ComparisonPanelLabel(label: label, study: study),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ComparisonPanelLabel extends StatelessWidget {
//   const _ComparisonPanelLabel({required this.label, required this.study});

//   final String label;
//   final ImagingStudy study;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsetsDirectional.fromSTEB(
//         AppSpacing.sm,
//         AppSpacing.xs,
//         AppSpacing.md,
//         AppSpacing.xs,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.ink.withValues(alpha: 0.78),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 22,
//             height: 22,
//             alignment: Alignment.center,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//             child: Text(
//               label,
//               style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                 color: AppColors.ink,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Text(
//             context.tr(study.titleKey),
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _GalleryFooter extends StatelessWidget {
//   const _GalleryFooter();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(
//         AppSpacing.xl,
//         AppSpacing.lg,
//         AppSpacing.xl,
//         AppSpacing.xl,
//       ),
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       decoration: BoxDecoration(
//         color: AppColors.canvas.withValues(alpha: 0.72),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: AppColors.borderFaint),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.shield_outlined, color: AppColors.mutedInk, size: 22),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Text(
//               context.tr(AppTextKey.imagingPolicyBody),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: AppColors.mutedInk,
//                 height: 1.45,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ComparisonCard extends StatelessWidget {
//   const _ComparisonCard({required this.selectedStudy, required this.onCompare});

//   final ImagingStudy selectedStudy;
//   final VoidCallback onCompare;

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.imagingComparisonTitle),
//       minHeight: _ImagingLayout.bottomCardMinHeight,
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Material(
//             color: AppColors.mutedInk.withValues(alpha: 0.06),
//             borderRadius: BorderRadius.circular(15),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(15),
//               onTap: onCompare,
//               child: Container(
//                 width: 42,
//                 height: 42,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(
//                     color: AppColors.mutedInk.withValues(alpha: 0.13),
//                   ),
//                 ),
//                 child: const Icon(
//                   Icons.compare_outlined,
//                   color: AppColors.mutedInk,
//                   size: 22,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: AppSpacing.lg),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 InkWell(
//                   borderRadius: BorderRadius.circular(999),
//                   onTap: onCompare,
//                   child: StatusBadge(
//                     label: context.tr(AppTextKey.imagingCompare),
//                     tone: BadgeTone.neutral,
//                     icon: Icons.swap_horiz_rounded,
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.md),
//                 Text(
//                   context.tr(selectedStudy.titleKey),
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.xs),
//                 Text(
//                   context.tr(AppTextKey.imagingComparisonBody),
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.mutedInk,
//                     height: 1.55,
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

// class _DownloadPolicyCard extends StatelessWidget {
//   const _DownloadPolicyCard();

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       title: context.tr(AppTextKey.imagingPolicyTitle),
//       minHeight: _ImagingLayout.bottomCardMinHeight,
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: AppColors.mutedInk.withValues(alpha: 0.06),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: AppColors.mutedInk.withValues(alpha: 0.13),
//               ),
//             ),
//             child: const Icon(
//               Icons.lock_outline,
//               color: AppColors.mutedInk,
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: AppSpacing.lg),
//           Expanded(
//             child: Text(
//               context.tr(AppTextKey.imagingPolicyBody),
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: AppColors.mutedInk,
//                 height: 1.55,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
