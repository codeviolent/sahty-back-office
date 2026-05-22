import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Unified linear section — separates content with thin dividers instead of heavy boxes.
class SectionCard extends StatelessWidget {
  static final _kDecoration = BoxDecoration(
    color: AppColors.surface,
    border: const Border(
      top: BorderSide(color: AppColors.borderFaint, width: 0.7),
      bottom: BorderSide(color: AppColors.borderFaint, width: 0.7),
    ),
  );
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding,
    this.minHeight,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight!),
      decoration: _kDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.mutedInk),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),

          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.borderFaint,
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}
