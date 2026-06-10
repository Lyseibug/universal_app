import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Settings screen for configuring ERP server URL.
/// Accessible from the login screen via settings icon.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(settingsProvider).erpUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(settingsProvider.notifier)
        .saveErpUrl(_urlController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('ERP URL saved successfully'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      );
    }
  }

  void _resetToDefault() {
    _urlController.text = AppConstants.defaultErpUrl;
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet
              ? size.width * 0.2
              : AppConstants.horizontalPadding,
          vertical: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header
              _buildSectionHeader(
                context,
                title: 'ERP Server Configuration',
                subtitle: 'Configure the server URL for your ERP system',
                icon: Icons.dns_outlined,
              ),
              const SizedBox(height: 24),
              // URL Input
              CustomTextField(
                controller: _urlController,
                labelText: 'ERP Server URL',
                hintText: 'http://your-erp-server.com',
                prefixIcon: const Icon(Icons.link),
                validator: Validators.url,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              // Default URL hint
              Text(
                'Default: ${AppConstants.defaultErpUrl}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              // Error display
              if (settingsState.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  settingsState.error!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Save button
              CustomButton(
                text: 'Save Settings',
                isLoading: settingsState.isSaving,
                onPressed: _saveSettings,
                icon: Icons.save,
              ),
              const SizedBox(height: 16),
              // Reset to default button
              CustomButton(
                text: 'Reset to Default',
                onPressed: _resetToDefault,
                outlined: true,
                icon: Icons.restore,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section header widget.
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
