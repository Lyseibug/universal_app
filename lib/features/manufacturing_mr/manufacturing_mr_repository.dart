import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/manufacturing_mr_models.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

class ManufacturingMRRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  ManufacturingMRRepository(
      {required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  Future<List<ManufacturingMR>> listMRs({String? status}) async {
    final data = await _api.call('manufacturing_mr.list_mrs', body: {
      if (status != null) 'status': status,
    });
    if (data is List) {
      return data
          .map((j) =>
              ManufacturingMR.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<ManufacturingMRDetail> getMR(String name) async {
    final data =
        await _api.call('manufacturing_mr.get_mr', body: {'name': name});
    return ManufacturingMRDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<dynamic> create({
    required List<Map<String, dynamic>> items,
    String? remarks,
  }) async {
    return _writeQueue.run('manufacturing_mr.create', {
      'items': items,
      if (remarks != null) 'remarks': remarks,
    });
  }
}

final manufacturingMRRepositoryProvider =
    Provider<ManufacturingMRRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return ManufacturingMRRepository(api: api, writeQueue: writeQueue);
});
