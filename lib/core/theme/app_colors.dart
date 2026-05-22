import 'package:flutter/material.dart';

/// Single source of truth for all application colors.
///
/// ╔══════════════════════════════════════╗
/// ║  To change the primary app color:    ║
/// ║  edit [primary] and [sidebar]        ║
/// ║                                      ║
/// ║  To change the gray page background:  ║
/// ║  edit [canvas]                       ║
/// ╚══════════════════════════════════════╝
abstract final class AppColors {
  // ════════════════════════════════════════════════════════════════
  // ❶  BRAND — primary app and sidebar color
  //    To rebrand: change [primary] only and everything follows
  // ════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF2B51E4); // ← #2b51e4 — Brand Blue
  static const Color primaryDark = Color(
    0xFF203CB0,
  ); // ← 20% darker (hover/pressed)
  static const Color accent = Color(0xFF5E77F0); // ← lighter and brighter

  // ════════════════════════════════════════════════════════════════
  // ❷  SIDEBAR — inherits the primary color automatically
  // ════════════════════════════════════════════════════════════════
  static const Color sidebar = primary; // = #2B51E4
  static const Color sidebarMuted = Color(
    0xFFDDE3FF,
  ); // inactive text on #2B51E4 background

  // ════════════════════════════════════════════════════════════════
  // ❸  SURFACES & CANVAS
  //    canvas  = #f7f7f7 → page background
  //    surface = #f9f9f9 → cards and panels
  // ════════════════════════════════════════════════════════════════
  static const Color ink = Color(0xFF1C1C1E); // macOS near-black
  static const Color mutedInk = Color(0xFF717171); // secondary text
  static const Color placeholder = Color(0xFFA9A9A9); // muted text
  static const Color canvas = Color(0xFFF7F7F7); // ← #f7f7f7 page background
  static const Color surface = canvas; // Line-based SaaS surfaces inherit page
  static const Color border = Color(0xFFDDDDDD); // borders
  static const Color borderSoft = Color(0xFFCBCBCB); // soft borders
  static const Color borderFaint = Color(0xFFE4E4E4); // faint card borders
  static const Color glassSurface = Color(0xD9FFFFFF); // white 85%
  static const Color glassSurfaceStrong = Color(0xF2FFFFFF); // white 95%
  static const Color glassStroke = Color(0xB3FFFFFF); // white 70%

  // ════════════════════════════════════════════════════════════════
  // ❹  SOFT TINTS — derived from the new primary color
  // ════════════════════════════════════════════════════════════════
  static const Color softBlue = Color(0xFFE9ECFF); // ← light tint from #2B51E4
  static const Color softPink = Color(0xFFFFF1F2);
  static const Color softMint = Color(0xFFECFDF5);
  static const Color softPurple = Color(0xFFF5F3FF);

  // ════════════════════════════════════════════════════════════════
  // ❺  SEMANTIC — fixed medical meaning colors (do not change semantics)
  //    ✓ green  ⚠ orange  ✕ red  ℹ blue
  // ════════════════════════════════════════════════════════════════
  static const Color normal = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ════════════════════════════════════════════════════════════════
  // ❻  SURFACE DEPTH — modern SaaS uses lines instead of card boxes.
  // ════════════════════════════════════════════════════════════════
  static List<BoxShadow> get cardShadow => const [];

  static List<BoxShadow> get floatingShadow => const [
    BoxShadow(color: Color(0x08000000), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x05000000), blurRadius: 48, offset: Offset(0, 28)),
  ];
}
