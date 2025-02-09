import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../widgets/responsive_layout.dart';
import '../config/app_localizations.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.translate('users') ?? 'Users'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: Provider.of<AppProvider>(context).usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    l10n?.translate('error') ?? 'Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('users') ?? 'Users',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                ResponsiveLayout(
                  mobile: _buildUsersList(context, users, compact: true),
                  tablet: _buildUsersList(context, users),
                  desktop: _buildUsersList(context, users),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, List<AppUser> users,
      {bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n?.translate('avatar') ?? 'Avatar')),
            DataColumn(label: Text(l10n?.translate('name') ?? 'Name')),
            DataColumn(label: Text(l10n?.translate('email') ?? 'Email')),
            if (!compact)
              DataColumn(label: Text(l10n?.translate('role') ?? 'Role')),
            if (!compact)
              DataColumn(label: Text(l10n?.translate('joined') ?? 'Joined')),
            DataColumn(label: Text(l10n?.translate('status') ?? 'Status')),
            DataColumn(label: Text(l10n?.translate('actions') ?? 'Actions')),
          ],
          rows: users.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  CircleAvatar(
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(user.name?[0].toUpperCase() ?? '')
                        : null,
                  ),
                ),
                DataCell(Text(
                    user.name ?? l10n?.translate('notAvailable') ?? 'N/A')),
                DataCell(Text(user.email)),
                if (!compact) DataCell(Text(user.role)),
                if (!compact)
                  DataCell(Text(user.createdAt.toString().split(' ')[0])),
                DataCell(
                  Switch(
                    value: user.isActive,
                    onChanged: (value) {
                      // Update user status
                    },
                  ),
                ),
                DataCell(
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n?.translate('edit') ?? 'Edit User'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n?.translate('delete') ?? 'Delete User'),
                      ),
                    ],
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _showEditUserDialog(context, user);
                          break;
                        case 'delete':
                          _showDeleteUserDialog(context, user);
                          break;
                      }
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, AppUser user) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    String selectedRole = user.role;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('editUser') ?? 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: l10n?.translate('name') ?? 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                  labelText: l10n?.translate('email') ?? 'Email'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration:
                  InputDecoration(labelText: l10n?.translate('role') ?? 'Role'),
              items: ['admin', 'user', 'manager']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(l10n?.translate(role) ?? role),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedRole = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update user
              Navigator.pop(context);
            },
            child: Text(l10n?.translate('save') ?? 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteUserDialog(BuildContext context, AppUser user) async {
    final l10n = AppLocalizations.of(context);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('deleteUser') ?? 'Delete User'),
        content: Text(l10n?.translate('confirmDeleteUser') ??
            'Are you sure you want to delete ${user.name ?? user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete user
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n?.translate('delete') ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}
