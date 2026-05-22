import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';

class StartupSplashScreen extends StatefulWidget {
  const StartupSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 4650);
  static const _asset = 'assets/images/typography-b.svg';
  static const _svgSize = Size(1979, 447);

  // Bounds were taken from typography-b.svg:
  // - left arc: path starting at x=1610
  // - right arc: gradient path from x=1797 to 1979
  // - dot: circle-like path from x=1726.74, y=0 to x=1870.74, y=142
  static const _markBounds = Rect.fromLTRB(1610, 0, 1979, 447);
  static const _leftArcBounds = Rect.fromLTRB(1608, 94, 1832, 447);
  static const _rightArcBounds = Rect.fromLTRB(1794, 94, 1979, 447);
  static const _dotBounds = Rect.fromLTRB(1724, 0, 1873, 144);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _seconds() => _controller.value * _duration.inMilliseconds / 1000;

  double _range(double start, double end, double seconds) {
    return ((seconds - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _smooth(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  double _sine(double value) {
    final t = value.clamp(0.0, 1.0);
    return -(math.cos(math.pi * t) - 1) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final seconds = _seconds();

        return ColoredBox(
          color: AppColors.canvas,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoWidth = math.min(constraints.maxWidth * 0.58, 720.0);
              final scale = logoWidth / _svgSize.width;
              final logoHeight = _svgSize.height * scale;
              final logoLeft = (constraints.maxWidth - logoWidth) / 2;

              final markSize = Size(
                _markBounds.width * scale,
                _markBounds.height * scale,
              );
              final dotSize = Size(
                _dotBounds.width * scale,
                _dotBounds.height * scale,
              );
              final dotLocalCenter = Offset(
                (_dotBounds.center.dx - _markBounds.left) * scale,
                (_dotBounds.center.dy - _markBounds.top) * scale,
              );
              final logoTop = (constraints.maxHeight - logoHeight) / 2;
              final wordCenter = Offset(
                logoLeft + logoWidth / 2,
                logoTop + logoHeight / 2,
              );
              final markCenterLeft = wordCenter.dx - dotLocalCenter.dx;
              final markFinalLeft = logoLeft + (_markBounds.left * scale);
              final markLeftSweep = logoLeft;

              final drop = _smooth(_range(0.00, 1.18, seconds));
              final opacity = _smooth(_range(0.00, 0.52, seconds));
              final introScale =
                  0.96 + (_smooth(_range(0.00, 1.18, seconds)) * 0.04);
              final dotStartTop = -dotSize.height - 54;
              final dotFinalTop =
                  logoTop + ((_dotBounds.top - _markBounds.top) * scale);
              final droppedDotTop = _lerp(dotStartTop, dotFinalTop, drop);
              final dotLeft =
                  markCenterLeft +
                  ((_dotBounds.left - _markBounds.left) * scale);

              // A tiny upward settle after the circle lands, then back to center.
              final settleProgress = _range(1.18, 1.58, seconds);
              final settleOffset =
                  -5 *
                  math.sin(math.pi * _sine(settleProgress)) *
                  (1 - settleProgress);
              final floatingOffset =
                  math.sin(seconds * math.pi * 2.4) *
                  2.0 *
                  (1 - _smooth(_range(1.58, 2.10, seconds)));
              final fallingDotTop =
                  droppedDotTop + settleOffset + floatingOffset;

              final assemblyOpacity = _smooth(_range(1.44, 1.62, seconds));
              final fallingDotFade = 1 - _smooth(_range(1.46, 1.68, seconds));
              final leftArc = _smooth(_range(1.48, 1.82, seconds));
              final rightArc = _smooth(_range(1.72, 2.08, seconds));
              final dot = _smooth(_range(1.34, 1.58, seconds));

              final moveLeft = _smooth(_range(2.16, 2.88, seconds));
              final writeBack = _smooth(_range(2.88, 3.96, seconds));
              final markLeft = seconds < 2.88
                  ? _lerp(markCenterLeft, markLeftSweep, moveLeft)
                  : _lerp(markLeftSweep, markFinalLeft, writeBack);
              final markTop = logoTop;

              final writingRevealWidth = seconds < 2.88
                  ? 0.0
                  : (markLeft - logoLeft).clamp(0.0, logoWidth);
              final finalReveal = _smooth(_range(3.96, 4.28, seconds));
              final revealWidth = seconds < 3.96
                  ? writingRevealWidth
                  : _lerp(markFinalLeft - logoLeft, logoWidth, finalReveal);
              final pulseProgress = _range(2.88, 3.96, seconds);
              final pulseScale =
                  1.0 + (math.sin(math.pi * pulseProgress) * 0.012);

              return Stack(
                children: [
                  Positioned(
                    left: logoLeft,
                    top: logoTop,
                    width: logoWidth,
                    height: logoHeight,
                    child: Opacity(
                      opacity: _smooth(_range(2.88, 3.02, seconds)),
                      child: _FadingLogoReveal(
                        asset: _asset,
                        width: logoWidth,
                        height: logoHeight,
                        revealWidth: revealWidth,
                      ),
                    ),
                  ),
                  Positioned(
                    left: markLeft,
                    top: markTop,
                    width: markSize.width,
                    height: markSize.height,
                    child: Opacity(
                      opacity: assemblyOpacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: pulseScale,
                        child: _LastMarkAssembly(
                          asset: _asset,
                          logoWidth: logoWidth,
                          logoHeight: logoHeight,
                          scale: scale,
                          leftArcOpacity: leftArc,
                          rightArcOpacity: rightArc,
                          dotOpacity: dot,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: dotLeft,
                    top: fallingDotTop,
                    width: dotSize.width,
                    height: dotSize.height,
                    child: Opacity(
                      opacity: (opacity * fallingDotFade).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: introScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1846E4),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.24,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _lerp(double start, double end, double t) =>
      start + ((end - start) * t);
}

class _LastMarkAssembly extends StatelessWidget {
  const _LastMarkAssembly({
    required this.asset,
    required this.logoWidth,
    required this.logoHeight,
    required this.scale,
    required this.leftArcOpacity,
    required this.rightArcOpacity,
    required this.dotOpacity,
  });

  final String asset;
  final double logoWidth;
  final double logoHeight;
  final double scale;
  final double leftArcOpacity;
  final double rightArcOpacity;
  final double dotOpacity;

  @override
  Widget build(BuildContext context) {
    final markRect = _StartupSplashScreenState._markBounds;

    return SizedBox(
      width: markRect.width * scale,
      height: markRect.height * scale,
      child: Stack(
        children: [
          _SvgCrop(
            asset: asset,
            sourceRect: _StartupSplashScreenState._leftArcBounds,
            originRect: markRect,
            logoWidth: logoWidth,
            logoHeight: logoHeight,
            opacity: leftArcOpacity,
          ),
          _SvgCrop(
            asset: asset,
            sourceRect: _StartupSplashScreenState._rightArcBounds,
            originRect: markRect,
            logoWidth: logoWidth,
            logoHeight: logoHeight,
            opacity: rightArcOpacity,
          ),
          _SvgCrop(
            asset: asset,
            sourceRect: _StartupSplashScreenState._dotBounds,
            originRect: markRect,
            logoWidth: logoWidth,
            logoHeight: logoHeight,
            opacity: dotOpacity,
          ),
        ],
      ),
    );
  }
}

class _SvgCrop extends StatelessWidget {
  const _SvgCrop({
    required this.asset,
    required this.sourceRect,
    required this.originRect,
    required this.logoWidth,
    required this.logoHeight,
    required this.opacity,
  });

  final String asset;
  final Rect sourceRect;
  final Rect originRect;
  final double logoWidth;
  final double logoHeight;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scale = logoWidth / _StartupSplashScreenState._svgSize.width;
    final sourceLeft = sourceRect.left * scale;
    final sourceTop = sourceRect.top * scale;
    final width = sourceRect.width * scale;
    final height = sourceRect.height * scale;

    return Positioned(
      left: (sourceRect.left - originRect.left) * scale,
      top: (sourceRect.top - originRect.top) * scale,
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: logoWidth,
            maxWidth: logoWidth,
            minHeight: logoHeight,
            maxHeight: logoHeight,
            child: Transform.translate(
              offset: Offset(-sourceLeft, -sourceTop),
              child: SvgPicture.asset(
                asset,
                width: logoWidth,
                height: logoHeight,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FadingLogoReveal extends StatelessWidget {
  const _FadingLogoReveal({
    required this.asset,
    required this.width,
    required this.height,
    required this.revealWidth,
  });

  final String asset;
  final double width;
  final double height;
  final double revealWidth;

  @override
  Widget build(BuildContext context) {
    final fadeBand = math.min(width * 0.12, 74.0);
    final softStart = ((revealWidth - fadeBand) / width).clamp(0.0, 1.0);
    final softEnd = (revealWidth / width).clamp(0.0, 1.0);

    return ClipRect(
      clipper: _LogoRevealClipper(revealWidth),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          if (revealWidth <= 1) {
            return const LinearGradient(
              colors: [Colors.transparent, Colors.transparent],
            ).createShader(bounds);
          }
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0, softStart, softEnd, 1],
            colors: const [
              Colors.white,
              Colors.white,
              Colors.transparent,
              Colors.transparent,
            ],
          ).createShader(bounds);
        },
        child: SvgPicture.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

class _LogoRevealClipper extends CustomClipper<Rect> {
  const _LogoRevealClipper(this.width);

  final double width;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, width.clamp(0.0, size.width), size.height);
  }

  @override
  bool shouldReclip(covariant _LogoRevealClipper oldClipper) {
    return oldClipper.width != width;
  }
}
