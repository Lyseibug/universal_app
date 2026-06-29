import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/scan_input_field.dart';
import 'product_details_card.dart';
import 'session_timer_widget.dart';
import 'support_help_section.dart';

class ProductionStationLayout extends StatelessWidget {
  final String title;

  // Workstation
  final List<String> availableWorkstations;
  final String? selectedWorkstation;
  final ValueChanged<String?>? onWorkstationChanged;
  final List<String>? assignedStations;

  // Scan
  final TextEditingController scanController;
  final FocusNode scanFocusNode;
  final String scanLabel;
  final String scanHint;
  final ValueChanged<String> onScanned;
  final bool scanning;

  // Product details (shown after scan)
  final Map<String, dynamic>? scanResult;

  // Step-specific content
  final Widget? stepContent;

  // Timer
  final DateTime? timerStartTime;
  final int? targetMinutes;

  // Actions
  final VoidCallback? onFinish;
  final VoidCallback? onBack;
  final bool finishing;
  final String finishLabel;

  // Error
  final String? error;
  final VoidCallback? onDismissError;

  const ProductionStationLayout({
    required this.title,
    this.availableWorkstations = const [],
    this.selectedWorkstation,
    this.onWorkstationChanged,
    this.assignedStations,
    required this.scanController,
    required this.scanFocusNode,
    this.scanLabel = 'Scan Flowchart',
    this.scanHint = 'Scan flowchart barcode',
    required this.onScanned,
    this.scanning = false,
    this.scanResult,
    this.stepContent,
    this.timerStartTime,
    this.targetMinutes,
    this.onFinish,
    this.onBack,
    this.finishing = false,
    this.finishLabel = 'Finish',
    this.error,
    this.onDismissError,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Workstation dropdown
              if (availableWorkstations.isNotEmpty) ...[
                const Text(
                  'WORKSTATION ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedWorkstation,
                  decoration: const InputDecoration(hintText: 'Select workstation'),
                  items: availableWorkstations.map((ws) {
                    return DropdownMenuItem(value: ws, child: Text(ws));
                  }).toList(),
                  onChanged: onWorkstationChanged,
                ),
                if (assignedStations != null && assignedStations!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned: ${assignedStations!.join(" · ")}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Scan field
              ScanInputField(
                controller: scanController,
                focusNode: scanFocusNode,
                labelText: scanLabel,
                hintText: scanHint,
                onScanned: onScanned,
                onSubmitted: onScanned,
                autofocus: availableWorkstations.isEmpty,
              ),
              const SizedBox(height: 12),

              if (scanning) const Center(child: CircularProgressIndicator()),

              // Error
              if (error != null)
                Card(
                  color: AppTheme.dangerLight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(error!, style: const TextStyle(color: AppTheme.danger))),
                        if (onDismissError != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: onDismissError,
                          ),
                      ],
                    ),
                  ),
                ),

              // Product details card
              if (scanResult != null) ...[
                ProductDetailsCard.fromScanResult(scanResult!),
                const SizedBox(height: 12),

                // Step-specific content
                if (stepContent != null) ...[
                  stepContent!,
                  const SizedBox(height: 12),
                ],

                // Session timer
                SessionTimerWidget(
                  startTime: timerStartTime,
                  targetMinutes: targetMinutes,
                ),
                const SizedBox(height: 16),

                // Support
                const SupportHelpSection(),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        // Bottom buttons
        if (scanResult != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(top: BorderSide(color: AppTheme.bgBorder)),
            ),
            child: Row(
              children: [
                if (onBack != null)
                  Expanded(
                    child: CustomButton(
                      text: 'Back',
                      icon: Icons.arrow_back,
                      outlined: true,
                      onPressed: onBack,
                    ),
                  ),
                if (onBack != null) const SizedBox(width: 12),
                Expanded(
                  flex: onBack != null ? 2 : 1,
                  child: CustomButton(
                    text: finishing ? 'Completing...' : finishLabel,
                    icon: Icons.check_circle,
                    isLoading: finishing,
                    backgroundColor: AppTheme.success,
                    textColor: Colors.white,
                    onPressed: finishing ? null : onFinish,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
