import 'package:flutter/material.dart';

import '../../core/menu/menu_models.dart';
import '../../features/grn/grn_putaway_screen.dart';
import '../../features/lot/lot_browser_screen.dart';
import '../../features/lot/manual_transfer_screen.dart';
import '../../features/physical_inventory/physical_inventory_screen.dart';
import '../../features/pick/pick_list_screen.dart';
import '../../features/manufacturing_mr/manufacturing_mr_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/line1/material_loading_screen.dart';
import '../../features/line1/bag_viewer_screen.dart';
import '../../features/line1/compound_lab_test_screen.dart';
import '../../features/line1/calendering_screen.dart';
import '../../features/line1/oil_loading_screen.dart';
import '../../features/line1/silo_loading_screen.dart';
import '../../features/line1/weighing_screen.dart';
import '../../features/po_reception/po_reception_screen.dart';
import '../../features/line2/active_jobs_screen.dart';
import '../../features/line2/sleeve_building_screen.dart';
import '../../features/line2/curing_screen.dart';
import '../../features/line2/processing_screen.dart';
import '../../features/line2/labelling_screen.dart';
import '../../features/line2/qc_measurement_screen.dart';
import '../../features/line2/qc_final_screen.dart';
import '../../features/line2/sleeve_creation_screen.dart';
import '../../features/line2/packing_screen.dart';
import '../../features/line2/tool_status_screen.dart';

/// Function type for building a WMS screen from its [MenuScreen] config.
typedef ScreenBuilder = Widget Function(MenuScreen screen);

/// Maps [MenuScreen.screenKey] → widget builder.
///
/// Screens not present in this registry are silently skipped, providing
/// forward-compatibility: the server can add new screen keys via fixture
/// without requiring every device to update the app first.
final Map<String, ScreenBuilder> screenRegistry = {
  'grn_putaway':        (s) => GrnPutAwayScreen(screen: s),
  'pick_list':          (s) => PickListScreen(screen: s),
  'physical_inventory': (s) => PhysicalInventoryScreen(screen: s),
  'lot_browser':        (s) => LotBrowserScreen(screen: s),
  'manual_transfer':    (s) => ManualTransferScreen(screen: s),
  'support':            (s) => SupportScreen(screen: s),
  'manufacturing_mr':   (s) => ManufacturingMRScreen(screen: s),
  'material_loading':   (s) => MaterialLoadingScreen(screen: s),
  'bag_view':           (s) => BagViewerScreen(screen: s),
  'compound_lab_test':  (s) => CompoundLabTestScreen(screen: s),
  'calendering':        (s) => CalenderingScreen(screen: s),
  'oil_loading':        (s) => OilLoadingScreen(screen: s),
  'silo_loading':       (s) => SiloLoadingScreen(screen: s),
  'weighing':           (s) => WeighingScreen(screen: s),
  'po_reception':       (s) => PoReceptionScreen(screen: s),
  // Line 2 — Belt/Sleeve Building
  'line2_active_jobs':  (s) => ActiveJobsScreen(screen: s),
  'line2_building':     (s) => SleeveBuildingScreen(screen: s),
  'line2_curing':       (s) => CuringScreen(screen: s),
  'line2_processing':   (s) => ProcessingScreen(screen: s),
  'line2_labelling':    (s) => LabellingScreen(screen: s),
  'line2_qc_measure':   (s) => QcMeasurementScreen(screen: s),
  'line2_qc_final':     (s) => QcFinalScreen(screen: s),
  'line2_sleeve':       (s) => SleeveCreationScreen(screen: s),
  'line2_packing':      (s) => PackingScreen(screen: s),
  'line2_tools':        (s) => ToolStatusScreen(screen: s),
};
