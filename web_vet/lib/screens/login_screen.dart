import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<VetAuthProvider>();
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (ok && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<VetAuthProvider>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(VetTheme.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MyPet Vet',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VetTheme.spacingSm),
                  Text(
                    'Portal für Tierärzt:innen und Praxen',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VetTheme.spacingXl),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-Mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Ungültige E-Mail' : null,
                  ),
                  const SizedBox(height: VetTheme.spacingMd),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Passwort'),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mindestens 6 Zeichen' : null,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: VetTheme.spacingMd),
                    Text(
                      auth.error!,
                      style: const TextStyle(color: VetTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: VetTheme.spacingLg),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Anmelden'),
                  ),
                  const SizedBox(height: VetTheme.spacingMd),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Noch kein Konto? Registrieren'),
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
