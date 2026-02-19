import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/auth/widgets/auth_text_field.dart';
import 'package:bagtrip/auth/widgets/social_login_button.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Toggle and content container corner radius.
const double _kPanelRadius = 16.0;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: const _LoginPageContent(),
    );
  }
}

class _LoginPageContent extends StatefulWidget {
  const _LoginPageContent();

  @override
  State<_LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<_LoginPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailHasError = false;
  bool _passwordHasError = false;
  bool _fullNameHasError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _toggleMode(bool currentMode) {
    _formKey.currentState?.reset();
    setState(() {
      _emailHasError = false;
      _passwordHasError = false;
      _fullNameHasError = false;
    });
    context.read<AuthBloc>().add(AuthModeChanged(isLoginMode: !currentMode));
  }

  void _handleSubmit(bool isLoginMode) {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    bool emailHasError = false;
    bool passwordHasError = false;
    bool fullNameHasError = false;
    String? firstError;

    if (email.isEmpty) {
      emailHasError = true;
      firstError ??= l10n.loginErrorEmailRequired;
    } else if (!email.contains('@') || !email.contains('.')) {
      emailHasError = true;
      firstError ??= l10n.loginErrorEmailInvalid;
    }
    if (password.isEmpty) {
      passwordHasError = true;
      firstError ??= l10n.loginErrorPasswordRequired;
    } else if (!isLoginMode && password.length < 6) {
      passwordHasError = true;
      firstError ??= l10n.loginErrorPasswordMinLength;
    }

    if (emailHasError || passwordHasError || fullNameHasError) {
      setState(() {
        _emailHasError = emailHasError;
        _passwordHasError = passwordHasError;
        _fullNameHasError = fullNameHasError;
      });
      if (firstError != null && context.mounted) {
        AppSnackBar.showError(context, message: firstError);
      }
      return;
    }

    setState(() {
      _emailHasError = false;
      _passwordHasError = false;
      _fullNameHasError = false;
    });

    if (isLoginMode) {
      context.read<AuthBloc>().add(
        LoginRequested(email: email, password: password),
      );
    } else {
      context.read<AuthBloc>().add(
        RegisterRequested(
          email: email,
          password: password,
          fullName: fullName.isNotEmpty ? fullName : null,
        ),
      );
    }
  }

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  void _handleAppleSignIn() {
    context.read<AuthBloc>().add(AppleSignInRequested());
  }

  void _onTermsTap() {
    // Placeholder: navigate to terms or launch URL
  }

  void _onPrivacyTap() {
    // Placeholder: navigate to privacy or launch URL
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const horizontalPadding = 24.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBackground =
        isDark ? ColorName.primaryTrueDark : ColorName.primaryLight;
    final titleColor = isDark ? AppColors.surface : AppColors.primaryTrueDark;
    final subtitleColor = isDark ? AppColors.hint : AppColors.textMutedLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textOnSurface =
        isDark ? AppColors.surface : AppColors.primaryTrueDark;
    final hintOnSurface = isDark ? AppColors.hint : AppColors.textMutedLight;
    final borderColor =
        isDark
            ? AppColors.surface.withValues(alpha: 0.15)
            : ColorName.primarySoftLight;
    final inputBackgroundColor =
        isDark ? AppColors.inputBackgroundDark : AppColors.primaryLight;
    final inputBorderColor = borderColor;
    const errorBorderColor = ColorName.errorDark;

    return Scaffold(
      backgroundColor: scaffoldBackground,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Future.delayed(const Duration(milliseconds: 100), () async {
                if (!context.mounted) return;
                final user = await AuthService().getCurrentUser();
                if (!context.mounted) return;
                if (user == null || user.id.isEmpty) {
                  context.go('/home');
                  return;
                }
                final hasSeen = await PersonalizationStorage()
                    .hasSeenPersonalizationPrompt(user.id);
                if (!context.mounted) return;
                if (hasSeen) {
                  context.go('/home');
                } else {
                  context.go('/personalization');
                }
              });
            }
            if (state is AuthError && context.mounted) {
              AppSnackBar.showError(
                context,
                message: toUserFriendlyMessage(state.errorMessage),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final isLoginMode =
                  state is AuthModeChangedState
                      ? state.isLoginMode
                      : state is AuthError
                      ? state.isLoginMode
                      : state is AuthInitial
                      ? state.isLoginMode
                      : true;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 100),
                      Text(
                        l10n.loginWelcomeTitle,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFamily: FontFamily.b612,
                          color: titleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        l10n.loginWelcomeSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: FontFamily.b612,
                          color: subtitleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      _LoginSignUpToggle(
                        isLogin: isLoginMode,
                        onToggle:
                            isLoading ? null : () => _toggleMode(isLoginMode),
                        l10n: l10n,
                        surfaceColor: surfaceColor,
                        textColor: textOnSurface,
                        borderColor: borderColor,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              isLoginMode ? 0 : _kPanelRadius,
                            ),
                            topRight: Radius.circular(
                              isLoginMode ? _kPanelRadius : 0,
                            ),
                            bottomLeft: const Radius.circular(_kPanelRadius),
                            bottomRight: const Radius.circular(_kPanelRadius),
                          ),
                          border: Border(
                            right: BorderSide(color: borderColor),
                            bottom: BorderSide(color: borderColor),
                            left: BorderSide(color: borderColor),
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.space24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SocialLoginButton(
                                    provider: SocialProvider.google,
                                    onPressed:
                                        isLoading ? null : _handleGoogleSignIn,
                                    isLoading: isLoading,
                                    useDarkStyle: isDark,
                                    label: l10n.loginContinueWithGoogle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.space8),
                                Expanded(
                                  child: SocialLoginButton(
                                    provider: SocialProvider.apple,
                                    onPressed:
                                        isLoading ? null : _handleAppleSignIn,
                                    isLoading: isLoading,
                                    useDarkStyle: isDark,
                                    label: l10n.loginContinueWithApple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space24),
                            _buildSeparator(
                              l10n.loginOrContinueWithEmail,
                              subtitleColor,
                            ),
                            const SizedBox(height: AppSpacing.space24),
                            AuthTextField(
                              label: '',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              hintText: l10n.loginEmailPlaceholder,
                              prefixIcon: Icon(
                                Icons.mail_outline,
                                size: 22,
                                color: hintOnSurface,
                              ),
                              backgroundColor: inputBackgroundColor,
                              textColor: textOnSurface,
                              hintColor: hintOnSurface,
                              borderColor: inputBorderColor,
                              hasError: _emailHasError,
                              errorBorderColor: errorBorderColor,
                            ),
                            const SizedBox(height: AppSpacing.space16),
                            if (!isLoginMode) ...[
                              AuthTextField(
                                label: l10n.loginFullNameLabel,
                                controller: _fullNameController,
                                keyboardType: TextInputType.name,
                                hintText: l10n.loginFullNameHint,
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 22,
                                  color: hintOnSurface,
                                ),
                                backgroundColor: inputBackgroundColor,
                                textColor: textOnSurface,
                                hintColor: hintOnSurface,
                                borderColor: inputBorderColor,
                                hasError: _fullNameHasError,
                                errorBorderColor: errorBorderColor,
                              ),
                              const SizedBox(height: AppSpacing.space16),
                            ],
                            AuthTextField(
                              label: '',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              hintText: l10n.loginPasswordPlaceholder,
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 22,
                                color: hintOnSurface,
                              ),
                              backgroundColor: inputBackgroundColor,
                              textColor: textOnSurface,
                              hintColor: hintOnSurface,
                              borderColor: inputBorderColor,
                              hasError: _passwordHasError,
                              errorBorderColor: errorBorderColor,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: hintOnSurface,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            if (isLoginMode) ...[
                              const SizedBox(height: AppSpacing.space8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading ? null : () {},
                                  child: Text(
                                    l10n.loginForgotPassword,
                                    style: const TextStyle(
                                      fontFamily: FontFamily.b612,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: ColorName.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.space24),
                            PrimaryButton(
                              label:
                                  isLoginMode
                                      ? l10n.loginButton
                                      : l10n.loginRegisterButton,
                              onPressed:
                                  isLoading
                                      ? null
                                      : () => _handleSubmit(isLoginMode),
                              isLoading: isLoading,
                            ),
                            const SizedBox(height: AppSpacing.space32),
                            _buildLegalText(l10n, subtitleColor),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(String text, Color color) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.6), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontFamily: FontFamily.b612,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.6), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildLegalText(AppLocalizations l10n, Color baseTextColor) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          fontFamily: FontFamily.b612,
          color: baseTextColor,
        ),
        children: [
          TextSpan(text: l10n.loginLegalBySigningIn),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: _onTermsTap,
              child: Text(
                l10n.loginTermsOfService,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: FontFamily.b612,
                  color: ColorName.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          TextSpan(text: l10n.loginLegalAnd),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: _onPrivacyTap,
              child: Text(
                l10n.loginPrivacyPolicy,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: FontFamily.b612,
                  color: ColorName.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

class _LoginSignUpToggle extends StatelessWidget {
  const _LoginSignUpToggle({
    required this.isLogin,
    required this.onToggle,
    required this.l10n,
    required this.surfaceColor,
    required this.textColor,
    required this.borderColor,
  });

  final bool isLogin;
  final VoidCallback? onToggle;
  final AppLocalizations l10n;
  final Color surfaceColor;
  final Color textColor;
  final Color borderColor;

  static const BorderRadius _selectedTopRadius = BorderRadius.only(
    topLeft: Radius.circular(_kPanelRadius),
    topRight: Radius.circular(_kPanelRadius),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onToggle != null ? () => onToggle!() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isLogin ? surfaceColor : Colors.transparent,
                borderRadius: isLogin ? _selectedTopRadius : null,
                border:
                    isLogin
                        ? Border(
                          top: BorderSide(color: borderColor),
                          left: BorderSide(color: borderColor),
                          right: BorderSide(color: borderColor),
                        )
                        : null,
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.login,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: GestureDetector(
            onTap: onToggle != null ? () => onToggle!() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !isLogin ? surfaceColor : Colors.transparent,
                borderRadius: !isLogin ? _selectedTopRadius : null,
                border:
                    !isLogin
                        ? Border(
                          top: BorderSide(color: borderColor),
                          left: BorderSide(color: borderColor),
                          right: BorderSide(color: borderColor),
                        )
                        : null,
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.signUp,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
