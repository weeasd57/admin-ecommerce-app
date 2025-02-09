import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/responsive_layout.dart';
import 'package:admin_ai_web/config/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(l10n?.translate('dashboard') ?? 'Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.translate('dashboard') ?? 'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ResponsiveLayout(
              mobile: _buildStatCards(context, appProvider.dashboardDataStream,
                  crossAxisCount: 1),
              tablet: _buildStatCards(context, appProvider.dashboardDataStream,
                  crossAxisCount: 2),
              desktop: _buildStatCards(context, appProvider.dashboardDataStream,
                  crossAxisCount: 4),
            ),
            const SizedBox(height: 24),
            _buildRecentOrders(context),
            const SizedBox(height: 24),
            _buildRecentUsers(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(
      BuildContext context, Stream<Map<String, dynamic>> dataStream,
      {required int crossAxisCount}) {
    final l10n = AppLocalizations.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return FutureBuilder<Map<String, dynamic>>(
          future: dataStream.first,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.translate('error') ?? 'Error',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final stat = [
              {
                'title': l10n?.translate('totalSales') ?? 'Total Sales',
                'value':
                    '\$${data['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                'icon': Icons.attach_money,
                'color': Colors.green,
              },
              {
                'title': l10n?.translate('totalOrders') ?? 'Total Orders',
                'value': data['totalOrders']?.toString() ?? '0',
                'icon': Icons.shopping_cart,
                'color': Colors.blue,
              },
              {
                'title': l10n?.translate('totalProducts') ?? 'Total Products',
                'value': data['totalProducts']?.toString() ?? '0',
                'icon': Icons.inventory,
                'color': Colors.orange,
              },
              {
                'title': l10n?.translate('totalUsers') ?? 'Total Users',
                'value': data['totalUsers']?.toString() ?? '0',
                'icon': Icons.people,
                'color': Colors.purple,
              },
            ][index];

            return _buildStatCard(context, stat['icon'] as IconData,
                stat['title'] as String, stat['value'] as String);
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleMedium),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.translate('recentOrders') ?? 'Recent Orders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return StreamBuilder(
                  stream: appProvider.ordersStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(l10n?.translate('errorLoadingOrders') ??
                          'Error loading orders');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders = snapshot.data ?? [];
                    final recentOrders = orders.take(5).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentOrders.length,
                      itemBuilder: (context, index) {
                        final order = recentOrders[index];
                        return ListTile(
                          title: Text(l10n?.translate('orderNumber') ??
                              'Order #${order.id}'),
                          subtitle: Text(l10n?.translate('currency') ??
                              '\$${order.total.toStringAsFixed(2)}'),
                          trailing: Chip(
                            label: Text(
                                l10n?.translate(order.status) ?? order.status),
                            backgroundColor: _getStatusColor(order.status),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsers(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.translate('recentUsers') ?? 'Recent Users',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return StreamBuilder(
                  stream: appProvider.usersStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(l10n?.translate('errorLoadingUsers') ??
                          'Error loading users');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data ?? [];
                    final recentUsers = users.take(5).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentUsers.length,
                      itemBuilder: (context, index) {
                        final user = recentUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(l10n?.translate('userInitial') ??
                                    user.name?[0].toUpperCase() ??
                                    '')
                                : null,
                          ),
                          title: Text(user.name ??
                              l10n?.translate('noName') ??
                              user.email),
                          subtitle:
                              Text(l10n?.translate('emailLabel') ?? user.email),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
