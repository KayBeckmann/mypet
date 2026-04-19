import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/role_badge.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<UsersProvider>().loadUsers(
          role: _selectedRole,
          search: _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AdminAuthProvider>();
    final users = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.onPrimary,
        title: const Text('Benutzerverwaltung'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdminTheme.spacingMd),
            child: Center(
              child: Text(
                auth.user?.name ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/users/create'),
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.onPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Benutzer anlegen'),
      ),
      body: Column(
        children: [
          // Filter-Leiste
          Container(
            color: AdminTheme.surfaceContainerLowest,
            padding: const EdgeInsets.all(AdminTheme.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Name oder E-Mail suchen...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingMd),
                DropdownButton<String>(
                  value: _selectedRole.isEmpty ? null : _selectedRole,
                  hint: const Text('Alle Rollen'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Alle Rollen')),
                    DropdownMenuItem(value: 'owner', child: Text('Tierbesitzer')),
                    DropdownMenuItem(value: 'vet', child: Text('Tierarzt')),
                    DropdownMenuItem(value: 'provider', child: Text('Dienstleister')),
                    DropdownMenuItem(value: 'superadmin', child: Text('Superadmin')),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedRole = v ?? '');
                    _applyFilters();
                  },
                ),
                const SizedBox(width: AdminTheme.spacingSm),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Neu laden',
                  onPressed: _applyFilters,
                ),
              ],
            ),
          ),

          // Fehlermeldung
          if (users.error != null)
            Container(
              width: double.infinity,
              color: AdminTheme.secondaryContainer,
              padding: const EdgeInsets.all(AdminTheme.spacingMd),
              child: Text(
                users.error!,
                style: const TextStyle(color: AdminTheme.secondary),
                textAlign: TextAlign.center,
              ),
            ),

          // Liste
          Expanded(
            child: users.isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 64, color: AdminTheme.outline),
                            const SizedBox(height: AdminTheme.spacingMd),
                            Text(
                              'Keine Benutzer gefunden',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AdminTheme.spacingMd),
                        itemCount: users.users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AdminTheme.spacingSm),
                        itemBuilder: (context, i) =>
                            _UserTile(user: users.users[i]),
                      ),
          ),

          // Paginierung
          if (users.pagination != null)
            _PaginationBar(
              pagination: users.pagination!,
              onPage: (p) => context.read<UsersProvider>().loadUsers(
                    page: p,
                    role: _selectedRole,
                    search: _searchController.text.trim(),
                  ),
            ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? false;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AdminTheme.spacingMd,
          vertical: AdminTheme.spacingSm,
        ),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AdminTheme.primaryContainer
              : AdminTheme.surfaceContainerHigh,
          child: Text(
            (user['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: isActive ? AdminTheme.onPrimary : AdminTheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(user['name'] as String? ?? ''),
            const SizedBox(width: AdminTheme.spacingSm),
            RoleBadge(role: user['role'] as String? ?? ''),
            if (!isActive) ...[
              const SizedBox(width: AdminTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
                ),
                child: const Text(
                  'Deaktiviert',
                  style: TextStyle(fontSize: 11, color: AdminTheme.outline),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(user['email'] as String? ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/users/${user['id']}'),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final Map<String, dynamic> pagination;
  final ValueChanged<int> onPage;

  const _PaginationBar({required this.pagination, required this.onPage});

  @override
  Widget build(BuildContext context) {
    final page = pagination['page'] as int? ?? 1;
    final pages = pagination['pages'] as int? ?? 1;
    final total = pagination['total'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingMd,
        vertical: AdminTheme.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AdminTheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AdminTheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total Benutzer gesamt',
            style: const TextStyle(color: AdminTheme.onSurfaceVariant, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: page > 1 ? () => onPage(page - 1) : null,
              ),
              Text('$page / $pages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: page < pages ? () => onPage(page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
