import 'package:flutter/material.dart';

import '../../features/administration/presentation/screens/administration_screen.dart';
import '../../features/administration/presentation/screens/audit_logs_screen.dart';
import '../../features/auth/presentation/screens/device_trust_screen.dart';
import '../../features/auth/presentation/screens/secure_login_screen.dart';
import '../../features/communication/presentation/screens/messaging_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/medical_record/presentation/screens/diagnoses_screen.dart';
import '../../features/medical_record/presentation/screens/imaging_screen.dart';
import '../../features/medical_record/presentation/screens/labs_screen.dart';
import '../../features/medical_record/presentation/screens/medical_overview_screen.dart';
import '../../features/medical_record/presentation/screens/prescriptions_screen.dart';
import '../../features/medical_record/presentation/screens/timeline_screen.dart';
import '../../features/medical_record/presentation/screens/vaccines_screen.dart';
import '../../features/medical_record/presentation/screens/vitals_screen.dart';
import '../../features/operations/presentation/screens/appointments_screen.dart';
import '../../features/operations/presentation/screens/queue_screen.dart';
import '../../features/patients/presentation/screens/patient_access_screen.dart';
import '../../features/patients/presentation/screens/patient_search_screen.dart';
import '../../features/shared/feature_placeholder_screen.dart';
import 'app_route.dart';

abstract final class AppRouter {
  static Widget buildScreen(
    AppRoute route, {
    required VoidCallback onLoginVerified,
    required VoidCallback onDeviceApproved,
  }) {
    if (route == AppRoute.dashboard) {
      return const DashboardScreen();
    }
    if (route == AppRoute.secureLogin) {
      return SecureLoginScreen(onLoginVerified: onLoginVerified);
    }
    if (route == AppRoute.deviceTrust) {
      return DeviceTrustScreen(onDeviceApproved: onDeviceApproved);
    }
    if (route == AppRoute.patientSearch) {
      return const PatientSearchScreen();
    }
    if (route == AppRoute.patientAccess) {
      return const PatientAccessScreen();
    }
    if (route == AppRoute.medicalOverview) {
      return const MedicalOverviewScreen();
    }
    if (route == AppRoute.timeline) {
      return const TimelineScreen();
    }
    if (route == AppRoute.diagnoses) {
      return const DiagnosesScreen();
    }
    if (route == AppRoute.prescriptions) {
      return const PrescriptionsScreen();
    }
    if (route == AppRoute.labs) {
      return const LabsScreen();
    }
    if (route == AppRoute.imaging) {
      return const ImagingScreen();
    }
    if (route == AppRoute.vaccines) {
      return const VaccinesScreen();
    }
    if (route == AppRoute.vitals) {
      return const VitalsScreen();
    }
    if (route == AppRoute.appointments) {
      return const AppointmentsScreen();
    }
    if (route == AppRoute.queue) {
      return const QueueScreen();
    }
    if (route == AppRoute.messaging) {
      return const MessagingScreen();
    }
    if (route == AppRoute.administration) {
      return const AdministrationScreen();
    }
    if (route == AppRoute.auditLogs) {
      return const AuditLogsScreen();
    }

    final spec = _screenSpecs[route];
    return FeaturePlaceholderScreen(
      route: route,
      summary: spec?.summary ?? '',
      primaryItems: spec?.items ?? const [],
      showImplementationRoadmap: route == AppRoute.administration,
    );
  }
}

class _ScreenSpec {
  const _ScreenSpec({required this.summary, required this.items});

  final String summary;
  final List<String> items;
}

const _screenSpecs = <AppRoute, _ScreenSpec>{
  AppRoute.secureLogin: _ScreenSpec(
    summary: 'مدخل صارم للطبيب والمستخدمين المخولين فقط.',
    items: [
      'معرّف الطبيب أو اسم المستخدم، كلمة المرور، والمصادقة متعددة العوامل (MFA/OTP).',
      'إظهار حالة الجهاز والثقة قبل عرض أي بيانات حساسة.',
      'زر تسجيل الدخول البيومتري يظهر فقط عند توفره واعتماده.',
    ],
  ),
  AppRoute.deviceTrust: _ScreenSpec(
    summary: 'اعتماد الجهاز وربطه بسياسات الثقة قبل الدخول الكامل.',
    items: [
      'اسم الجهاز، نظام التشغيل، الإصدار، وآخر دخول.',
      'حالة الجهاز: موثوق، بانتظار الموافقة، أو مرفوض.',
      'إعادة طلب التوثيق مع سبب الرفض أو المراجعة.',
    ],
  ),
  AppRoute.patientSearch: _ScreenSpec(
    summary: 'بحث سريع ومقيد عن المرضى دون فتح ملفات بلا سبب.',
    items: [
      'بحث بالاسم أو NNI أو رقم الملف مع إخفاء NNI عند العرض العام.',
      'فلاتر العمر، الجنس، الحالة، آخر زيارة، والطبيب المعالج.',
      'نتائج مختصرة بجداول واضحة قبل فتح الملف.',
    ],
  ),
  AppRoute.patientAccess: _ScreenSpec(
    summary: 'فتح جلسة مريض مؤقتة ومبررة ومحددة المدة.',
    items: [
      'رمز QR أو معرّف الجلسة مع التحقق عبر رمز PIN.',
      'سبب الوصول: استشارة، طارئ، أو متابعة.',
      'مدة صلاحية وعد تنازلي وزر إنهاء الجلسة فورًا.',
    ],
  ),
  AppRoute.medicalOverview: _ScreenSpec(
    summary: 'ملف طبي شامل مع تسلسل بصري يبدأ بالحساسية والتحذيرات.',
    items: [
      'بيانات تعريفية مختصرة في الأعلى.',
      'شريط حساسية دائم الظهور.',
      'تشخيصات نشطة، أدوية حالية، مؤشرات، لقاحات، وآخر زيارة.',
    ],
  ),
  AppRoute.timeline: _ScreenSpec(
    summary: 'أحداث طبية مرتبة زمنيًا مع فلاتر وروابط سريعة.',
    items: [
      'تنقل حسب السنة، الشهر، ونوع الحدث.',
      'تمييز الأحداث بالألوان والنص وليس باللون فقط.',
      'فتح التحليل أو الوصفة أو التشخيص من نفس السجل.',
    ],
  ),
  AppRoute.diagnoses: _ScreenSpec(
    summary: 'إدارة قراءة التشخيصات الحالية والسابقة ودرجة الخطورة.',
    items: [
      'الحالة الحالية والسابقة مع التواريخ.',
      'درجة الخطورة والملاحظات السريرية.',
      'فصل واضح بين القراءة والتعديل حسب الصلاحية.',
    ],
  ),
  AppRoute.prescriptions: _ScreenSpec(
    summary: 'وصفات طبية مع تحذيرات تداخل دوائي وحساسية.',
    items: [
      'اسم الدواء، الجرعة، التكرار، المدة، والحالة.',
      'تحذيرات التداخل الدوائي والحساسية في أعلى الشاشة.',
      'حالات: نشط، موقوف، مكتمل، مع الطباعة أو تصدير PDF وفق الصلاحية.',
    ],
  ),
  AppRoute.labs: _ScreenSpec(
    summary: 'تحاليل وقيم مرجعية وتنبيهات واضحة للقيم الخارجة عن الحدود.',
    items: [
      'النتيجة والقيم الطبيعية والقيم الخارجة عن الحدود.',
      'مقارنة مع آخر تحليل.',
      'علامات خطورة مقروءة بسرعة دون اعتماد على اللون فقط.',
    ],
  ),
  AppRoute.imaging: _ScreenSpec(
    summary: 'عرض الأشعة والملفات الطبية مع تنزيل آمن ومقارنة.',
    items: [
      'مصغرات للفحوصات وبيانات الفحص.',
      'عرض كامل الشاشة ومقارنة بين فحصين.',
      'تحميل مشروط بالسياسة الأمنية.',
    ],
  ),
  AppRoute.vaccines: _ScreenSpec(
    summary: 'حالة اللقاحات والجرعات والتنبيهات القادمة.',
    items: [
      'الجرعات المكتملة والناقصة.',
      'تنبيهات الجرعات القادمة.',
      'حالة واضحة لكل لقاح ضمن جدول قابل للتصفية.',
    ],
  ),
  AppRoute.vitals: _ScreenSpec(
    summary: 'مؤشرات حيوية قابلة للمقارنة والقراءة السريعة.',
    items: [
      'وزن، ضغط، سكر، حرارة، نبض، وأكسجين.',
      'رسوم بيانية لاحقة للمقارنة الزمنية.',
      'تمييز القيم الحرجة بنص واضح وشارة دلالية.',
    ],
  ),
  AppRoute.appointments: _ScreenSpec(
    summary: 'إدارة المواعيد اليومية والأسبوعية والشهرية.',
    items: [
      'عرض يومي وأسبوعي وشهري.',
      'حالات الموعد: مؤكد، مؤجل، ملغى، متأخر.',
      'ربط مباشر بقائمة الانتظار والملف الطبي عند الصلاحية.',
    ],
  ),
  AppRoute.queue: _ScreenSpec(
    summary: 'قائمة انتظار مرتبة حسب الأولوية السريرية ووقت الانتظار.',
    items: [
      'ترتيب المرضى حسب الأولوية السريرية.',
      'وقت الانتظار والحالات الحرجة.',
      'إجراءات سريعة لا تتجاوز الصلاحيات.',
    ],
  ),
  AppRoute.messaging: _ScreenSpec(
    summary: 'مراسلات طبية محكومة ومؤرشفة.',
    items: [
      'محادثات فردية ومجتمعية حسب الدور.',
      'مرفقات آمنة وحالة القراءة والتثبيت.',
      'أرشفة وفق السياسة القانونية.',
    ],
  ),
  AppRoute.administration: _ScreenSpec(
    summary: 'إدارة الأدوار والأجهزة والسياسات للمستخدمين المخولين فقط.',
    items: [
      'أدوار وصلاحيات دقيقة.',
      'أجهزة موثوقة وحدود رؤية وتعديل.',
      'موافقات وسياسات لا تدمج أدوارًا متعارضة في شاشة واحدة.',
    ],
  ),
  AppRoute.auditLogs: _ScreenSpec(
    summary: 'سجل تدقيق كامل وغير قابل للتعديل الصامت.',
    items: [
      'من فتح ماذا، متى، ومن أي جهاز.',
      'محاولات الدخول والإخفاق والتنبيهات الأمنية.',
      'وضع القراءة فقط مع إمكانية التحقيق دون حذف أو تعديل صامت.',
    ],
  ),
};
