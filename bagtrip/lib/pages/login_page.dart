import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bagtrip/service/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLoginMode = true; // true = login, false = register
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Pour register, on pourrait ajouter un champ fullName
        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text,
          'User', // TODO: Ajouter champ fullName dans le formulaire
        );
      }

      // Navigation vers Home après login réussi
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Connexion' : 'Inscription')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLoginMode ? 'Connexion' : 'Inscription',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isLoginMode ? 'Se connecter' : 'S\'inscrire'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                              _errorMessage = null;
                            });
                          },
                  child: Text(
                    _isLoginMode
                        ? 'Pas de compte ? S\'inscrire'
                        : 'Déjà un compte ? Se connecter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
