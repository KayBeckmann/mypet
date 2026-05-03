import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<MobileAuthProvider>();
    bool ok;
    if (_isRegister) {
      ok = await auth.register(
          _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Fehler'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<MobileAuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.pets_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 24),
                Text(
                  'MyPet',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                ),
                Text(
                  _isRegister ? 'Konto erstellen' : 'Willkommen zurück',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),

                if (_isRegister) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name erforderlich' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Ungültige E-Mail' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) => v == null || v.length < 6
                      ? 'Mindestens 6 Zeichen'
                      : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isRegister ? 'Registrieren' : 'Anmelden'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() {
                    _isRegister = !_isRegister;
                    _formKey.currentState?.reset();
                  }),
                  child: Text(_isRegister
                      ? 'Bereits registriert? Anmelden'
                      : 'Noch kein Konto? Registrieren'),
                ),

                const SizedBox(height: 24),
                Text(
                  'Server: ${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080')}',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
