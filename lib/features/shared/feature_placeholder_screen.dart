import 'package:flutter/material.dart';

import '../../app/router/app_route.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_state_panel.dart';
import '../../core/widgets/clinical_alert_banner.dart';
import '../../core/widgets/implementation_roadmap_panel.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.route,
    required this.summary,
    required this.primaryItems,
    this.showImplementationRoadmap = false,
  });

  final AppRoute route;
  final String summary;
  final List<String> primaryItems;
  final bool showImplementationRoadmap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClinicalAlertBanner(
          title: 'ضوابط أمان الواجهة',
          message:
              'ستدعم هذه الشاشة جميع حالات الواجهة القياسية: التحميل، فراغ البيانات، غياب الصلاحية، القراءة فقط، انتهاء الجلسة، عدم توثيق الجهاز، تدهور الشبكة، والتنبيهات الحرجة.',
          isCritical: route.section == AppSection.security,
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'نطاق الشاشة وفق الوثيقة',
          subtitle: 'المحتوى الوظيفي معرّف مسبقًا قبل ربط خدمات الخلفية.',
          child: Column(
            children: [
              for (final item in primaryItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusBadge(
                        label: 'متطلب واجهة',
                        tone: BadgeTone.info,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(item, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppStatePanel(
          title: 'جاهزة كهيكل واجهة',
          message:
              'هذه الصفحة مدمجة ضمن خريطة التنقل، وستتحول في المرحلة التالية إلى شاشة تفاعلية مدعومة ببيانات فعلية أو بيانات محاكاة مفصلة.',
          icon: Icons.account_tree_outlined,
        ),
        if (showImplementationRoadmap) ...[
          const SizedBox(height: AppSpacing.xl),
          const ImplementationRoadmapPanel(),
        ],
      ],
    );
  }
}
