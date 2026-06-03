class ApiEndpoints {
  ApiEndpoints._();

  static const String supabaseUrl = 'https://ymmdyaqjuallibixpeil.supabase.co';
  static const String anonKey =
      'sb_publishable_MMhux97CTu6TO5VQbVkdeg_CDAr6Xzw';
  //'sb_publishable_MMhux97CTu6TO5VQbVkdeg_CDAr6Xzw';

  static const String _base = '$supabaseUrl/functions/v1';
  static const String _auth = '$supabaseUrl/auth/v1';

  // ── Auth ─────────────────────────────────────────────────────
  static const String login = '$_auth/token?grant_type=password';
  static const String logout = '$_auth/logout';
  static const String user = '$_auth/user';

  // ── Patient ──────────────────────────────────────────────────
  static const String verifyNni = '$_base/verify-nni';
  static const String createPatientProfile = '$_base/create-patient-profile';
  static const String getHomeData = '$_base/get-home-data';
  static const String getDossierSection = '$_base/get-dossier-section';
  static const String getAppointments = '$_base/get-appointments';
  static const String bookAppointment = '$_base/book-appointment';
  static const String cancelAppointment = '$_base/cancel-appointment';
  static const String getConversations = '$_base/get-conversations';
  static const String sendMessage = '$_base/send-message';
  static const String getPatientProfile = '$_base/get-patient-profile';
  static const String updatePatientProfile = '$_base/update-patient-profile';
  static const String changePin = '$_base/change-pin';
  static const String getDoctorsPublic = '$_base/get-doctors-public';
  static const String getDoctorAvailabilities =
      '$_base/get-doctor-availabilities';
  static const String getUserRole = '$_base/get-user-role';

  // ── Médecin ───────────────────────────────────────────────────
  static const String doctorVerifyPatientAccess =
      '$_base/doctor-verify-patient-access';
  static const String doctorGetPatientDossier =
      '$_base/doctor-get-patient-dossier';
  static const String doctorGetAgenda = '$_base/doctor-get-agenda';
  static const String doctorGetFileAttente = '$_base/doctor-get-file-attente';
  static const String doctorUpdateAppointment =
      '$_base/doctor-update-appointment';
  static const String doctorAddMedicalRecord =
      '$_base/doctor-add-medical-record';
  static const String doctorGetStats = '$_base/doctor-get-stats';
  static const String getMyProfile = '$_base/get-my-profile';
  static const String doctorGetPatients = '$_base/doctor-get-patients';

  // ── Admin ─────────────────────────────────────────────────────
  static const String adminGetStats = '$_base/admin-get-stats';
  static const String adminCreateUser = '$_base/admin-create-user';

  // ── Pharmacien ────────────────────────────────────────────────
  static const String pharmacistGetPrescription =
      '$_base/pharmacist-get-prescription';
  static const String pharmacistDispense = '$_base/pharmacist-dispense';

  // ── Système ───────────────────────────────────────────────────
  static const String registerFcmToken = '$_base/register-fcm-token';
}
