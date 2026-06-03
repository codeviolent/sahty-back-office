import 'dart:developer';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../models/queue_models.dart';

class QueueDatasource {
  const QueueDatasource();

  Future<List<QueueItem>> getQueue() async {
    log('[QueueDatasource] Chargement file d\'attente...');
    final data = await ApiClient.get(
      ApiEndpoints.doctorGetFileAttente,
      queryParams: {'mode': 'queue'},
    );
    log('[QueueDatasource] Données reçues: $data');
    final list = data['queue'] as List? ?? [];
    return list
        .map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}