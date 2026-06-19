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
        }
      ];

      final result = await repo.listPending();

      expect(result, hasLength(1));
      expect(result[0].name, equals('line-1'));
      expect(result[0].itemCode, equals('ITEM-A'));
      expect(result[0].pendingQty, equals(10.0));
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

    test('putAway routes to WriteQueue', () async {
      fakeWriteQueue.responseData = {'status': 'queued'};

      final result = await repo.putAway(
        receivedItemLine: 'line-1',
        lot: 'LOT-A',
        qty: 5.0,
        productionDate: '2026-06-18',
        expiryDate: '2027-06-18',
        forceCapacity: true,
      );

      expect(result, equals({'status': 'queued'}));
      expect(fakeWriteQueue.runs, hasLength(1));
      expect(fakeWriteQueue.runs[0]['method'], equals('grn.put_away'));
      expect(fakeWriteQueue.runs[0]['body']['received_item_line'], equals('line-1'));
      expect(fakeWriteQueue.runs[0]['body']['lot'], equals('LOT-A'));
      expect(fakeWriteQueue.runs[0]['body']['qty'], equals(5.0));
      expect(fakeWriteQueue.runs[0]['body']['production_date'], equals('2026-06-18'));
      expect(fakeWriteQueue.runs[0]['body']['expiry_date'], equals('2027-06-18'));
      expect(fakeWriteQueue.runs[0]['body']['force_capacity'], equals(1));
    });
  });
}
