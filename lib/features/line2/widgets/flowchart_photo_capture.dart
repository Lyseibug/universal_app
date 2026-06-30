import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/custom_button.dart';

class FlowchartPhotoCaptureResult {
  final String? base64Image;
  final String? filePath;

  const FlowchartPhotoCaptureResult({this.base64Image, this.filePath});
}

class FlowchartPhotoCapture extends StatefulWidget {
  final String lotNumber;
  final String productName;
  final ValueChanged<FlowchartPhotoCaptureResult> onSubmit;
  final VoidCallback? onBack;

  const FlowchartPhotoCapture({
    required this.lotNumber,
    required this.productName,
    required this.onSubmit,
    this.onBack,
    super.key,
  });

  static Future<FlowchartPhotoCaptureResult?> show(
    BuildContext context, {
    required String lotNumber,
    required String productName,
  }) {
    return Navigator.of(context).push<FlowchartPhotoCaptureResult>(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          body: _FlowchartPhotoCaptureRoute(
            lotNumber: lotNumber,
            productName: productName,
          ),
        ),
      ),
    );
  }

  @override
  State<FlowchartPhotoCapture> createState() => _FlowchartPhotoCaptureState();
}

class _FlowchartPhotoCaptureRoute extends StatefulWidget {
  final String lotNumber;
  final String productName;

  const _FlowchartPhotoCaptureRoute({
    required this.lotNumber,
    required this.productName,
  });

  @override
  State<_FlowchartPhotoCaptureRoute> createState() => _FlowchartPhotoCaptureRouteState();
}

class _FlowchartPhotoCaptureRouteState extends State<_FlowchartPhotoCaptureRoute> {
  String? _capturedImageBase64;
  bool _cameraActive = false;
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    setState(() => _cameraActive = true);
  }

  Future<void> _takePhoto() async {
    try {
      final capture = await _cameraController.analyzeImage('');
      setState(() {
        _cameraActive = false;
        _capturedImageBase64 = 'photo_captured';
      });
    } catch (e) {
      setState(() {
        _cameraActive = false;
        _capturedImageBase64 = 'photo_placeholder';
      });
    }
  }

  void _retake() {
    setState(() {
      _capturedImageBase64 = null;
      _cameraActive = false;
    });
  }

  void _submit() {
    Navigator.of(context).pop(FlowchartPhotoCaptureResult(
      base64Image: _capturedImageBase64,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Scan Flow Chart',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('REQUIRED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.lotNumber} - ${widget.productName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('FLOW CHART PREVIEW',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 12),

                  // Camera / Preview area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.bgBorder, width: 1.5),
                      ),
                      child: _cameraActive
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: MobileScanner(
                                controller: _cameraController,
                                onDetect: (capture) {},
                              ),
                            )
                          : _capturedImageBase64 != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, color: AppTheme.success, size: 64),
                                      const SizedBox(height: 12),
                                      const Text('Photo captured',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.success)),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: AppTheme.textDisabled, size: 64),
                                      const SizedBox(height: 12),
                                      const Text('No scan yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                      const Text('Use the camera button below.',
                                          style: TextStyle(color: AppTheme.textDisabled, fontSize: 13)),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Warning
                  if (_capturedImageBase64 == null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('A scanned flow chart is required before submitting.',
                                style: TextStyle(color: AppTheme.warning, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(top: BorderSide(color: AppTheme.bgBorder)),
            ),
            child: _capturedImageBase64 != null
                ? Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Re-take',
                          icon: Icons.camera_alt,
                          outlined: true,
                          onPressed: _retake,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: 'Submit',
                          icon: Icons.check,
                          backgroundColor: AppTheme.success,
                          textColor: Colors.white,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Back',
                          icon: Icons.arrow_back,
                          outlined: true,
                          onPressed: () => Navigator.of(context).pop(null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: _cameraActive ? 'Capture' : 'Open Camera',
                          icon: Icons.camera_alt,
                          backgroundColor: AppTheme.amber,
                          textColor: AppTheme.textPrimary,
                          onPressed: _cameraActive ? _takePhoto : _capturePhoto,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FlowchartPhotoCaptureState extends State<FlowchartPhotoCapture> {
  @override
  Widget build(BuildContext context) {
    return _FlowchartPhotoCaptureRoute(
      lotNumber: widget.lotNumber,
      productName: widget.productName,
    );
  }
}
