import 'package:flutter/material.dart';

import '../../core/l10n/app_text_key.dart';

enum AppSection {
  security(AppTextKey.sidebarSecurity),
  operations(AppTextKey.sidebarOperations),
  patients(AppTextKey.sidebarPatients),
  clinical(AppTextKey.sidebarClinical),
  communication(AppTextKey.sidebarCommunication),
  administration(AppTextKey.sidebarAdministration);

  const AppSection(this.titleKey);

  final AppTextKey titleKey;
}

enum AppRoute {
  secureLogin(
    titleKey: AppTextKey.routeSecureLogin,
    section: AppSection.security,
    icon: Icons.lock_outline,
  ),
  deviceTrust(
    titleKey: AppTextKey.routeDeviceTrust,
    section: AppSection.security,
    icon: Icons.verified_user_outlined,
  ),
  dashboard(
    titleKey: AppTextKey.routeDashboard,
    section: AppSection.operations,
    icon: Icons.dashboard_outlined,
  ),
  patientSearch(
    titleKey: AppTextKey.routePatientSearch,
    section: AppSection.patients,
    icon: Icons.manage_search,
  ),
  patientAccess(
    titleKey: AppTextKey.routePatientAccess,
    section: AppSection.patients,
    icon: Icons.qr_code_2,
  ),
  medicalOverview(
    titleKey: AppTextKey.routeMedicalOverview,
    section: AppSection.clinical,
    icon: Icons.folder_shared_outlined,
  ),
  timeline(
    titleKey: AppTextKey.routeTimeline,
    section: AppSection.clinical,
    icon: Icons.timeline,
  ),
  diagnoses(
    titleKey: AppTextKey.routeDiagnoses,
    section: AppSection.clinical,
    icon: Icons.medical_information_outlined,
  ),
  prescriptions(
    titleKey: AppTextKey.routePrescriptions,
    section: AppSection.clinical,
    icon: Icons.medication_outlined,
  ),
  labs(
    titleKey: AppTextKey.routeLabs,
    section: AppSection.clinical,
    icon: Icons.science_outlined,
  ),
  imaging(
    titleKey: AppTextKey.routeImaging,
    section: AppSection.clinical,
    icon: Icons.image_search_outlined,
  ),
  vaccines(
    titleKey: AppTextKey.routeVaccines,
    section: AppSection.clinical,
    icon: Icons.vaccines_outlined,
  ),
  vitals(
    titleKey: AppTextKey.routeVitals,
    section: AppSection.clinical,
    icon: Icons.monitor_heart_outlined,
  ),
  appointments(
    titleKey: AppTextKey.routeAppointments,
    section: AppSection.operations,
    icon: Icons.calendar_month_outlined,
  ),
  queue(
    titleKey: AppTextKey.routeQueue,
    section: AppSection.operations,
    icon: Icons.format_list_numbered,
  ),
  messaging(
    titleKey: AppTextKey.routeMessaging,
    section: AppSection.communication,
    icon: Icons.forum_outlined,
  ),
  administration(
    titleKey: AppTextKey.routeAdministration,
    section: AppSection.administration,
    icon: Icons.admin_panel_settings_outlined,
  ),
  auditLogs(
    titleKey: AppTextKey.routeAuditLogs,
    section: AppSection.administration,
    icon: Icons.policy_outlined,
  );

  const AppRoute({
    required this.titleKey,
    required this.section,
    required this.icon,
  });

  final AppTextKey titleKey;
  final AppSection section;
  final IconData icon;
}
