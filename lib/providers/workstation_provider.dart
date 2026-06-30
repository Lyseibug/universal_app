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
