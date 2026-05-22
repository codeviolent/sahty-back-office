import 'package:flutter/material.dart';

class ImplementationPhase {
  const ImplementationPhase({
    required this.order,
    required this.title,
    required this.scope,
    required this.icon,
  });

  final int order;
  final String title;
  final String scope;
  final IconData icon;
}

abstract final class ImplementationRoadmap {
  static const phases = [
    ImplementationPhase(
      order: 1,
      title: 'نظام التصميم',
      scope:
          'الألوان الطبية، الخطوط، المسافات، البطاقات، حالات الواجهة، والتنبيهات.',
      icon: Icons.design_services_outlined,
    ),
    ImplementationPhase(
      order: 2,
      title: 'هيكل التطبيق',
      scope: 'شريط جانبي ثابت، شريط علوي، محتوى رئيسي، ولوحة سياق جانبية.',
      icon: Icons.dashboard_customize_outlined,
    ),
    ImplementationPhase(
      order: 3,
      title: 'المصادقة وثقة الجهاز',
      scope: 'الدخول الآمن، MFA، حالة الجهاز، وانتهاء الجلسة.',
      icon: Icons.lock_outline,
    ),
    ImplementationPhase(
      order: 4,
      title: 'Dashboard',
      scope: 'ملخص يومي وتنبيهات حرجة ونشاط حديث قابل للتدقيق.',
      icon: Icons.dashboard_outlined,
    ),
    ImplementationPhase(
      order: 5,
      title: 'بحث المرضى وإدارة الوصول',
      scope: 'بحث مقيد، نتائج مختصرة، وفتح جلسة مريض مؤقتة.',
      icon: Icons.manage_search,
    ),
    ImplementationPhase(
      order: 6,
      title: 'هيكل الملف الطبي',
      scope:
          'نظرة عامة وتسلسل زمني، ثم الوصفات، والتحاليل، والأشعة، واللقاحات، والمؤشرات الحيوية.',
      icon: Icons.folder_shared_outlined,
    ),
    ImplementationPhase(
      order: 7,
      title: 'العمليات والمراسلات والتدقيق',
      scope:
          'المواعيد، قائمة الانتظار، الرسائل الطبية، الإدارة، وسجلات التدقيق.',
      icon: Icons.policy_outlined,
    ),
  ];
}
