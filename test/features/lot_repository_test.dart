import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/api/api_client.dart';
import 'package:universal_app/core/models/warehouse_models.dart';
import 'package:universal_app/core/sync/write_queue.dart';
import 'package:universal_app/core/sync/write_queue_entry.dart';
import 'package:universal_app/features/lot/lot_repository.dart';

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
  group('LotRepository Tests', () {
    late FakeApiClient fakeApi;
    late FakeWriteQueue fakeWriteQueue;
    late LotRepository repo;

    setUp(() {
      fakeApi = FakeApiClient();
      fakeWriteQueue = FakeWriteQueue();
      repo = LotRepository(api: fakeApi, writeQueue: fakeWriteQueue);
    });

    test('browse returns list of parsed WarehouseLot', () async {
      fakeApi.responseData = [
        {
          'name': 'BIN-A1',
          'warehouse': 'WH-1',
          'zone': 'Z-1',
          'items': [
            {
              'item_code': 'ITEM-1',
              'batch_no': 'B1',
              'fifo_date': '2026-06-18',
              'qty': 100.0,
              'uom': 'Nos',
            }
          ]
        }
      ];

      final result = await repo.browse(warehouse: 'WH-1', zone: 'Z-1', onlyOccupied: true);

      expect(result, hasLength(1));
      expect(result[0].name, equals('BIN-A1'));
      expect(result[0].items, hasLength(1));
      expect(result[0].items[0].itemCode, equals('ITEM-1'));
      expect(result[0].items[0].qty, equals(100.0));
      expect(fakeApi.calls[0]['method'], equals('lot.browse'));
      expect(fakeApi.calls[0]['body']['warehouse'], equals('WH-1'));
      expect(fakeApi.calls[0]['body']['zone'], equals('Z-1'));
      expect(fakeApi.calls[0]['body']['only_occupied'], equals(1));
    });

    test('get returns parsed single WarehouseLot', () async {
      fakeApi.responseData = {
        'name': 'BIN-A1',
        'warehouse': 'WH-1',
        'zone': 'Z-1',
        'items': []
      };

      final result = await repo.get('BIN-A1');

      expect(result.name, equals('BIN-A1'));
      expect(result.warehouse, equals('WH-1'));
      expect(result.items, isEmpty);
      expect(fakeApi.calls[0]['method'], equals('lot.get'));
      expect(fakeApi.calls[0]['body']['lot'], equals('BIN-A1'));
    });

    test('transfer routes to WriteQueue', () async {
      fakeWriteQueue.responseData = {'status': 'transferred'};

      final result = await repo.transfer(
        fromLot: 'BIN-1',
        toLot: 'BIN-2',
        item: 'ITEM-X',
        batchNo: 'B2',
        qty: 15.5,
      );

      expect(result, equals({'status': 'transferred'}));
      expect(fakeWriteQueue.runs, hasLength(1));
      expect(fakeWriteQueue.runs[0]['method'], equals('lot.transfer'));
      expect(fakeWriteQueue.runs[0]['body']['from_lot'], equals('BIN-1'));
      expect(fakeWriteQueue.runs[0]['body']['to_lot'], equals('BIN-2'));
      expect(fakeWriteQueue.runs[0]['body']['item'], equals('ITEM-X'));
      expect(fakeWriteQueue.runs[0]['body']['batch_no'], equals('B2'));
      expect(fakeWriteQueue.runs[0]['body']['qty'], equals(15.5));
    });
  });
}
