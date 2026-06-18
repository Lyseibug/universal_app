import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_theme.dart';
import '../providers/service_providers.dart';
import 'custom_text_field.dart';

class ScanInputField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onScanned;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const ScanInputField({
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.hintText,
    this.prefixIcon = Icons.qr_code_scanner,
    this.onChanged,
    this.onScanned,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  @override
  ConsumerState<ScanInputField> createState() => _ScanInputFieldState();
}

class _ScanInputFieldState extends ConsumerState<ScanInputField> {
  StreamSubscription<String>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    // Defer check to post-frame to ensure focus state has stabilized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.focusNode.hasFocus) {
        _subscribe();
      }
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _unsubscribe();
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus) {
      _subscribe();
    } else {
      _unsubscribe();
    }
  }

  void _subscribe() {
    if (_scanSubscription != null) return;
    _scanSubscription = ref.read(keyboardScanServiceProvider).scans.listen((
      barcode,
    ) {
      if (!mounted) return;
      widget.controller.text = barcode;
      if (widget.onScanned != null) {
        widget.onScanned!(barcode);
      } else if (widget.onChanged != null) {
        widget.onChanged!(barcode);
      }
    });
  }

  void _unsubscribe() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  /// Read the scan mode from Hive settings box.
  String _getScanMode() {
    try {
      final box = Hive.box<dynamic>('settings');
      return box.get('scan_mode', defaultValue: 'keyboard') as String;
    } catch (_) {
      return 'keyboard';
    }
  }

  /// Opens a bottom sheet with the camera barcode scanner.
  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CameraScannerSheet(
        onScanned: (barcode) {
          Navigator.of(ctx).pop();
          widget.controller.text = barcode;
          if (widget.onScanned != null) {
            widget.onScanned!(barcode);
          } else if (widget.onChanged != null) {
            widget.onChanged!(barcode);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanMode = _getScanMode();
    final isCameraMode = scanMode == 'camera';

    return CustomTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: Icon(widget.prefixIcon, color: AppTheme.amber),
      textStyle: AppTheme.scanValueStyle,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera scan button — always visible so users can use camera scan
          // regardless of mode. Primary action when scan_mode == 'camera'.
          IconButton(
            icon: Icon(
              Icons.camera_alt_outlined,
              color: isCameraMode ? AppTheme.primary : AppTheme.textSecondary,
            ),
            tooltip: 'Scan with Camera',
            onPressed: _openCameraScanner,
          ),
          // Keyboard-wedge status indicator — shows when keyboard mode is active
          if (!isCameraMode)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.sensors,
                size: 20,
                color: widget.focusNode.hasFocus
                    ? AppTheme.success
                    : AppTheme.textDisabled,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet widget that displays the camera barcode scanner.
class _CameraScannerSheet extends StatefulWidget {
  final ValueChanged<String> onScanned;

  const _CameraScannerSheet({required this.onScanned});

  @override
  State<_CameraScannerSheet> createState() => _CameraScannerSheetState();
}

class _CameraScannerSheetState extends State<_CameraScannerSheet> {
  MobileScannerController? _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null && value.isNotEmpty) {
      _hasScanned = true;
      widget.onScanned(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Scan Barcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Camera View
          Expanded(
            child: MobileScanner(controller: _controller!, onDetect: _onDetect),
          ),
          // Hint text at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: const Text(
              'Point camera at barcode to scan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
