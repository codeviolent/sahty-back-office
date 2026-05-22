import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
