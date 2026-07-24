import 'package:flutter/material.dart';

import '../../core/menu/menu_models.dart';
import '../../widgets/pdt_scaffold.dart';
import 'maintenance_request_form.dart';

/// Raise a Maintenance Request against a machine. Any PDT User can open
/// this screen (screen_key: maintenance_request) -- the shared queue is a
/// separate, role-restricted screen (maintenance_team_screen.dart), so
/// this one is deliberately create-only with no list-back-view.
///
/// The actual form lives in maintenance_request_form.dart, shared with the
/// global Quick Support drawer (widgets/pdt_scaffold.dart) so both stay
/// wired to the same machine-autofill + issue-picker logic.
class RaiseMaintenanceRequestScreen extends StatelessWidget {
  final MenuScreen screen;
  const RaiseMaintenanceRequestScreen({required this.screen, super.key});

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: screen.label,
      body: const MaintenanceRequestForm(),
    );
  }
}
