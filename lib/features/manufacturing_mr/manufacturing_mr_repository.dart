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

  Future<ManufacturingMRDetail> update({
    required String name,
    List<Map<String, dynamic>>? items,
    String? remarks,
    String? compoundType,
    String? formulaCode,
    String? bom,
    double? requestedCompoundQty,
    String? requestType,
  }) async {
    final data = await _api.call('manufacturing_mr.update', body: {
      'name': name,
      if (items != null) 'items': items,
      if (remarks != null) 'remarks': remarks,
      if (compoundType != null) 'compound_type': compoundType,
      if (formulaCode != null) 'formula_code': formulaCode,
      if (bom != null) 'bom': bom,
      if (requestedCompoundQty != null)
        'requested_compound_qty': requestedCompoundQty,
      if (requestType != null) 'request_type': requestType,
    });
    return ManufacturingMRDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<dynamic> submitMR(String name) async {
    return _writeQueue.run('manufacturing_mr.submit_mr', {
      'name': name,
    });
  }
}

final manufacturingMRRepositoryProvider =
    Provider<ManufacturingMRRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return ManufacturingMRRepository(api: api, writeQueue: writeQueue);
});
