import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/logic/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignupRequested(_email.text, _password.text));
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
                    'Inscription',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Créez votre compte pour commencer l\'aventure.',
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
                         const SizedBox(height: AppSpacing.space16),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: _obscurePassword,
                          decoration: const InputDecoration(
                            labelText: 'Confirmer mot de passe',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez confirmer votre mot de passe';
                            }
                            if (value != _password.text) {
                              return 'Les mots de passe ne correspondent pas';
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
                        label: 'S\'inscrire',
                        isLoading: state is AuthLoading,
                        onPressed: _onSubmit,
                      );
                    },
                  ),
    
                  const SizedBox(height: AppSpacing.space16),
    
                  // Register
                  Center(
                    child: TextButton(
                      onPressed: () {
                         context.pop();
                      },
                      child: const Text(
                        'J\'ai déjà un compte',
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
