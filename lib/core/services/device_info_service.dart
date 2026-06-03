// lib/core/services/device_info_service.dart

import 'dart:io';
import 'dart:developer';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfo {
  final String deviceName;
  final String operatingSystem;
  final String appVersion;
  final String lastLogin;       // "Première connexion" ou date formatée
  final DateTime loginDateTime; // Date réelle pour l'audit log

  const DeviceInfo({
    required this.deviceName,
    required this.operatingSystem,
    required this.appVersion,
    required this.lastLogin,
    required this.loginDateTime,
  });
}

class DeviceInfoService {
  DeviceInfoService._();

  static const _kLastLoginKey = 'sahhti_last_login';

  static Future<DeviceInfo> load() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final prefs       = await SharedPreferences.getInstance();

      // Date du DERNIER login (avant ce lancement)
      final lastLoginRaw  = prefs.getString(_kLastLoginKey);
      final lastLoginStr  = lastLoginRaw != null
          ? _formatLastLogin(DateTime.parse(lastLoginRaw))
          : 'Première connexion';

      // Enregistrer le login ACTUEL pour la prochaine fois
      await prefs.setString(
        _kLastLoginKey,
        DateTime.now().toIso8601String(),
      );

      return DeviceInfo(
        deviceName:      _getDeviceName(),
        operatingSystem: _getOs(),
        appVersion:      'v${packageInfo.version}+${packageInfo.buildNumber}',
        lastLogin:       lastLoginStr,
        loginDateTime:   DateTime.now(),
      );
    } catch (e) {
      log('[DeviceInfoService] Erreur: $e');
      return DeviceInfo(
        deviceName:      Platform.localHostname,
        operatingSystem: Platform.operatingSystem,
        appVersion:      'v1.0.0',
        lastLogin:       'Première connexion',
        loginDateTime:   DateTime.now(),
      );
    }
  }

  static String _getDeviceName() {
    final host = Platform.localHostname;
    if (Platform.isMacOS)   return 'Mac — $host';
    if (Platform.isWindows) return 'Windows — $host';
    if (Platform.isLinux)   return 'Linux — $host';
    return host;
  }

  static String _getOs() {
    final version = Platform.operatingSystemVersion;
    if (Platform.isMacOS)   return 'macOS $version';
    if (Platform.isWindows) return 'Windows $version';
    if (Platform.isLinux)   return 'Linux $version';
    return version;
  }

  static String _formatLastLogin(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    final hh   = dt.hour.toString().padLeft(2, '0');
    final mm   = dt.minute.toString().padLeft(2, '0');

    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inHours   < 1)  return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays    < 1)  return 'Aujourd\'hui $hh:$mm';
    if (diff.inDays   == 1)  return 'Hier $hh:$mm';
    return '${dt.day.toString().padLeft(2,'0')}/'
           '${dt.month.toString().padLeft(2,'0')}/'
           '${dt.year}  $hh:$mm';
  }
}