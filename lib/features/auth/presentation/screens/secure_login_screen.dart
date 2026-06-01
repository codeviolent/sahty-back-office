import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

abstract final class _LoginMock {
  static const hasRecoveryPermission = false;
}

// ─────────────────────────────────────────────────────────────────────────────

class SecureLoginScreen extends StatefulWidget {
  const SecureLoginScreen({super.key, required this.onLoginVerified});

  final VoidCallback onLoginVerified;

  @override
  State<SecureLoginScreen> createState() => _SecureLoginScreenState();
}

class _SecureLoginScreenState extends State<SecureLoginScreen> {
  bool _obscurePassword = true;
  bool _requestDeviceTrust = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'dr.nichols@sahty.local');
  final _passwordCtrl = TextEditingController(text: 'Demo1234');
  final _otpCtrl = TextEditingController(text: '123456');
  bool _formValid = true; // Pre-valid because of mock credentials

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _formValid) setState(() => _formValid = valid);
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        // Login réussi → laisser l'app passer à DeviceTrust
        if (state is AuthPendingDeviceTrust) {
          widget.onLoginVerified();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 820;

          return ColoredBox(
            color: AppColors.canvas,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: constraints.maxWidth - (AppSpacing.lg * 2),
                  height: constraints.maxHeight - (AppSpacing.lg * 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 32,
                          offset: Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: isCompact
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _LoginVisualPanel(compact: true),
                                _buildLoginForm(),
                              ],
                            )
                          : SizedBox(
                              height: double.infinity,
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 10,
                                    child: _LoginVisualPanel(),
                                  ),
                                  Expanded(flex: 11, child: _buildLoginForm()),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    return _LoginCard(
      formKey: _formKey,
      usernameCtrl: _usernameCtrl,
      passwordCtrl: _passwordCtrl,
      otpCtrl: _otpCtrl,
      obscurePassword: _obscurePassword,
      requestDeviceTrust: _requestDeviceTrust,
      formValid: _formValid,
      onTogglePassword: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onToggleDeviceTrust: (v) => setState(() => _requestDeviceTrust = v),
      onFieldChanged: _onFieldChanged,
      onLogin: _submitLogin,
      showRecoveryLink: _LoginMock.hasRecoveryPermission,
    );
  }
}

class _LoginVisualPanel extends StatelessWidget {
  const _LoginVisualPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final px = MediaQuery.devicePixelRatioOf(context);
          // Decode image only at the actual display size to avoid loading a
          // full-resolution JPEG into GPU memory.
          final cacheW = constraints.maxWidth.isFinite
              ? (constraints.maxWidth * px).round()
              : 900;
          return SizedBox(
            height: compact ? 360 : double.infinity,
            width: double.infinity,
            child: Image.asset(
              'assets/images/reaction.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: cacheW,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  const _MissingLoginImageFallback(),
            ),
          );
        },
      ),
    );
  }
}

class _MissingLoginImageFallback extends StatelessWidget {
  const _MissingLoginImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7E4DE), Color(0xFFCFCBC3)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: 22,
          color: AppColors.ink.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

// ── Login Card ────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.otpCtrl,
    required this.obscurePassword,
    required this.requestDeviceTrust,
    required this.formValid,
    required this.onTogglePassword,
    required this.onToggleDeviceTrust,
    required this.onFieldChanged,
    required this.onLogin,
    required this.showRecoveryLink,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController otpCtrl;
  final bool obscurePassword;
  final bool requestDeviceTrust;
  final bool formValid;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onToggleDeviceTrust;
  final VoidCallback onFieldChanged;
  final VoidCallback onLogin;
  final bool showRecoveryLink;

  void _submit(BuildContext context) {
    final email = usernameCtrl.text.trim();
    final password = passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = AppColors.primaryDark;
    final otpHint = switch (context.appLocale) {
      AppLocale.ar => 'رمز مكوّن من 6 أرقام',
      AppLocale.fr => 'Code à 6 chiffres',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 82, vertical: 46),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Form(
            key: formKey,
            onChanged: onFieldChanged,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => const Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.primaryDark,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr(AppTextKey.appTitle).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: brandColor,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 0.98,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _LoginFieldLabel(label: context.tr(AppTextKey.doctorId)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: _loginInputDecoration(
                    context,
                    hintText: 'dr.nichols@sahty.local',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: AppSpacing.md),
                _LoginFieldLabel(label: context.tr(AppTextKey.password)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: _loginInputDecoration(
                    context,
                    hintText: '••••••••••',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? '' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: AppSpacing.md),
                _LoginFieldLabel(label: context.tr(AppTextKey.otp)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: _loginInputDecoration(
                    context,
                    hintText: otpHint,
                    icon: Icons.pin_outlined,
                  ).copyWith(counterText: ''),
                  validator: (v) => (v == null || v.length != 6) ? '' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: showRecoveryLink ? () {} : null,
                    style: TextButton.styleFrom(
                      foregroundColor: brandColor,
                      disabledForegroundColor: brandColor,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.labelSmall,
                    ),
                    child: Text(context.tr(AppTextKey.recoveryLink)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onToggleDeviceTrust(!requestDeviceTrust),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 17,
                          height: 17,
                          child: Checkbox.adaptive(
                            value: requestDeviceTrust,
                            onChanged: (v) => onToggleDeviceTrust(v ?? false),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.tr(AppTextKey.rememberDevice),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (ctx, state) {
                    final isLoading = state is AuthLoading;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Message d'erreur ────────────────────────────
                        if (state is AuthError)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFFDC2626,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFDC2626),
                                    size: 15,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      state.message,
                                      style: Theme.of(ctx).textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFFDC2626),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── Bouton connexion ─────────────────────────────
                        SizedBox(
                          height: 46,
                          child: FilledButton(
                            // Désactivé si loading ou formulaire invalide
                            onPressed: (formValid && !isLoading)
                                ? onLogin
                                : null,
                            style:
                                FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: AppColors.glassSurfaceStrong,
                                  disabledBackgroundColor: AppColors.border
                                      .withValues(alpha: 0.40),
                                  disabledForegroundColor: AppColors.mutedInk
                                      .withValues(alpha: 0.50),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStatePropertyAll(
                                    AppColors.glassSurfaceStrong.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(context.tr(AppTextKey.loginAction)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Biometric button hidden until local_auth is integrated
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _loginInputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, size: 17),
      suffixIcon: suffixIcon,
      prefixIconColor: AppColors.ink,
      suffixIconColor: AppColors.ink,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.26)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.26)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.2),
      ),
      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.placeholder,
        fontSize: 11,
      ),
    );
  }
}

class _LoginFieldLabel extends StatelessWidget {
  const _LoginFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.primaryDark,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}
