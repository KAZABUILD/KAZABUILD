/// Debug page to check admin access
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';

class AdminAccessDebugPage extends ConsumerWidget {
  const AdminAccessDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access Debug'),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'No user logged in',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please log in first',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final isAdmin = user.userRole.isAdministrator;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Information',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Username', user.username),
                        _buildInfoRow('Display Name', user.displayName),
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow('User Role', user.userRole.name),
                        _buildInfoRow('Role Value', user.userRole.value.toString()),
                        _buildInfoRow('Is Administrator', isAdmin.toString()),
                        _buildInfoRow('Raw JSON Role', 'Check console logs'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: isAdmin ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAdmin ? Icons.check_circle : Icons.cancel,
                              color: isAdmin ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAdmin ? 'Admin Access: GRANTED' : 'Admin Access: DENIED',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: isAdmin ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                          Text(
                            isAdmin
                                ? 'You have administrator privileges and can access the admin panel.'
                                : 'You do not have administrator privileges. Required roles: ADMINISTRATOR (6), OWNER (7), or SYSTEM (8). Your role: ${user.userRole.name} (${user.userRole.value}).',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (!isAdmin) ...[
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.blue.withValues(alpha: 0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Troubleshooting:',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('1. Check browser console (F12) for detailed logs'),
                                    const Text('2. Verify your role in the database is ADMINISTRATOR, OWNER, or SYSTEM'),
                                    const Text('3. Try logging out and logging back in'),
                                    const Text('4. Check that backend is returning UserRole correctly'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isAdmin)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Roles',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text('• ADMINISTRATOR (value: 6)'),
                          const Text('• OWNER (value: 7)'),
                          const SizedBox(height: 16),
                          Text(
                            'Your Current Role',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('• ${user.userRole.name.toUpperCase()} (value: ${user.userRole.value})'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading user data',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

