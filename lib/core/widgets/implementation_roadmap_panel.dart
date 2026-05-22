import 'package:flutter/material.dart';

import '../../app/implementation/implementation_phase.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'section_card.dart';

class ImplementationRoadmapPanel extends StatelessWidget {
  const ImplementationRoadmapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'ترتيب التنفيذ المعتمد',
      subtitle: 'تسلسل ثابت يمنع بناء الشاشات قبل تأسيس الواجهة والأمان.',
      child: Column(
        children: [
          for (final phase in ImplementationRoadmap.phases)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${phase.order}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(phase.icon, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          phase.scope,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
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
