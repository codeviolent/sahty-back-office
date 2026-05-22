abstract final class AppSpacing {
  // ── Base spacing scale ───────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double xxl = 28;

  // ── Sidebar ──────────────────────────────────────────────────────
  // Collapsed (icons only) ↔ expanded (icon + label)
  static const double sidebarCollapsedWidth = 58;
  static const double sidebarExpandedWidth = 206;

  /// Reference inner width when expanded (after subtracting padding=10 from each side)
  static const double sidebarInnerWidth = sidebarExpandedWidth - 18; // 188

  // ── Other layout constants ────────────────────────────────────────
  static const double shellInset = 12;
  static const double rightPanelWidth = 276;
  static const double topBarHeight = 52;
  static const double cardRadius = 14;
  static const double panelRadius = 18;
}
