import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/auth/widgets/auth_text_field.dart';
import 'package:bagtrip/auth/widgets/social_login_button.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _toggleMode(bool currentMode) {
    _formKey.currentState?.reset();
    context.read<AuthBloc>().add(AuthModeChanged(isLoginMode: !currentMode));
  }

  void _handleSubmit(bool isLoginMode) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isLoginMode) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        RegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName:
              _fullNameController.text.trim().isNotEmpty
                  ? _fullNameController.text.trim()
                  : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              // Petit délai pour s'assurer que l'état est bien émis
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  context.go('/home');
                }
              });
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final errorMessage =
                  state is AuthError ? state.errorMessage : null;
              final isLoginMode =
                  state is AuthModeChangedState
                      ? state.isLoginMode
                      : state is AuthError
                      ? state.isLoginMode
                      : state is AuthInitial
                      ? state.isLoginMode
                      : true;

              return SingleChildScrollView(
                padding: AppSpacing.allEdgeInsetSpace16,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                      ),
                      // Logo/Title
                      Text(
                        'BagTrip',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        isLoginMode ? 'Connectez-vous' : 'Créez votre compte',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.08,
                      ),
                      // Email field
                      AuthTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'votre@email.com',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      // Full name field (only for register)
                      if (!isLoginMode) ...[
                        AuthTextField(
                          label: 'Nom complet (optionnel)',
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          hintText: 'Jean Dupont',
                        ),
                        const SizedBox(height: AppSpacing.space16),
                      ],
                      // Password field
                      AuthTextField(
                        label: 'Mot de passe',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: ColorName.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (!isLoginMode && value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),
                      // Error message
                      if (errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.space16),
                        Container(
                          padding: AppSpacing.allEdgeInsetSpace16,
                          decoration: BoxDecoration(
                            color: ColorName.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.medium8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: ColorName.error,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.space8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: ColorName.error,
                                    fontFamily: FontFamily.b612,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space24),
                      // Submit button
                      PrimaryButton(
                        label: isLoginMode ? 'Se connecter' : 'S\'inscrire',
                        onPressed:
                            isLoading ? null : () => _handleSubmit(isLoginMode),
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      // Toggle mode button
                      TextButton(
                        onPressed:
                            isLoading ? null : () => _toggleMode(isLoginMode),
                        child: Text(
                          isLoginMode
                              ? 'Pas de compte ? S\'inscrire'
                              : 'Déjà un compte ? Se connecter',
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space32),
                      // Divider
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: ColorName.primarySoftLight,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space16,
                            ),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: ColorName.primaryTrueDark.withValues(
                                  alpha: 0.6,
                                ),
                                fontFamily: FontFamily.b612,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: ColorName.primarySoftLight,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      // Social login buttons
                      SocialLoginButton(
                        provider: SocialProvider.google,
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      SocialLoginButton(
                        provider: SocialProvider.apple,
                        onPressed: isLoading ? null : _handleAppleSignIn,
                        isLoading: isLoading,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
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
}
