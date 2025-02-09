import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/app_provider.dart';
import '../widgets/responsive_layout.dart';
import 'package:admin_ai_web/config/app_localizations.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.translate('orders') ?? 'Orders'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Order>>(
          stream: provider.ordersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(l10n?.translate('errorLoadingOrders') ??
                  'Error loading orders');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return Center(
                  child: Text(
                      l10n?.translate('noOrdersFound') ?? 'No orders found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveLayout(
                    mobile: _buildOrdersList(context, orders, compact: true),
                    tablet: _buildOrdersList(context, orders),
                    desktop: _buildOrdersList(context, orders),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders,
      {bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n?.translate('orderId') ?? 'Order ID')),
            DataColumn(label: Text(l10n?.translate('date') ?? 'Date')),
            DataColumn(label: Text(l10n?.translate('customer') ?? 'Customer')),
            if (!compact)
              DataColumn(label: Text(l10n?.translate('items') ?? 'Items')),
            DataColumn(label: Text(l10n?.translate('total') ?? 'Total')),
            DataColumn(label: Text(l10n?.translate('status') ?? 'Status')),
            DataColumn(label: Text(l10n?.translate('actions') ?? 'Actions')),
          ],
          rows: orders.map((order) {
            return DataRow(
              cells: [
                DataCell(Text(order.id)),
                DataCell(Text(_formatDate(order.createdAt))),
                DataCell(Text(order.userId)),
                if (!compact)
                  DataCell(
                    Tooltip(
                      message: order.items
                          .map(
                              (item) => '${item.quantity}x ${item.productName}')
                          .join('\n'),
                      child: Text(
                        order.items
                            .map((item) =>
                                '${item.quantity}x ${item.productName}')
                            .join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                DataCell(Text('\$${order.total.toStringAsFixed(2)}')),
                DataCell(_buildStatusChip(context, order.status)),
                DataCell(_buildStatusMenu(context, order)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusMenu(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        _buildStatusMenuItem(
            'pending', l10n?.translate('markAsPending') ?? 'Mark as Pending'),
        _buildStatusMenuItem('processing',
            l10n?.translate('markAsProcessing') ?? 'Mark as Processing'),
        _buildStatusMenuItem(
            'shipped', l10n?.translate('markAsShipped') ?? 'Mark as Shipped'),
        _buildStatusMenuItem('delivered',
            l10n?.translate('markAsDelivered') ?? 'Mark as Delivered'),
        _buildStatusMenuItem('cancelled',
            l10n?.translate('markAsCancelled') ?? 'Mark as Cancelled'),
      ],
      onSelected: (status) async {
        final provider = Provider.of<AppProvider>(context, listen: false);
        final success = await provider.updateOrderStatus(order.id, status);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Order status updated successfully'
                    : 'Failed to update order status',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(String value, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(value),
              shape: BoxShape.circle,
            ),
          ),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
