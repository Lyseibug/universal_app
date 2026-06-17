import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Login screen for the PDT WMS app.
///
/// Multiple workers use the same device across shifts — each must log in
/// with their own credentials. The cookie-based Frappe session ensures
/// proper per-user data isolation.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Settings gear (top-right) ──────────────────────────────────
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                tooltip: 'Server Settings',
                onPressed: () => context.push('/settings'),
              ),
            ),

            // ── Main content ───────────────────────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.horizontalPad,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo ────────────────────────────────────────────
                        _buildLogo(),
                        const SizedBox(height: 36),

                        // ── Title ───────────────────────────────────────────
                        Text(
                          'Sign In',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use your ERP credentials to access the warehouse',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // ── Error banner ─────────────────────────────────────
                        if (authState.error != null) ...[
                          _buildErrorBanner(authState.error!),
                          const SizedBox(height: 16),
                        ],

                        // ── Username ─────────────────────────────────────────
                        CustomTextField(
                          controller: _usernameCtrl,
                          labelText: 'Username / Email',
                          hintText: 'Enter your ERP username',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: Validators.username,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                        ),
                        const SizedBox(height: 14),

                        // ── Password ─────────────────────────────────────────
                        CustomTextField(
                          controller: _passwordCtrl,
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
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: Validators.password,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                        ),
                        const SizedBox(height: 28),

                        // ── Login button ─────────────────────────────────────
                        CustomButton(
                          text: 'Sign In',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                          icon: Icons.login,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'WMS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.dangerLight,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.danger, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
