// Tests for the Work Order picker plumbing added to Line1Repository —
// listing open Work Orders per machine, and forwarding the chosen Work
// Order on every write call that used to have no target-item context.
//
// Written as part of the code structure for this change; not executed as
// part of this pass (see the implementation plan's constraints) — run via
// `flutter test` separately.

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/api/api_client.dart';
import 'package:universal_app/core/sync/write_queue.dart';
import 'package:universal_app/core/sync/write_queue_entry.dart';
import 'package:universal_app/features/line1/line1_repository.dart';

class FakeApiClient implements ApiClient {
  final List<Map<String, dynamic>> calls = [];
  dynamic responseData;
  Object? errorToThrow;

  @override
  void Function()? get onUnauthenticated => null;

  @override
  void updateBaseUrl(String newUrl) {}

  @override
  Future<dynamic> call(String method, {Map<String, dynamic>? body}) async {
    calls.add({'method': method, 'body': body});
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseData;
  }
}

class FakeWriteQueue implements WriteQueue {
  final List<Map<String, dynamic>> runs = [];
  dynamic responseData;
  Object? errorToThrow;

  @override
  Future<dynamic> run(String method, Map<String, dynamic> body) async {
    runs.add({'method': method, 'body': body});
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseData;
  }

  @override
  List<WriteQueueEntry> get pendingEntries => [];

  @override
  List<WriteQueueEntry> get allEntries => [];

  @override
  Future<void> flush() async {}

  @override
  Future<void> retry(String id) async {}

  @override
  Future<void> clearSynced() async {}
}

void main() {
  group('Line1Repository Work Order gate', () {
    late FakeApiClient fakeApi;
    late FakeWriteQueue fakeWriteQueue;
    late Line1Repository repo;

    setUp(() {
      fakeApi = FakeApiClient();
      fakeWriteQueue = FakeWriteQueue();
      repo = Line1Repository(api: fakeApi, writeQueue: fakeWriteQueue);
    });

    test('listWeighingWorkOrders calls the right endpoint and parses results', () async {
      fakeApi.responseData = [
        {
          'name': 'WO-0001',
          'production_item': 'BAG-001',
          'item_name': 'Test Bag',
          'qty': 100.0,
          'produced_qty': 0.0,
          'bom_no': 'BOM-BAG-001',
          'status': 'Not Started',
        }
      ];

      final result = await repo.listWeighingWorkOrders();

      expect(fakeApi.calls.single['method'], 'line1_weighing.list_work_orders');
      expect(result, hasLength(1));
      expect(result.first.name, 'WO-0001');
      expect(result.first.productionItem, 'BAG-001');
    });

    test('weighingLoad forwards work_order in the write-queue body', () async {
      fakeWriteQueue.responseData = {
        'stock_entry': 'STE-0001',
        'qty': 5.0,
        'work_order': 'WO-0001',
      };

      await repo.weighingLoad(
        boxBarcode: 'BOX-1',
        itemCode: 'CHEM-1',
        qty: 5,
        workOrder: 'WO-0001',
      );

      final body = fakeWriteQueue.runs.single['body'] as Map<String, dynamic>;
      expect(fakeWriteQueue.runs.single['method'], 'line1_weighing.weighing_load');
      expect(body['work_order'], 'WO-0001');
      expect(body['item_code'], 'CHEM-1');
    });

    test('listMixerWorkOrders calls the right endpoint', () async {
      fakeApi.responseData = <Map<String, dynamic>>[];
      await repo.listMixerWorkOrders();
      expect(fakeApi.calls.single['method'], 'line1_mixer.list_work_orders');
    });

    test('loadToMixer forwards work_order in the write-queue body', () async {
      fakeWriteQueue.responseData = {'stock_entries': []};

      await repo.loadToMixer(
        itemCode: 'CMB-1',
        qty: 10,
        workOrder: 'WO-0002',
        batchNo: 'BATCH-1',
      );

      final body = fakeWriteQueue.runs.single['body'] as Map<String, dynamic>;
      expect(fakeWriteQueue.runs.single['method'], 'line1_mixer.load');
      expect(body['work_order'], 'WO-0002');
      expect(body['batch_no'], 'BATCH-1');
    });

    test('listCalenderingWorkOrders calls the right endpoint', () async {
      fakeApi.responseData = <Map<String, dynamic>>[];
      await repo.listCalenderingWorkOrders();
      expect(fakeApi.calls.single['method'], 'line1_calendering.list_work_orders');
    });

    test('startRunFromBatches forwards work_order in the write-queue body', () async {
      fakeWriteQueue.responseData = {
        'name': 'CAL-2026-00001',
        'work_order': 'WO-0003',
        'fmb_item': 'FMB-1',
        'fmb_sources': [],
        'input_qty': 20.0,
        'status': 'In Progress',
      };

      await repo.startRunFromBatches(
        [
          {'batch_no': 'FMB-BATCH-1', 'qty': 20.0}
        ],
        'WO-0003',
      );

      final body = fakeWriteQueue.runs.single['body'] as Map<String, dynamic>;
      expect(fakeWriteQueue.runs.single['method'],
          'line1_calendering.start_run_from_batches');
      expect(body['work_order'], 'WO-0003');
    });

    test('a rejected Work Order/BOM mismatch surfaces as an exception', () async {
      fakeWriteQueue.errorToThrow =
          Exception("'CHEM-2' is not a component of Work Order WO-0001's BOM");

      expect(
        () => repo.weighingLoad(
          boxBarcode: 'BOX-1',
          itemCode: 'CHEM-2',
          qty: 5,
          workOrder: 'WO-0001',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
