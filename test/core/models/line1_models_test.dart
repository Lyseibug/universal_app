import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/models/line1_models.dart';

void main() {
  group('Bag payload parsing', () {
    test('BagItem.fromJson tolerates null and non-string values', () {
      final bag = BagItem.fromJson({
        'batch_no': null,
        'item_code': 123,
        'item_name': 456,
        'qty': '10.5',
        'formula_name': 789,
        'production_datetime': null,
        'machine_production_record': null,
      });

      expect(bag.batchNo, isEmpty);
      expect(bag.itemCode, '123');
      expect(bag.itemName, '456');
      expect(bag.qty, 10.5);
      expect(bag.formulaName, '789');
    });

    test('BagDetail.fromJson handles missing or malformed consume items', () {
      final detail = BagDetail.fromJson({
        'batch_no': 'B-100',
        'item_code': 'ITEM-1',
        'item_name': 'Test Bag',
        'qty': 12,
        'formula_name': null,
        'manufacturing_date': '2026-07-09',
        'machine_production_record': null,
        'consume_items': {
          'item_code': 'MAT-1',
          'item_name': 'Material',
          'batch_no': 'M-1',
          'qty': '2.5',
          'warehouse': 'WH-1',
        },
      });

      expect(detail.batchNo, 'B-100');
      expect(detail.consumeItems, hasLength(1));
      expect(detail.consumeItems.first.itemCode, 'MAT-1');
      expect(detail.consumeItems.first.qty, 2.5);
    });
  });

  group('WorkOrderSummary payload parsing', () {
    test('WorkOrderSummary.fromJson parses the Work Order picker fields', () {
      final wo = WorkOrderSummary.fromJson({
        'name': 'WO-0001',
        'production_item': 'BAG-001',
        'item_name': 'Test Bag',
        'qty': 100,
        'produced_qty': 25.5,
        'bom_no': 'BOM-BAG-001',
        'status': 'Not Started',
      });

      expect(wo.name, 'WO-0001');
      expect(wo.productionItem, 'BAG-001');
      expect(wo.itemName, 'Test Bag');
      expect(wo.qty, 100);
      expect(wo.producedQty, 25.5);
      expect(wo.bomNo, 'BOM-BAG-001');
      expect(wo.status, 'Not Started');
    });

    test('WorkOrderSummary.fromJson tolerates missing optional fields', () {
      final wo = WorkOrderSummary.fromJson({
        'name': 'WO-0002',
        'production_item': 'CMB-001',
      });

      expect(wo.name, 'WO-0002');
      expect(wo.productionItem, 'CMB-001');
      expect(wo.itemName, isNull);
      expect(wo.qty, 0);
      expect(wo.producedQty, 0);
      expect(wo.bomNo, isNull);
      expect(wo.status, isEmpty);
    });
  });
}
