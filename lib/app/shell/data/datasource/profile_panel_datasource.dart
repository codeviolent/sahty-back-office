import 'dart:developer';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/profile_models.dart';

class ProfilePanelDatasource {
  const ProfilePanelDatasource();

  Future<UserProfile> loadMyProfile() async {
    log('[ProfilePanelDatasource] Chargement profil...');
    final data = await ApiClient.get(ApiEndpoints.getMyProfile);
    return UserProfile.fromJson(data);
  }
}