import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Settings screen — ERP server URL and scan mode configuration.
/// Accessible from the login screen before authentication.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlCtrl;
  String _scanMode = 'keyboard';

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(settingsProvider).erpUrl;
    _urlCtrl = TextEditingController(text: currentUrl);
    final box = Hive.box<dynamic>('settings');
    _scanMode = box.get('scan_mode', defaultValue: 'keyboard') as String;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(settingsProvider.notifier)
        .saveErpUrl(_urlCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Settings saved'),
            ],
          ),
          backgroundColor: AppTheme.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setScanMode(String mode) async {
    setState(() => _scanMode = mode);
    await Hive.box<dynamic>('settings').put('scan_mode', mode);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: const Text('Device Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Server Section ───────────────────────────────────────────
              _buildSection(
                icon: Icons.dns_outlined,
                title: 'ERP Server',
                subtitle: 'Configure the ERPNext server URL',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _urlCtrl,
                labelText: 'Server URL',
                hintText: 'https://your-erp-server.com',
                prefixIcon: const Icon(Icons.link_outlined),
                validator: Validators.url,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              if (state.error != null)
                Text(
                  state.error!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Save',
                      isLoading: state.isSaving,
                      onPressed: _save,
                      icon: Icons.save_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _urlCtrl.text = 'https://erp.your-company.com',
                    icon: const Icon(Icons.restore_outlined, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(110, AppTheme.buttonHeight),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              // ── Scanner Section ──────────────────────────────────────────
              _buildSection(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scanner Mode',
                subtitle: 'Choose how barcodes are scanned on this device',
              ),
              const SizedBox(height: 16),

              _buildScanModeCard(
                mode: 'keyboard',
                icon: Icons.keyboard_outlined,
                label: 'Keyboard-Wedge (PDT Hardware)',
                description:
                    'For industrial scanners (Zebra, Honeywell). Scanner emulates '
                    'keyboard keystrokes — no camera needed.',
              ),
              const SizedBox(height: 10),
              _buildScanModeCard(
                mode: 'camera',
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                description:
                    'Use the device camera to scan barcodes. For phones or tablets '
                    'without a laser scanner.',
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanModeCard({
    required String mode,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final selected = _scanMode == mode;
    return GestureDetector(
      onTap: () => _setScanMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.06)
              : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.bgBorder,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.primary : AppTheme.textDisabled,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
