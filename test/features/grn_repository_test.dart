import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/api/api_client.dart';
import 'package:universal_app/core/models/warehouse_models.dart';
import 'package:universal_app/core/sync/write_queue.dart';
import 'package:universal_app/core/sync/write_queue_entry.dart';
import 'package:universal_app/features/grn/grn_repository.dart';

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

  @override
  Future<dynamic> run(String method, Map<String, dynamic> body) async {
    runs.add({'method': method, 'body': body});
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
  group('GrnRepository Tests', () {
    late FakeApiClient fakeApi;
    late FakeWriteQueue fakeWriteQueue;
    late GrnRepository repo;

    setUp(() {
      fakeApi = FakeApiClient();
      fakeWriteQueue = FakeWriteQueue();
      repo = GrnRepository(api: fakeApi, writeQueue: fakeWriteQueue);
    });

    test('listPending returns parsed ReceivedItemLine list', () async {
      fakeApi.responseData = [
        {
          'name': 'line-1',
          'parent': 'GRN-001',
          'item_code': 'ITEM-A',
          'item_name': 'Item A',
          'pending_qty': 10.0,
          'uom': 'Nos',
          'warehouse': 'WH-A',
          'batch_no': 'BATCH-STG-1',
          'received_qty': 10.0,
          'batch_qty_created': 0.0,
          'pending_batch_qty': 10.0,
          'bin_allocated_quantity': 0.0,
        }
      ];

      final result = await repo.listPending();

      expect(result, hasLength(1));
      expect(result[0].name, equals('line-1'));
      expect(result[0].itemCode, equals('ITEM-A'));
      expect(result[0].pendingQty, equals(10.0));
      expect(result[0].batchNo, equals('BATCH-STG-1'));
      expect(result[0].pendingBatchQty, equals(10.0));
      expect(fakeApi.calls[0]['method'], equals('grn.list_pending'));
    });

    test('suggestLot returns valid suggestion or null on failure', () async {
      fakeApi.responseData = {
        'lot': 'LOT-123',
        'available_qty': 50.0,
      };

      final result = await repo.suggestLot('line-1');

      expect(result, isNotNull);
      expect(result!.lot, equals('LOT-123'));
      expect(result.availableQty, equals(50.0));
      expect(fakeApi.calls[0]['method'], equals('grn.suggest_lot'));
      expect(fakeApi.calls[0]['body']['received_item_line'], equals('line-1'));
    });

    test('createBatch routes to WriteQueue', () async {
      fakeWriteQueue.responseData = {
        'batch_no': 'BATCH-00457',
        'stock_entry': 'STE-00123'
      };

      final result = await repo.createBatch(
        receivedItemLine: 'line-1',
        qty: 40.0,
        productionDate: '2026-01-15',
        expiryDate: '2027-01-15',
      );

      expect(result['batch_no'], equals('BATCH-00457'));
      expect(fakeWriteQueue.runs, hasLength(1));
      expect(fakeWriteQueue.runs[0]['method'], equals('grn.create_batch'));
      expect(fakeWriteQueue.runs[0]['body']['received_item_line'], equals('line-1'));
      expect(fakeWriteQueue.runs[0]['body']['qty'], equals(40.0));
      expect(fakeWriteQueue.runs[0]['body']['production_date'], equals('2026-01-15'));
      expect(fakeWriteQueue.runs[0]['body']['expiry_date'], equals('2027-01-15'));
    });

    test('printLabel routes to WriteQueue', () async {
      fakeWriteQueue.responseData = {
        'print_job': 'PJ-00012',
        'status': 'Queued'
      };

      final result = await repo.printLabel(
        referenceDoctype: 'Batch',
        referenceName: 'BATCH-00457',
        printFormat: 'Batch Label',
        printer: 'Label Printer - WH-A',
      );

      expect(result['print_job'], equals('PJ-00012'));
      expect(fakeWriteQueue.runs, hasLength(1));
      expect(fakeWriteQueue.runs[0]['method'], equals('grn.print_label'));
      expect(fakeWriteQueue.runs[0]['body']['reference_doctype'], equals('Batch'));
      expect(fakeWriteQueue.runs[0]['body']['reference_name'], equals('BATCH-00457'));
      expect(fakeWriteQueue.runs[0]['body']['print_format'], equals('Batch Label'));
      expect(fakeWriteQueue.runs[0]['body']['printer'], equals('Label Printer - WH-A'));
    });

    test('listCreatedBatches returns parsed GrnBatch list', () async {
      fakeApi.responseData = [
        {
          'batch_no': 'BATCH-00457',
          'production_date': '2026-01-15',
          'expiry_date': '2027-01-15',
          'available_qty': 40.0,
        }
      ];

      final result = await repo.listCreatedBatches('line-1');

      expect(result, hasLength(1));
      expect(result[0].batchNo, equals('BATCH-00457'));
      expect(result[0].availableQty, equals(40.0));
      expect(fakeApi.calls[0]['method'], equals('grn.list_created_batches'));
      expect(fakeApi.calls[0]['body']['received_item_line'], equals('line-1'));
    });

    test('allocateToBin routes to WriteQueue', () async {
      fakeWriteQueue.responseData = {'status': 'success'};

      final result = await repo.allocateToBin(
        receivedItemLine: 'line-1',
        lot: 'LOT-A',
        qty: 40.0,
        batchNo: 'BATCH-00457',
        forceCapacity: true,
      );

      expect(result, equals({'status': 'success'}));
      expect(fakeWriteQueue.runs, hasLength(1));
      expect(fakeWriteQueue.runs[0]['method'], equals('grn.allocate_to_bin'));
      expect(fakeWriteQueue.runs[0]['body']['received_item_line'], equals('line-1'));
      expect(fakeWriteQueue.runs[0]['body']['lot'], equals('LOT-A'));
      expect(fakeWriteQueue.runs[0]['body']['qty'], equals(40.0));
      expect(fakeWriteQueue.runs[0]['body']['batch_no'], equals('BATCH-00457'));
      expect(fakeWriteQueue.runs[0]['body']['force_capacity'], equals(1));
    });
  });
}
