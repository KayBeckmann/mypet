import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<VetAuthProvider>();
    final ok = await auth.register(
      _nameController.text.trim(),
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
                    'Tierarzt-Konto anlegen',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VetTheme.spacingXl),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bitte angeben' : null,
                  ),
                  const SizedBox(height: VetTheme.spacingMd),
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
                        : const Text('Registrieren'),
                  ),
                  const SizedBox(height: VetTheme.spacingMd),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Zurück zur Anmeldung'),
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
