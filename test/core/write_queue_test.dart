import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:universal_app/core/api/api_client.dart';
import 'package:universal_app/core/api/api_exceptions.dart';
import 'package:universal_app/core/sync/write_queue.dart';
import 'package:universal_app/core/sync/write_queue_entry.dart';

class FakeApiClient implements ApiClient {
  final List<Map<String, dynamic>> calls = [];
  dynamic responseData;
  Object? errorToThrow;
  Future<dynamic> Function(String, {Map<String, dynamic>? body})? callHandler;

  @override
  void Function()? get onUnauthenticated => null;

  @override
  void updateBaseUrl(String newUrl) {}

  @override
  Future<dynamic> call(String method, {Map<String, dynamic>? body}) async {
    calls.add({'method': method, 'body': body});
    if (callHandler != null) {
      return callHandler!(method, body: body);
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseData;
  }
}

void main() {
  late Directory tempDir;
  late Box<WriteQueueEntry> box;
  late FakeApiClient fakeApi;
  late WriteQueue writeQueue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('write_queue_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(WriteQueueEntryAdapter());
    }
    box = await Hive.openBox<WriteQueueEntry>('test_write_queue');
    fakeApi = FakeApiClient();
    writeQueue = WriteQueue(apiClient: fakeApi, box: box);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WriteQueue Tests', () {
    test('run() immediately executes call on API and marks synced on success', () async {
      fakeApi.responseData = {'ok': true};

      final result = await writeQueue.run('grn.put_away', {'item': 'item-01'});

      expect(result, equals({'ok': true}));
      expect(fakeApi.calls, hasLength(1));
      expect(fakeApi.calls.first['method'], equals('grn.put_away'));
      expect(fakeApi.calls.first['body']['item'], equals('item-01'));
      expect(fakeApi.calls.first['body']['request_id'], isNotNull);

      // Verify stored in hive as synced
      final storedId = fakeApi.calls.first['body']['request_id'].toString();
      final entry = box.get(storedId);
      expect(entry, isNotNull);
      expect(entry!.status, equals(QueueStatus.synced));
    });

    test('run() saves as failed and rethrows on business ApiException', () async {
      fakeApi.errorToThrow = const ApiException('BIN_FULL', 'Bin is full');

      await expectLater(
        () => writeQueue.run('grn.put_away', {'item': 'item-01'}),
        throwsA(isA<ApiException>()),
      );

      expect(fakeApi.calls, hasLength(1));
      final storedId = fakeApi.calls.first['body']['request_id'].toString();
      final entry = box.get(storedId);
      expect(entry, isNotNull);
      expect(entry!.status, equals(QueueStatus.failed));
      expect(entry.errorMessage, equals('Bin is full'));
    });

    test('run() saves as pending and rethrows on connection/network error', () async {
      fakeApi.errorToThrow = SocketException('Failed to connect');

      await expectLater(
        () => writeQueue.run('grn.put_away', {'item': 'item-01'}),
        throwsA(isA<SocketException>()),
      );

      expect(fakeApi.calls, hasLength(1));
      final storedId = fakeApi.calls.first['body']['request_id'].toString();
      final entry = box.get(storedId);
      expect(entry, isNotNull);
      expect(entry!.status, equals(QueueStatus.pending));
    });

    test('flush() processes pending writes and marks DUPLICATE_REQUEST as synced', () async {
      // Simulate two failed writes previously enqueued
      final entry1 = WriteQueueEntry(
        id: 'req-1',
        method: 'grn.put_away',
        bodyJson: '{"item": "item-01", "request_id": "req-1"}',
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
      );
      final entry2 = WriteQueueEntry(
        id: 'req-2',
        method: 'grn.put_away',
        bodyJson: '{"item": "item-02", "request_id": "req-2"}',
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
      );

      await box.put('req-1', entry1);
      await box.put('req-2', entry2);

      // First call succeeds, second call throws DUPLICATE_REQUEST
      int callCount = 0;
      fakeApi.errorToThrow = null;
      fakeApi.responseData = {'ok': true};

      // We override API call to return duplicate request for the second call
      fakeApi.callHandler = (method, {body}) async {
        callCount++;
        if (callCount == 2) {
          throw const ApiException('DUPLICATE_REQUEST', 'Duplicate entry');
        }
        return {'ok': true};
      };

      await writeQueue.flush();

      expect(box.get('req-1')!.status, equals(QueueStatus.synced));
      expect(box.get('req-2')!.status, equals(QueueStatus.synced));
    });
  });
}
