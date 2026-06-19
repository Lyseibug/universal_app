import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Abstract scan service — screens subscribe to [scans] regardless of
/// whether the device has a laser scanner or camera.
abstract class ScanService {
  /// Stream of decoded barcode strings. Emits one value per completed scan.
  Stream<String> get scans;

  void dispose();
}

// ─── Keyboard-Wedge Implementation ───────────────────────────────────────────

/// Primary scan service for PDT hardware (Zebra, Honeywell, etc.).
///
/// Industrial scanners configured as keyboard-wedge emit the barcode as
/// rapid keystrokes followed by a terminator (default: Enter / `\n`).
///
/// Usage: place a [KeyboardWedgeScanWidget] somewhere in the widget tree
/// whenever scanning is needed; it handles focus and key capture.
class KeyboardWedgeScanService extends ScanService {
  final _controller = StreamController<String>.broadcast();
  final StringBuffer _buffer = StringBuffer();

  /// Character that signals end-of-barcode (configurable per device profile).
  final String terminator;

  KeyboardWedgeScanService({this.terminator = '\n'});

  @override
  Stream<String> get scans => _controller.stream;

  /// Call from a [KeyboardListener.onKeyEvent]
  void onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final char = event.character;
    if (char == null) return;

    if (char == terminator || char == '\r') {
      final value = _buffer.toString().trim();
      _buffer.clear();
      if (value.isNotEmpty) {
        _controller.add(value);
      }
    } else {
      _buffer.write(char);
    }
  }

  /// Manually inject a scan value (used in tests or manual entry fallback).
  void injectScan(String value) {
    if (value.isNotEmpty) _controller.add(value);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

// ─── Camera Implementation ────────────────────────────────────────────────────

/// Fallback scan service for devices without a laser scanner.
/// Uses `mobile_scanner` to read barcodes via the device camera.
class CameraScanService extends ScanService {
  final _controller = StreamController<String>.broadcast();
  MobileScannerController? _scannerController;

  @override
  Stream<String> get scans => _controller.stream;

  /// Create and return the [MobileScanner] widget.
  /// Place this inside a bottom sheet or overlay in the WMS screen.
  Widget buildScannerWidget() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    return MobileScanner(
      controller: _scannerController!,
      onDetect: (capture) {
        final barcode = capture.barcodes.firstOrNull;
        final value = barcode?.rawValue;
        if (value != null && value.isNotEmpty) {
          _controller.add(value);
        }
      },
    );
  }

  void stopCamera() {
    _scannerController?.stop();
  }

  void startCamera() {
    _scannerController?.start();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _controller.close();
  }
}

// ─── Keyboard Wedge Widget ────────────────────────────────────────────────────

/// Widget that captures keyboard-wedge scanner input.
///
/// Wrap the body of any WMS screen with this widget. It maintains focus
/// on a hidden text field so that every keystroke from the scanner is
/// captured without requiring the user to tap a field.
///
/// ```dart
/// body: KeyboardWedgeScanWidget(
///   service: ref.read(keyboardScanServiceProvider),
///   child: YourScreenContent(),
/// )
/// ```
class KeyboardWedgeScanWidget extends StatefulWidget {
  final KeyboardWedgeScanService service;
  final Widget child;

  const KeyboardWedgeScanWidget({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  State<KeyboardWedgeScanWidget> createState() =>
      _KeyboardWedgeScanWidgetState();
}

class _KeyboardWedgeScanWidgetState extends State<KeyboardWedgeScanWidget> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus on next frame so the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: widget.service.onKeyEvent,
      child: widget.child,
    );
  }
}
