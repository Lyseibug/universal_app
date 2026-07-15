import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkstationState {
  final String? selectedWorkstation;
  final String? productionLine;
  final List<String> assignedStations;
  final String? helperName;

  const WorkstationState({
    this.selectedWorkstation,
    this.productionLine,
    this.assignedStations = const [],
    this.helperName,
  });

  WorkstationState copyWith({
    String? selectedWorkstation,
    String? productionLine,
    List<String>? assignedStations,
    String? helperName,
  }) {
    return WorkstationState(
      selectedWorkstation: selectedWorkstation ?? this.selectedWorkstation,
      productionLine: productionLine ?? this.productionLine,
      assignedStations: assignedStations ?? this.assignedStations,
      helperName: helperName ?? this.helperName,
    );
  }
}

final workstationProvider = StateProvider<WorkstationState>((ref) {
  return const WorkstationState();
});

/// Screen key to auto-open once HomeScreen finishes its first build after
/// workspace selection (see WorkspaceScreen._confirm). Set right before
/// `context.go('/home')` and consumed-and-cleared by HomeScreen's first
/// post-frame callback — pushing only after Home is actually the current
/// page avoids the imperative-push-on-top-of-a-page-being-replaced race.
/// Null means no pending auto-open.
final pendingAutoOpenScreenKeyProvider = StateProvider<String?>((ref) => null);
