import 'package:flutter/material.dart';

import '../../core/menu/menu_models.dart';
import '../../features/grn/grn_putaway_screen.dart';
import '../../features/lot/lot_browser_screen.dart';
import '../../features/lot/manual_transfer_screen.dart';
import '../../features/physical_inventory/physical_inventory_screen.dart';
import '../../features/pick/pick_list_screen.dart';
import '../../features/manufacturing_mr/manufacturing_mr_screen.dart';
import '../../features/support/support_screen.dart';

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
};
