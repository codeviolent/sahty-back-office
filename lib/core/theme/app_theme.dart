import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,

      // ── Typography — compact SaaS hierarchy for dense desktop data ──
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.45,
          height: 1.18,
        ),
        headlineMedium: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.32,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.22,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedInk,
          height: 1.42,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedInk,
          height: 1.35,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedInk,
          letterSpacing: 0.3,
        ),
      ),

      // ── Card — line-based SaaS surface, no raised boxes ──────────────
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(side: BorderSide.none),
      ),

      // ── Input decoration — macOS minimal style ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.placeholder),
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.mutedInk),
        prefixIconColor: AppColors.mutedInk,
      ),

      // ── Buttons ────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
