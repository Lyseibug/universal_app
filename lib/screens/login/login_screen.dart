import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/version_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/version_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/update_dialog.dart';

/// Professional login screen with form validation and settings access.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Check for app updates on launch
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  /// Check version and show update dialog if needed.
  Future<void> _checkForUpdate() async {
    if (!mounted) return;

    final versionStatus = await ref
        .read(versionProvider.notifier)
        .checkVersion();

    if (!mounted) return;

    if (versionStatus == VersionStatus.forceUpdate) {
      final state = ref.read(versionProvider);
      await UpdateDialog.show(
        context,
        currentVersion: state.appVersion ?? '1.0.0',
        newVersion: state.serverVersion?.latestVersion ?? '',
        apkUrl: state.serverVersion?.apkUrl ?? '',
        updateMessage: state.serverVersion?.message,
        isForceUpdate: true,
        onInstallAttempt: (version) =>
            ref.read(storageServiceProvider).savePendingUpdateVersion(version),
      );
      return;
    }

    if (versionStatus == VersionStatus.updateAvailable) {
      final state = ref.read(versionProvider);
      if (mounted) {
        await UpdateDialog.show(
          context,
          currentVersion: state.appVersion ?? '1.0.0',
          newVersion: state.serverVersion?.latestVersion ?? '',
          apkUrl: state.serverVersion?.apkUrl ?? '',
          updateMessage: state.serverVersion?.message,
          isForceUpdate: false,
          onInstallAttempt: (version) => ref
              .read(storageServiceProvider)
              .savePendingUpdateVersion(version),
        );
      }
    }

    // If already authenticated, navigate to dashboard
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error
    ref.read(authProvider.notifier).clearError();

    final success = await ref
        .read(authProvider.notifier)
        .login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Settings icon (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
              ),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet
                      ? size.width * 0.2
                      : AppConstants.horizontalPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 40),
                      // Welcome text
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue to ${AppConstants.appName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Error message
                      if (authState.error != null)
                        _buildErrorBanner(authState.error!),
                      // Username field
                      CustomTextField(
                        controller: _usernameController,
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: Validators.username,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) =>
                            ref.read(authProvider.notifier).clearError(),
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        validator: Validators.password,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) =>
                            ref.read(authProvider.notifier).clearError(),
                      ),
                      const SizedBox(height: 32),
                      // Login button
                      CustomButton(
                        text: 'Login',
                        isLoading: authState.isLoading,
                        onPressed: _handleLogin,
                        icon: Icons.login,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the company logo widget.
  Widget _buildLogo() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/universal_rubber_belt_manufacturing_logo.jpg',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Build error banner widget.
  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
