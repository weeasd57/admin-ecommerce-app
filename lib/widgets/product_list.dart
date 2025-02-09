import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_localizations.dart';

class ProductList extends StatelessWidget {
  final List<Product> products;

  const ProductList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 2,
          color: theme.colorScheme.surface,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: product.imageUrls.first,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(l10n?.translate('loading') ?? 'Loading...'),
                ),
                errorWidget: (context, url, error) => Tooltip(
                  message: l10n?.translate('error') ?? 'Error loading image',
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n?.translate('price')}: ${l10n?.translate('currency') ?? '\$'}${product.price}',
                ),
                if (product.onSale && product.salePrice != null)
                  Text(
                    '${l10n?.translate('salePrice')}: ${l10n?.translate('currency') ?? '\$'}${product.salePrice!}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.isHot)
                  Tooltip(
                    message: l10n?.translate('hot') ?? 'Hot',
                    child: Icon(
                      Icons.whatshot,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                if (product.isNew)
                  Tooltip(
                    message: l10n?.translate('new') ?? 'New',
                    child: Icon(
                      Icons.fiber_new,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
