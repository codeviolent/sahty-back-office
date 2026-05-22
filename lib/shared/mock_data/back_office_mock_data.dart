import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';

class MockMetric {
  const MockMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;
}

class MockRowItem {
  const MockRowItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final String status;
  final BadgeTone tone;
}

abstract final class BackOfficeMockData {
  static const doctorName = 'Dr. Alisha Nichols';
  static const sessionStatus = 'Session sécurisée - 18 min restantes';
  static const activePatient = 'Mariam Bent Salem';
  static const maskedNni = 'NNI: 1234 **** **** 91';
  static const allergies = 'Allergie critique: pénicilline';

  static const metrics = [
    MockMetric(
      label: 'Patients aujourd’hui',
      value: '42',
      icon: Icons.groups_outlined,
      color: AppColors.primary,
      caption: '12 dossiers à revoir',
    ),
    MockMetric(
      label: 'File d’attente',
      value: '9',
      icon: Icons.format_list_numbered,
      color: AppColors.warning,
      caption: '2 priorités cliniques',
    ),
    MockMetric(
      label: 'Alertes critiques',
      value: '3',
      icon: Icons.warning_amber_rounded,
      color: AppColors.critical,
      caption: 'Décision requise',
    ),
    MockMetric(
      label: 'Messages non lus',
      value: '16',
      icon: Icons.mark_email_unread_outlined,
      color: AppColors.info,
      caption: '5 messages équipe',
    ),
  ];

  static const activity = [
    MockRowItem(
      title: 'Session patient temporaire ouverte',
      subtitle: 'Patient: Mariam Bent Salem - motif: consultation',
      status: 'validé',
      tone: BadgeTone.normal,
    ),
    MockRowItem(
      title: 'Résultat laboratoire hors limites',
      subtitle: 'HbA1c élevé par rapport à la dernière visite',
      status: 'alerte',
      tone: BadgeTone.warning,
    ),
    MockRowItem(
      title: 'Tentative depuis un appareil inconnu',
      subtitle: 'Windows Desktop - approbation administrateur requise',
      status: 'sécurité',
      tone: BadgeTone.critical,
    ),
  ];

  static const patientContext = [
    MockRowItem(
      title: 'آخر زيارة',
      subtitle: 'متابعة ضغط وسكر - منذ 7 أيام',
      status: 'مكتمل',
      tone: BadgeTone.normal,
    ),
    MockRowItem(
      title: 'دواء نشط',
      subtitle: 'Metformin 500mg - مرتين يوميًا',
      status: 'active',
      tone: BadgeTone.info,
    ),
    MockRowItem(
      title: 'موعد قادم',
      subtitle: 'الأحد 09:30 - عيادة الباطنية',
      status: 'مؤكد',
      tone: BadgeTone.normal,
    ),
  ];
}
