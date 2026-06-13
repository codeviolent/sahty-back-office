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
    allowedRoles: ['medecin', 'admin', 'staff', 'pharmacien'],
  ),
  deviceTrust(
    titleKey: AppTextKey.routeDeviceTrust,
    section: AppSection.security,
    icon: Icons.verified_user_outlined,
    allowedRoles: ['medecin', 'admin', 'staff', 'pharmacien'],
  ),
  dashboard(
    titleKey: AppTextKey.routeDashboard,
    section: AppSection.operations,
    icon: Icons.dashboard_outlined,
    allowedRoles: ['medecin', 'admin', 'staff'],
  ),
  patientSearch(
    titleKey: AppTextKey.routePatientSearch,
    section: AppSection.patients,
    icon: Icons.manage_search,
    allowedRoles: ['medecin', 'admin', 'staff'],
  ),
  patientAccess(
    titleKey: AppTextKey.routePatientAccess,
    section: AppSection.patients,
    icon: Icons.qr_code_2,
    allowedRoles: ['medecin', 'staff', 'pharmacien'],
  ),
  medicalOverview(
    titleKey: AppTextKey.routeMedicalOverview,
    section: AppSection.clinical,
    icon: Icons.folder_shared_outlined,
    allowedRoles: ['medecin', 'staff'],
  ),
  timeline(
    titleKey: AppTextKey.routeTimeline,
    section: AppSection.clinical,
    icon: Icons.timeline,
    allowedRoles: ['medecin', 'staff'],
  ),
  diagnoses(
    titleKey: AppTextKey.routeDiagnoses,
    section: AppSection.clinical,
    icon: Icons.medical_information_outlined,
    allowedRoles: ['medecin', 'staff'],
  ),
  prescriptions(
    titleKey: AppTextKey.routePrescriptions,
    section: AppSection.clinical,
    icon: Icons.medication_outlined,
    allowedRoles: ['medecin', 'pharmacien', 'staff'],
  ),
  labs(
    titleKey: AppTextKey.routeLabs,
    section: AppSection.clinical,
    icon: Icons.science_outlined,
    allowedRoles: ['medecin', 'staff'],
  ),
  imaging(
    titleKey: AppTextKey.routeImaging,
    section: AppSection.clinical,
    icon: Icons.image_search_outlined,
    allowedRoles: ['medecin', 'staff'],
  ),
  vaccines(
    titleKey: AppTextKey.routeVaccines,
    section: AppSection.clinical,
    icon: Icons.vaccines_outlined,
    allowedRoles: ['medecin', 'staff'],
  ),
  vitals(
    titleKey: AppTextKey.routeVitals,
    section: AppSection.clinical,
    icon: Icons.monitor_heart_outlined,
    allowedRoles: ['medecin', 'staff'],
  ),
  appointments(
    titleKey: AppTextKey.routeAppointments,
    section: AppSection.operations,
    icon: Icons.calendar_month_outlined,
    allowedRoles: ['medecin', 'admin', 'staff'],
  ),
  queue(
    titleKey: AppTextKey.routeQueue,
    section: AppSection.operations,
    icon: Icons.format_list_numbered,
    allowedRoles: ['medecin', 'staff'],
  ),
  messaging(
    titleKey: AppTextKey.routeMessaging,
    section: AppSection.communication,
    icon: Icons.forum_outlined,
    allowedRoles: ['medecin', 'admin'],
  ),
  administration(
    titleKey: AppTextKey.routeAdministration,
    section: AppSection.administration,
    icon: Icons.admin_panel_settings_outlined,
    allowedRoles: ['admin'],
  ),
  auditLogs(
    titleKey: AppTextKey.routeAuditLogs,
    section: AppSection.administration,
    icon: Icons.policy_outlined,
    allowedRoles: ['admin'],
  );

  const AppRoute({
    required this.titleKey,
    required this.section,
    required this.icon,
    required this.allowedRoles,
  });

  final AppTextKey titleKey;
  final AppSection section;
  final IconData icon;
  final List<String> allowedRoles;
  bool isAllowedFor(String role) => allowedRoles.contains(role);
}
