import 'package:flutter/material.dart';

import '../../core/menu/menu_models.dart';
import '../../features/grn/grn_putaway_screen.dart';
import '../../features/lot/lot_browser_screen.dart';
import '../../features/lot/manual_transfer_screen.dart';
import '../../features/physical_inventory/physical_inventory_screen.dart';
import '../../features/pick/pick_list_screen.dart';
import '../../features/manufacturing_mr/manufacturing_mr_screen.dart';
import '../../features/tool_requests/tool_requests_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/chat/group_chat_list_screen.dart';
import '../../features/chat/direct_chat_list_screen.dart';
import '../../features/line1/material_loading_screen.dart';
import '../../features/line1/mixer_loading_screen.dart';
import '../../features/line1/bag_viewer_screen.dart';
import '../../features/line1/compound_lab_test_screen.dart';
import '../../features/line1/calendering_screen.dart';
import '../../features/line1/cutting_screen.dart';
import '../../features/line1/weighing_screen.dart';
import '../../features/po_reception/po_reception_screen.dart';
import '../../features/line2/active_jobs_screen.dart';
import '../../features/line2/line2_production_screen.dart';
import '../../features/line2/labelling_screen.dart';
import '../../features/line2/qc_measurement_screen.dart';
import '../../features/line2/qc_final_screen.dart';
import '../../features/line2/sleeve_creation_screen.dart';
import '../../features/line2/packing_screen.dart';
import '../../features/line2/reception_screen.dart';
import '../../features/line2/tool_status_screen.dart';
import '../../features/fabric_stitching/fabric_stitching_screen.dart';

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
  'chat_groups':        (s) => GroupChatListScreen(screen: s),
  'chat_direct':        (s) => DirectChatListScreen(screen: s),
  'manufacturing_mr':   (s) => ManufacturingMRScreen(screen: s),
  'tool_requests':      (s) => ToolRequestsScreen(screen: s),
  'material_loading':   (s) => MaterialLoadingScreen(screen: s),
  'mixer_loading':      (s) => MixerLoadingScreen(screen: s),
  'bag_view':           (s) => BagViewerScreen(screen: s),
  'compound_lab_test':  (s) => CompoundLabTestScreen(screen: s),
  'calendering':        (s) => CalenderingScreen(screen: s),
  'cutting':            (s) => CuttingScreen(screen: s),
  // 'oil_loading' / 'silo_loading' intentionally absent: the legacy loading
  // screens bypass tank-capacity validation — use 'material_loading' for both
  // streams (GOLIVE-DOC §10, Finding #17).
  'weighing_load':      (s) => WeighingScreen(screen: s),
  'po_reception':       (s) => PoReceptionScreen(screen: s),
  // Line 2 — Belt/Sleeve Building
  'line2_active_jobs':  (s) => ActiveJobsScreen(screen: s),
  // Building/Curing/Processing share one adaptive screen — see
  // line2_production_screen.dart. Each PDT screen key still gates
  // independently server-side (api/line2.py STEP_TO_SCREEN).
  'line2_building':     (s) => Line2ProductionScreen(screen: s),
  'line2_curing':       (s) => Line2ProductionScreen(screen: s),
  'line2_processing':   (s) => Line2ProductionScreen(screen: s),
  'line2_labelling':    (s) => LabellingScreen(screen: s),
  'line2_qc_measure':   (s) => QcMeasurementScreen(screen: s),
  'line2_qc_final':     (s) => QcFinalScreen(screen: s),
  'line2_sleeve':       (s) => SleeveCreationScreen(screen: s),
  'line2_reception':    (s) => ReceptionScreen(screen: s),
  'line2_packing':      (s) => PackingScreen(screen: s),
  'line2_tools':        (s) => ToolStatusScreen(screen: s),
  'fabric_stitching':   (s) => FabricStitchingScreen(screen: s),
};
