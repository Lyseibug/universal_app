import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _scanSubscription = ref.read(keyboardScanServiceProvider).scans.listen((barcode) {
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

  @override
  Widget build(BuildContext context) {
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
      suffixIcon: Tooltip(
        message: 'Scanner Ready',
        child: Icon(Icons.sensors, color: widget.focusNode.hasFocus ? AppTheme.success : AppTheme.textDisabled),
      ),
    );
  }
}
