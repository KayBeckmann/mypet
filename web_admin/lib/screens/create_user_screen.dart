import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/users_provider.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'vet';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<UsersProvider>().createUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Benutzer erfolgreich angelegt')),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.onPrimary,
        title: const Text('Neuen Benutzer anlegen'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AdminTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Benutzerdaten',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AdminTheme.spacingLg),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Name ist erforderlich' : null,
                          ),
                          const SizedBox(height: AdminTheme.spacingMd),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-Mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Ungültige E-Mail' : null,
                          ),
                          const SizedBox(height: AdminTheme.spacingMd),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Passwort',
                              prefixIcon: const Icon(Icons.lock_outline),
                              helperText: 'Mindestens 8 Zeichen',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: (v) => (v == null || v.length < 8)
                                ? 'Mindestens 8 Zeichen'
                                : null,
                          ),
                          const SizedBox(height: AdminTheme.spacingLg),
                          Text(
                            'Rolle',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AdminTheme.spacingSm),
                          _RoleSelector(
                            value: _selectedRole,
                            onChanged: (r) => setState(() => _selectedRole = r),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (users.error != null) ...[
                    const SizedBox(height: AdminTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AdminTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AdminTheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      ),
                      child: Text(
                        users.error!,
                        style: const TextStyle(color: AdminTheme.secondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: AdminTheme.spacingLg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Abbrechen'),
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingMd),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: users.isLoading ? null : _submit,
                          child: users.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Benutzer anlegen'),
                        ),
                      ),
                    ],
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

class _RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const roles = [
      ('vet', 'Tierarzt', Icons.medical_services_outlined,
          'Zugang zum Tierarzt-Portal'),
      ('provider', 'Dienstleister', Icons.handyman_outlined,
          'Hufpfleger, Trainer, etc.'),
      ('owner', 'Tierbesitzer', Icons.pets_outlined,
          'Normaler Benutzer mit Tier-Verwaltung'),
    ];

    return Column(
      children: roles.map((r) {
        final (role, label, icon, description) = r;
        final selected = value == role;
        return Padding(
          padding: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
          child: InkWell(
            onTap: () => onChanged(role),
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AdminTheme.spacingMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                border: Border.all(
                  color: selected ? AdminTheme.primary : AdminTheme.outlineVariant,
                  width: selected ? 2 : 1,
                ),
                color: selected
                    ? AdminTheme.primaryContainer.withOpacity(0.1)
                    : AdminTheme.surfaceContainerLowest,
              ),
              child: Row(
                children: [
                  Icon(icon,
                      color: selected ? AdminTheme.primary : AdminTheme.outline),
                  const SizedBox(width: AdminTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AdminTheme.primary
                                  : AdminTheme.onSurface,
                            )),
                        Text(description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AdminTheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AdminTheme.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
