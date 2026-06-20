import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:universal_app/core/api/api_client.dart';
import 'package:universal_app/core/menu/menu_models.dart';
import 'package:universal_app/core/models/warehouse_models.dart';
import 'package:universal_app/core/sync/write_queue.dart';
import 'package:universal_app/core/sync/write_queue_entry.dart';
import 'package:universal_app/features/grn/grn_putaway_screen.dart';
import 'package:universal_app/features/grn/grn_repository.dart';
import 'package:universal_app/providers/service_providers.dart';
import 'package:universal_app/core/scanner/scan_service.dart';

class MockGrnRepository implements GrnRepository {
  List<ReceivedItemLine> pendingList = [];
  List<GrnBatch> batchesList = [];
  Map<String, dynamic> createBatchResponse = {};
  dynamic printLabelResponse = {};
  dynamic allocateToBinResponse = {};

  @override
  Future<List<ReceivedItemLine>> listPending() async {
    return pendingList;
  }

  @override
  Future<ReceivedItemLine> getReceivedItem(String receivedItem) async {
    return pendingList.firstWhere((e) => e.name == receivedItem);
  }

  @override
  Future<LotSuggestion?> suggestLot(String receivedItemLine) async {
    return const LotSuggestion(lot: 'F-CA-1', availableQty: 80.0);
  }

  @override
  Future<Map<String, dynamic>> createBatch({
    required String receivedItemLine,
    required double qty,
    required String productionDate,
    String? expiryDate,
  }) async {
    return createBatchResponse;
  }

  @override
  Future<dynamic> printLabel({
    required String referenceDoctype,
    required String referenceName,
    required String printFormat,
    String? printer,
  }) async {
    return printLabelResponse;
  }

  @override
  Future<List<GrnBatch>> listCreatedBatches(String receivedItemLine) async {
    return batchesList;
  }

  @override
  Future<dynamic> allocateToBin({
    required String receivedItemLine,
    required String lot,
    required double qty,
    required String batchNo,
    bool forceCapacity = false,
  }) async {
    return allocateToBinResponse;
  }
}

class FakeWriteQueue implements WriteQueue {
  @override
  Future<dynamic> run(String method, Map<String, dynamic> body) async {
    return null;
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
  group('GrnPutAwayScreen Widget Tests - Two-Step Flow', () {
    late MockGrnRepository mockRepo;
    late KeyboardWedgeScanService scanService;
    late Directory tempDir;
    late Box<WriteQueueEntry> writeQueueBox;
    late Box<dynamic> settingsBox;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('grn_putaway_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(WriteQueueEntryAdapter());
      }
      writeQueueBox = await Hive.openBox<WriteQueueEntry>('write_queue');
      settingsBox = await Hive.openBox<dynamic>('settings');

      mockRepo = MockGrnRepository();
      scanService = KeyboardWedgeScanService();
    });

    tearDown(() async {
      scanService.dispose();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Widget buildTestWidget() {
      final menuJson = {
        'screen_key': 'grn_putaway',
        'label': 'GRN Put-Away',
        'route': '/grn-putaway',
        'api_module': 'grn',
        'actions': ['create_batch', 'allocate_bin', 'override_capacity'],
        'icon': 'archive'
      };
      final screen = MenuScreen.fromJson(menuJson);

      return ProviderScope(
        overrides: [
          grnRepositoryProvider.overrideWithValue(mockRepo),
          keyboardScanServiceProvider.overrideWithValue(scanService),
          writeQueueProvider.overrideWithValue(FakeWriteQueue()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GrnPutAwayScreen(screen: screen),
          ),
        ),
      );
    }

    testWidgets('Complete two-step flow matches update plan specifications', (WidgetTester tester) async {
      mockRepo.pendingList = [
        const ReceivedItemLine(
          name: 'line-1',
          parent: 'RI-MAT-REC-00001',
          itemCode: 'P-POLYMER-001',
          itemName: 'Polymer Grade A',
          pendingQty: 100.0,
          uom: 'KG',
          warehouse: 'WH-A',
          receivedQty: 100.0,
          batchQtyCreated: 0.0,
          pendingBatchQty: 100.0,
          binAllocatedQuantity: 0.0,
        )
      ];

      mockRepo.batchesList = [];
      mockRepo.createBatchResponse = {
        'batch_no': 'BATCH-00457',
        'stock_entry': 'STE-00123'
      };
      mockRepo.printLabelResponse = {
        'print_job': 'PJ-00012',
        'status': 'Queued'
      };
      mockRepo.allocateToBinResponse = {
        'status': 'success'
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Verify pending line in List View
      expect(find.text('P-POLYMER-001 (Polymer Grade A)'), findsOneWidget);
      expect(find.text('GRN: RI-MAT-REC-00001 | Line: line-1'), findsOneWidget);

      // Tap the pending line
      await tester.tap(find.text('P-POLYMER-001 (Polymer Grade A)'));
      await tester.pumpAndSettle();

      // 2. Verify RI Line Detail View metrics
      expect(find.text('Put-Away Details'), findsOneWidget);
      expect(find.text('Received Quantity:'), findsOneWidget);
      expect(find.text('Pending Batch Split:'), findsOneWidget);
      expect(find.text('100.0 KG'), findsAtLeastNWidgets(2));
      expect(find.text('Create Batch'), findsOneWidget);
      expect(find.text('Allocate to Bin'), findsOneWidget);

      // 3. Step 1: Create Batch Flow
      await tester.tap(find.text('Create Batch'));
      await tester.pumpAndSettle();

      expect(find.text('Create Batch'), findsOneWidget);
      expect(find.text('Remaining to split: 100.0 KG'), findsOneWidget);

      // Enter splitting details
      final qtyInput = find.widgetWithText(TextFormField, 'Batch Quantity');
      expect(qtyInput, findsOneWidget);
      await tester.enterText(qtyInput, '40.0');

      // Tap Create and Print
      final createBtn = find.text('CREATE & PRINT');
      expect(createBtn, findsOneWidget);

      // Mock update to reload pending & batches list after creation
      mockRepo.pendingList = [
        const ReceivedItemLine(
          name: 'line-1',
          parent: 'RI-MAT-REC-00001',
          itemCode: 'P-POLYMER-001',
          itemName: 'Polymer Grade A',
          pendingQty: 100.0,
          uom: 'KG',
          warehouse: 'WH-A',
          receivedQty: 100.0,
          batchQtyCreated: 40.0,
          pendingBatchQty: 60.0,
          binAllocatedQuantity: 0.0,
        )
      ];
      mockRepo.batchesList = [
        const GrnBatch(
          batchNo: 'BATCH-00457',
          productionDate: '2026-01-15',
          expiryDate: '2027-01-15',
          availableQty: 40.0,
        )
      ];

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Should show success print notification toast/alert, then return to Detail
      expect(find.textContaining('created and sent to printer!'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(GrnPutAwayScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      expect(find.text('Put-Away Details'), findsOneWidget);
      expect(find.text('Pending Batch Split:'), findsOneWidget);
      expect(find.text('60.0 KG'), findsOneWidget); // Pending batch reduced
      expect(find.text('BATCH-00457'), findsOneWidget); // Batch listed at the bottom

      // 4. Step 2: Bin Allocation Flow
      await tester.tap(find.text('Allocate to Bin'));
      await tester.pumpAndSettle();

      expect(find.text('Select Batch'), findsOneWidget);
      expect(find.text('BATCH-00457'), findsOneWidget);

      // Tap the batch to allocate
      await tester.tap(find.text('BATCH-00457'));
      await tester.pumpAndSettle();

      expect(find.text('Allocate to Bin'), findsOneWidget);
      expect(find.text('Batch: BATCH-00457'), findsOneWidget);
      
      // Enter allocation details
      final binInput = find.widgetWithText(TextFormField, 'Scan Bin');
      final lotInput = find.widgetWithText(TextFormField, 'Scan Lot');
      final allocQtyInput = find.widgetWithText(TextFormField, 'Allocation Qty');
      
      expect(binInput, findsOneWidget);
      expect(lotInput, findsOneWidget);
      expect(allocQtyInput, findsOneWidget);

      await tester.enterText(binInput, 'BIN-01');
      await tester.enterText(lotInput, 'LOT-01');
      await tester.enterText(allocQtyInput, '40.0');

      // Mock listPending update for allocation completion
      mockRepo.pendingList = [
        const ReceivedItemLine(
          name: 'line-1',
          parent: 'RI-MAT-REC-00001',
          itemCode: 'P-POLYMER-001',
          itemName: 'Polymer Grade A',
          pendingQty: 60.0,
          uom: 'KG',
          warehouse: 'WH-A',
          receivedQty: 100.0,
          batchQtyCreated: 40.0,
          pendingBatchQty: 60.0,
          binAllocatedQuantity: 40.0,
        )
      ];
      mockRepo.batchesList = []; // Batch is now allocated and empty in WH-A

      // Tap Allocate
      await tester.ensureVisible(find.text('ALLOCATE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ALLOCATE'));
      await tester.pumpAndSettle();

      // Verify returned to detail view with updated metrics
      expect(find.textContaining('allocated to LOT-01 successful!'), findsOneWidget);
      expect(find.text('Put-Away Details'), findsOneWidget);
      expect(find.text('Pending Bin Allocation:'), findsOneWidget);
      expect(find.text('60.0 KG'), findsAtLeastNWidgets(2)); // Remaining pending alloc
    });
  });
}
