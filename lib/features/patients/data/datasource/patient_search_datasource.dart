import 'dart:developer';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/patient_search_models.dart';

class PatientSearchDatasource {
  const PatientSearchDatasource();

  Future<({List<PatientSearchResult> patients, int total})> getPatients({
    String search = '',
    int page = 1,
  }) async {
    log('[PatientSearchDatasource] Recherche: "$search" page: $page');

    final params = <String, String>{'page': page.toString()};
    if (search.isNotEmpty) params['search'] = search;

    final data = await ApiClient.get(
      ApiEndpoints.doctorGetPatients,
      queryParams: params,
    );

    final list = (data['patients'] as List? ?? [])
        .map((e) => PatientSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();

    return (patients: list, total: data['total'] as int? ?? 0);
  }
}
