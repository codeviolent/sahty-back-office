import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/status_badge.dart';
import '../router/app_route.dart';

// ─────────────────────────────────────────────────────────────────────────────

class BackOfficeShell extends StatefulWidget {
  const BackOfficeShell({
    super.key,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.child,
    required this.visibleRoutes,
  });

  final AppRoute selectedRoute;
  final ValueChanged<AppRoute> onRouteSelected;
  final Widget child;
  final List<AppRoute> visibleRoutes;

  @override
  State<BackOfficeShell> createState() => _BackOfficeShellState();
}

class _BackOfficeShellState extends State<BackOfficeShell> {
  bool _profilePanelVisible = true;

  void _toggleProfilePanel() {
    setState(() => _profilePanelVisible = !_profilePanelVisible);
  }

  @override
  Widget build(BuildContext context) {
    final canShowRightPanel =
        widget.selectedRoute.section != AppSection.security;
    final showRightPanel = canShowRightPanel && _profilePanelVisible;

    return Scaffold(
      body: _LuxuryCanvas(
        child: Row(
          children: [
            _Sidebar(
              selectedRoute: widget.selectedRoute,
              onRouteSelected: widget.onRouteSelected,
              visibleRoutes: widget.visibleRoutes,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.shellInset,
                  AppSpacing.shellInset,
                  AppSpacing.shellInset,
                ),
                child: GlassPanel(
                  radius: AppSpacing.panelRadius,
                  color: AppColors.surface,
                  blur: 0,
                  borderColor: AppColors.borderFaint,
                  shadows: AppColors.floatingShadow,
                  child: Column(
                    children: [
                      _TopBar(
                        profilePanelVisible: showRightPanel,
                        onProfilePressed: canShowRightPanel
                            ? _toggleProfilePanel
                            : null,
                      ),
                      const Divider(),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Each screen owns its scroll via IndexedStack wrapper.
                            // SingleChildScrollView removed from shell to eliminate
                            // a shared scroll that caused cross-screen layout overhead.
                            Expanded(child: widget.child),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: showRightPanel
                                  ? const _RightContextPanel(
                                      key: ValueKey('right-profile-panel'),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('right-profile-hidden'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _LuxuryCanvas extends StatelessWidget {
  const _LuxuryCanvas({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas,
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -90,
            start: 110,
            child: _AmbientSpot(
              color: AppColors.surface,
              size: 280,
              opacity: 0.45,
            ),
          ),
          PositionedDirectional(
            bottom: -120,
            end: -30,
            child: _AmbientSpot(
              color: AppColors.primary,
              size: 320,
              opacity: 0.055,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AmbientSpot extends StatelessWidget {
  const _AmbientSpot({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
//
// Animates between collapsed (64 px — icon only) and expanded (220 px — icon +
// label) using a dedicated AnimationController for ultra-smooth behaviour.
//
// Three independent sub-animations driven by the same controller:
//   _width      → sidebar width    (ease-out expand / ease-in collapse)
//   _textFade   → label opacity    (delayed fade-in / quick fade-out)
//   _sectionH   → section-label ht (delayed grow / quick shrink)

class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.visibleRoutes,
  });

  final AppRoute selectedRoute;
  final ValueChanged<AppRoute> onRouteSelected;
  final List<AppRoute> visibleRoutes;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar>
    with SingleTickerProviderStateMixin {
  // ─────────────────────────────────────────────────────────────
  // Sidebar animation strategy
  //
  // Uses AnimationController.animateTo() — battle-tested, interrupt-safe,
  // and correctly handles mid-animation reversals (starts from current
  // value, not from 0 or 1).
  //
  // Expand: 300 ms, easeOutCubic   — fast start, silky arrival
  // Collapse: 220 ms, easeInOutCubic — snappier close
  //
  // Three sub-animations driven by the same controller:
  //   width      → sidebar pixel width (outer AnimatedBuilder.builder only)
  //   _textFade  → label opacity (inner AnimatedBuilders per widget)
  //   _sectionH  → section-label height (inner AnimatedBuilders per item)
  //
  // Performance strategy:
  //   • _sections map is precomputed — never rebuilt per animation frame
  //   • _sidebarDecoration is precomputed — no BoxDecoration allocation per frame
  //   • AnimatedBuilder.child carries the static structure (ClipRRect, shadow)
  //     so only the SizedBox width is rebuilt by the outer builder each frame
  //   • Each child widget subscribes to its own Animation<double> internally
  // ─────────────────────────────────────────────────────────────

  late final AnimationController _ctrl;
  late final Animation<double> _textFade;
  late final Animation<double> _sectionH;
  late final BoxDecoration _sidebarDecoration;

  // Precomputed sections — rebuilt only when visibleRoutes reference changes,
  // never on every animation frame.
  Map<AppSection, List<AppRoute>> _sections = {};

  // Icon column: always 44 px regardless of sidebar state
  static const double _iconColW = AppSpacing.sidebarCollapsedWidth - 18;

  @override
  void initState() {
    super.initState();
    _rebuildSections();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );

    // Text fades in only after sidebar is ~45% expanded.
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.22, curve: Curves.easeIn),
    );

    // Section label height grows after width is established.
    _sectionH = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.93, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.32, curve: Curves.easeIn),
    );

    // Precompute decoration once — avoids allocating BoxDecoration + BoxShadow
    // list on every animation frame (was happening 60×/sec on hover).
    _sidebarDecoration = BoxDecoration(
      color: AppColors.sidebar,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.sidebar.withValues(alpha: 0.40),
          blurRadius: 28,
          offset: const Offset(4, 10),
        ),
        BoxShadow(
          color: AppColors.sidebar.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(_Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibleRoutes != widget.visibleRoutes) {
      _rebuildSections();
    }
  }

  // Rebuilds the sections map from the current visibleRoutes.
  // Called once on init and only when visibleRoutes actually changes —
  // never per animation frame.
  void _rebuildSections() {
    final map = <AppSection, List<AppRoute>>{};
    for (final route in widget.visibleRoutes) {
      map.putIfAbsent(route.section, () => []).add(route);
    }
    _sections = map;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Hover handlers ────────────────────────────────────────────
  //
  // animateTo starts from the current controller value — so if the user
  // moves the mouse out while the sidebar is half-expanded, the collapse
  // begins from that exact position, not from 1.0.

  void _onEnter(_) => _ctrl.animateTo(
    1.0,
    duration: Duration(
      milliseconds: (300 * (1.0 - _ctrl.value)).round().clamp(80, 300),
    ),
    curve: Curves.easeOutCubic,
  );

  void _onExit(_) => _ctrl.animateTo(
    0.0,
    duration: Duration(
      milliseconds: (220 * _ctrl.value).round().clamp(60, 220),
    ),
    curve: Curves.easeInOutCubic,
  );

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: AnimatedBuilder(
        animation: _ctrl,
        // ── Static child ────────────────────────────────────────
        // Built once per widget configuration, NOT on every animation frame.
        // The shadow, clip, and inner widgets live here.
        // Each inner widget subscribes to _textFade / _sectionH independently.
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              // RepaintBoundary isolates the sidebar's raster layer so the
              // GPU does not re-composite the surrounding canvas on hover.
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: _sidebarDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarBrand(iconColW: _iconColW, textFade: _textFade),
                      Expanded(
                        child: _SidebarRouteList(
                          sections: _sections,
                          selectedRoute: widget.selectedRoute,
                          onRouteSelected: widget.onRouteSelected,
                          textFade: _textFade,
                          sectionH: _sectionH,
                          iconColW: _iconColW,
                        ),
                      ),
                      _SidebarFooter(iconColW: _iconColW, textFade: _textFade),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Width-only builder ──────────────────────────────────
        // Runs every animation frame but only constructs a SizedBox —
        // the expensive child subtree is passed through unchanged.
        builder: (context, child) {
          final sideW =
              AppSpacing.sidebarCollapsedWidth +
              _ctrl.value *
                  (AppSpacing.sidebarExpandedWidth -
                      AppSpacing.sidebarCollapsedWidth);
          return SizedBox(width: sideW, child: child);
        },
      ),
    );
  }
}

// ── Sidebar Brand ─────────────────────────────────────────────────────────────

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.iconColW, required this.textFade});

  final double iconColW;
  final Animation<double> textFade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // Icon stays at the same x-position in both collapsed / expanded
          SizedBox(
            width: iconColW,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (context) => const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          // Text fades in when sidebar expands — AnimatedBuilder subscribes
          // to textFade independently so the icon column is never rebuilt.
          Expanded(
            child: AnimatedBuilder(
              animation: textFade,
              builder: (context, child) {
                final op = textFade.value;
                if (op <= 0) return const SizedBox.shrink();
                return Opacity(opacity: op, child: child);
              },
              child: const Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sahty',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Back Office',
                      style: TextStyle(
                        color: AppColors.sidebarMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar Item ──────────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.route,
    required this.isSelected,
    required this.onTap,
    required this.textFade,
    required this.iconColW,
  });

  final AppRoute route;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double> textFade;
  final double iconColW;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      // AnimatedBuilder subscribes to textFade — only the label area
      // updates when opacity changes, not the Material/InkWell structure.
      child: AnimatedBuilder(
        animation: textFade,
        builder: (context, child) {
          final textOp = textFade.value;
          return Tooltip(
            message: textOp < 0.3 ? context.tr(route.titleKey) : '',
            preferBelow: false,
            child: Material(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: onTap,
                hoverColor: Colors.white.withValues(alpha: 0.08),
                child: SizedBox(
                  height: 34,
                  child: Row(
                    children: [
                      // Fixed-position icon — never moves between states
                      SizedBox(
                        width: iconColW,
                        child: Center(
                          child: Icon(
                            route.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.sidebarMuted,
                          ),
                        ),
                      ),
                      // Label appears as the sidebar expands
                      if (textOp > 0) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Opacity(
                            opacity: textOp,
                            child: Text(
                              context.tr(route.titleKey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.sidebarMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Sidebar Footer ────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.iconColW, required this.textFade});

  final double iconColW;
  final Animation<double> textFade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: iconColW,
            child: Center(
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: const Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: textFade,
              builder: (context, child) {
                final op = textFade.value;
                if (op <= 0) return const SizedBox.shrink();
                return Opacity(opacity: op, child: child);
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: Text(
                  context.tr(AppTextKey.doctorName),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.sidebarMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: textFade,
            builder: (context, child) {
              final op = textFade.value;
              if (op <= 0) return const SizedBox.shrink();
              return Opacity(opacity: op, child: child);
            },
            child: const Padding(
              padding: EdgeInsetsDirectional.only(end: 8),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.sidebarMuted,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar Route List ────────────────────────────────────────────────────────
//
// Renders sections and routes using ListView.builder for lazy item
// construction. Each section label subscribes to sectionH independently;
// each route item subscribes to textFade independently — so only the
// widgets that actually changed repaint.

class _SidebarRouteList extends StatelessWidget {
  const _SidebarRouteList({
    required this.sections,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.textFade,
    required this.sectionH,
    required this.iconColW,
  });

  final Map<AppSection, List<AppRoute>> sections;
  final AppRoute selectedRoute;
  final ValueChanged<AppRoute> onRouteSelected;
  final Animation<double> textFade;
  final Animation<double> sectionH;
  final double iconColW;

  @override
  Widget build(BuildContext context) {
    final entries = sections.entries.toList(growable: false);
    // Opacity animation derived from sectionH: full opacity reached at 40%
    // of the expand animation. FadeTransition avoids a compositing layer at
    // opacity=1, unlike Opacity which always creates one.
    final sectionFade = sectionH.drive(
      CurveTween(curve: const Interval(0.0, 0.4)),
    );
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return const SizedBox(height: AppSpacing.md);
        }
        final entry = entries[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: index == 0 ? AppSpacing.sm : AppSpacing.lg),
            // Height driven by AnimatedBuilder.builder; opacity driven by
            // FadeTransition directly — no compositing layer at full opacity.
            AnimatedBuilder(
              animation: sectionH,
              child: FadeTransition(
                opacity: sectionFade,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: iconColW + 6),
                  child: Text(
                    context.tr(entry.key.titleKey).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: AppColors.sidebarMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              builder: (context, child) {
                final h = sectionH.value;
                if (h <= 0) return const SizedBox.shrink();
                return SizedBox(height: h * 16.0, child: child);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final route in entry.value)
              _SidebarItem(
                route: route,
                isSelected: route == selectedRoute,
                onTap: () => onRouteSelected(route),
                textFade: textFade,
                iconColW: iconColW,
              ),
          ],
        );
      },
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.profilePanelVisible,
    required this.onProfilePressed,
  });

  final bool profilePanelVisible;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 620;

            return Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: context.tr(AppTextKey.quickSearchHint),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      constraints: const BoxConstraints(maxHeight: 36),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (wide) ...[
                  Flexible(
                    child: StatusBadge(
                      label: context.tr(AppTextKey.secureSession),
                      tone: BadgeTone.normal,
                      icon: Icons.shield_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                _LocaleBtn(
                  label: context.tr(AppTextKey.langFr),
                  active: context.appLocale == AppLocale.fr,
                  onTap: () => context.setAppLocale(AppLocale.fr),
                ),
                _LocaleBtn(
                  label: context.tr(AppTextKey.langAr),
                  active: context.appLocale == AppLocale.ar,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "L'application est entièrement prête pour la traduction, mais l'arabe n'a pas encore été ajouté.",
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: context.tr(AppTextKey.notificationTooltip),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(AppTextKey.notificationTooltip),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  color: AppColors.mutedInk,
                ),
                const SizedBox(width: AppSpacing.sm),
                _TopProfileButton(showName: wide, onPressed: onProfilePressed),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Locale Button ─────────────────────────────────────────────────────────────

class _LocaleBtn extends StatelessWidget {
  const _LocaleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.mutedInk,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopProfileButton extends StatelessWidget {
  const _TopProfileButton({required this.showName, required this.onPressed});

  final bool showName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isFrench = context.appLocale == AppLocale.fr;
    final name = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 132),
      child: Text(
        context.tr(AppTextKey.doctorName),
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: enabled ? AppColors.ink : AppColors.mutedInk,
        ),
      ),
    );
    final avatar = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.softBlue
            : AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
    final content = showName
        ? <Widget>[
            if (isFrench) avatar else name,
            const SizedBox(width: AppSpacing.sm),
            if (isFrench) name else avatar,
          ]
        : <Widget>[avatar];

    return Tooltip(
      message: context.tr(AppTextKey.myProfile),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsetsDirectional.only(
            start: showName ? AppSpacing.sm : 0,
            end: showName ? AppSpacing.xs : 0,
            top: showName ? AppSpacing.xs : 0,
            bottom: showName ? AppSpacing.xs : 0,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: content),
        ),
      ),
    );
  }
}

// ── Right Context Panel ───────────────────────────────────────────────────────

class _RightContextPanel extends StatelessWidget {
  const _RightContextPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appLocale == AppLocale.ar;
    return Container(
      width: AppSpacing.rightPanelWidth,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile ──────────────────────────────────────────
            _PanelLabel(title: context.tr(AppTextKey.myProfile)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(AppTextKey.doctorName),
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.tr(AppTextKey.profileSpecialty),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.placeholder,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              context.tr(AppTextKey.profileLocation),
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileStats(outerContext: context),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // ── Calendar ─────────────────────────────────────────
            _PanelLabel(title: context.tr(AppTextKey.myCalendar)),
            const SizedBox(height: AppSpacing.md),
            const _CalendarStrip(),
            const SizedBox(height: AppSpacing.md),
            _ContextItem(
              time: '14:00',
              title: isArabic
                  ? 'اجتماع متابعة — د. ويليامز'
                  : 'Réunion de suivi — Dr. Williams',
              tone: BadgeTone.info,
              label: isArabic ? 'اجتماع' : 'Réunion',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ContextItem(
              time: '15:00',
              title: isArabic
                  ? 'استشارة مجدولة — السيدة مايزي'
                  : 'Consultation planifiée — Mme Maisy',
              tone: BadgeTone.normal,
              label: isArabic ? 'رعاية' : 'Soin',
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // ── Alerts ───────────────────────────────────────────
            StatusBadge(
              label: context.tr(AppTextKey.allergyCritical),
              tone: BadgeTone.critical,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            StatusBadge(
              label: context.tr(AppTextKey.readOnlyAfterSession),
              tone: BadgeTone.info,
              icon: Icons.visibility_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Panel Label ───────────────────────────────────────────────────────────────

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ── Profile Stats ─────────────────────────────────────────────────────────────

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.outerContext});

  final BuildContext outerContext;

  @override
  Widget build(BuildContext context) {
    final departmentValue = switch (outerContext.appLocale) {
      AppLocale.ar => 'جلدية',
      AppLocale.fr => 'Dermatologie',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + 2,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderFaint, width: 0.5),
      ),
      child: SizedBox(
        height: 54,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatCell(
                label: outerContext.tr(AppTextKey.doctorDepartment),
                value: departmentValue,
              ),
            ),
            const VerticalDivider(color: AppColors.border, width: 1),
            Expanded(
              child: _StatCell(
                label: outerContext.tr(AppTextKey.doctorAvailability),
                value: '✓',
              ),
            ),
            const VerticalDivider(color: AppColors.border, width: 1),
            Expanded(
              child: _StatCell(
                label: outerContext.tr(AppTextKey.workingHours),
                value: '9–17',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ── Calendar Strip ────────────────────────────────────────────────────────────

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip();

  static const Map<AppLocale, List<String>> _dayNames = {
    AppLocale.fr: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
    AppLocale.ar: ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'],
  };

  @override
  Widget build(BuildContext context) {
    final locale = context.appLocale;
    final days = _dayNames[locale] ?? _dayNames[AppLocale.fr]!;
    const dates = ['12', '13', '14', '15', '16', '17', '18'];

    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: i == 1
                    ? AppColors.primary
                    : AppColors.surface.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      color: i == 1 ? Colors.white : AppColors.placeholder,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dates[i],
                    style: TextStyle(
                      color: i == 1 ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Context Item ──────────────────────────────────────────────────────────────

class _ContextItem extends StatelessWidget {
  const _ContextItem({
    required this.time,
    required this.title,
    required this.label,
    required this.tone,
  });

  final String time;
  final String title;
  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.58),
        border: Border.all(color: AppColors.borderFaint, width: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}
