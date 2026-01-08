import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/logic/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.allEdgeInsetSpace24,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Connectez-vous pour retrouver vos voyages et votre budget.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.space24),
    
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'vous@exemple.com',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir votre email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.space16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
    
                  const SizedBox(height: AppSpacing.space24),
    
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        label: 'Se connecter',
                        isLoading: state is AuthLoading,
                        onPressed: _onSubmit,
                      );
                    },
                  ),
    
                  const SizedBox(height: AppSpacing.space24),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ou', 
                          style: TextStyle(color: Colors.grey.shade500)
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space24),

                  // Social Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        icon: FontAwesomeIcons.google,
                        label: 'Google',
                        onPressed: () {
                           context.read<AuthBloc>().add(AuthGoogleLoginRequested());
                        },
                      ),
                      const SizedBox(width: AppSpacing.space16),
                      _SocialButton(
                        icon: FontAwesomeIcons.apple,
                        label: 'Apple',
                        onPressed: () {
                            context.read<AuthBloc>().add(AuthAppleLoginRequested());
                        },
                      ),
                    ],
                  ),
    
                  const SizedBox(height: AppSpacing.space24),
    
                  // Register
                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.pushNamed('register');
                      },
                      child: const Text(
                        'Créer un compte',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
