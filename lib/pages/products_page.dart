import '../models/category.dart';
import 'package:admin_ai_web/config/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../dialogs/product_dialogs.dart';
import '../widgets/loading_screen.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = true;
  Set<String> _selectedProducts = {};
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts.add(productId);
      }
    });
  }

  void _showBulkActionDialog(
      BuildContext context, List<Product> selectedProducts) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('bulkActions') ?? 'Bulk Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title:
                  Text(l10n?.translate('moveToCategory') ?? 'Move to Category'),
              onTap: () {
                Navigator.pop(context);
                _showMoveToCategoryDialog(context, selectedProducts);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(
                l10n?.translate('deleteSelected') ?? 'Delete Selected',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteSelectedDialog(context, selectedProducts);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveToCategoryDialog(BuildContext context, List<Product> products) {
    final l10n = AppLocalizations.of(context);
    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('selectCategory') ?? 'Select Category'),
        content: StreamBuilder<List<Category>>(
          stream: context.read<AppProvider>().categoriesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return DropdownButtonFormField<String>(
              value: selectedCategoryId,
              items: snapshot.data!.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) => selectedCategoryId = value,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedCategoryId != null) {
                final provider = context.read<AppProvider>();
                for (final product in products) {
                  await provider.updateProductCategory(
                    product.id,
                    selectedCategoryId!,
                  );
                }
                setState(() => _selectedProducts.clear());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n?.translate('move') ?? 'Move'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context, List<Product> products) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('deleteProducts') ?? 'Delete Products'),
        content: Text(
          l10n?.translate('confirmDeleteMultiple') ??
              'Are you sure you want to delete ${products.length} products?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () async {
              final provider = context.read<AppProvider>();
              for (final product in products) {
                await provider.deleteProduct(product.id);
              }
              setState(() => _selectedProducts.clear());
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n?.translate('delete') ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Product> _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'name':
        products.sort((a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case 'price':
        products.sort((a, b) {
          final priceA = a.onSale ? (a.salePrice ?? a.price) : a.price;
          final priceB = b.onSale ? (b.salePrice ?? b.price) : b.price;
          return _sortAscending
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        });
        break;
      case 'date':
        products.sort((a, b) => _sortAscending
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt));
        break;
      case 'hot':
        products.sort((a, b) {
          if (a.isHot == b.isHot) {
            return _sortAscending
                ? a.name.compareTo(b.name)
                : b.name.compareTo(a.name);
          }
          return _sortAscending ? (b.isHot ? 1 : -1) : (a.isHot ? 1 : -1);
        });
        break;
      case 'new':
        products.sort((a, b) {
          if (a.isNew == b.isNew) {
            return _sortAscending
                ? a.name.compareTo(b.name)
                : b.name.compareTo(a.name);
          }
          return _sortAscending ? (b.isNew ? 1 : -1) : (a.isNew ? 1 : -1);
        });
        break;
      case 'sale':
        products.sort((a, b) {
          if (a.onSale == b.onSale) {
            return _sortAscending
                ? a.name.compareTo(b.name)
                : b.name.compareTo(a.name);
          }
          return _sortAscending ? (b.onSale ? 1 : -1) : (a.onSale ? 1 : -1);
        });
        break;
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _selectedProducts.isEmpty
            ? Text(l10n?.translate('products') ?? 'Products')
            : Text(
                '${_selectedProducts.length} ${l10n?.translate('selected') ?? 'Selected'}'),
        actions: [
          if (_selectedProducts.isEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: l10n?.translate('sort') ?? 'Sort',
              onSelected: (value) {
                setState(() {
                  if (_sortBy == value) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = value;
                    _sortAscending = true;
                  }
                });
              },
              itemBuilder: (context) => [
                _buildSortMenuItem(
                  'name',
                  _sortAscending ? 'sortNameAZ' : 'sortNameZA',
                  _sortAscending ? 'Name (A-Z)' : 'Name (Z-A)',
                ),
                _buildSortMenuItem(
                  'price',
                  _sortAscending ? 'sortPriceLowHigh' : 'sortPriceHighLow',
                  _sortAscending ? 'Price (Low-High)' : 'Price (High-Low)',
                ),
                _buildSortMenuItem(
                  'date',
                  _sortAscending ? 'sortDateNewest' : 'sortDateOldest',
                  _sortAscending ? 'Date (Newest)' : 'Date (Oldest)',
                ),
                _buildSortMenuItem(
                  'hot',
                  _sortAscending ? 'sortHotFirst' : 'sortHotLast',
                  _sortAscending ? 'Hot First' : 'Hot Last',
                ),
                _buildSortMenuItem(
                  'new',
                  _sortAscending ? 'sortNewFirst' : 'sortNewLast',
                  _sortAscending ? 'New First' : 'New Last',
                ),
                _buildSortMenuItem(
                  'sale',
                  _sortAscending ? 'sortSaleFirst' : 'sortSaleLast',
                  _sortAscending ? 'Sale First' : 'Sale Last',
                ),
              ],
            ),
          ],
          Consumer<AppProvider>(
            builder: (context, provider, _) => StreamBuilder<List<Product>>(
              stream: provider.productsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return Row(
                  children: [
                    if (_selectedProducts.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          final selectedProducts = snapshot.data!
                              .where((p) => _selectedProducts.contains(p.id))
                              .toList();
                          _showBulkActionDialog(context, selectedProducts);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            tooltip: _isGridView
                ? l10n?.translate('listView') ?? 'List View'
                : l10n?.translate('gridView') ?? 'Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => ProductDialogs.showProductDialog(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    l10n?.translate('searchProducts') ?? 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, _) => StreamBuilder<List<Product>>(
                stream: provider.productsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LoadingScreen();
                  }

                  final filteredProducts = _filterProducts(snapshot.data!);
                  final sortedProducts = _sortProducts(filteredProducts);

                  if (sortedProducts.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? l10n?.translate('noProductsFound') ??
                                'No products found'
                            : l10n?.translate('noSearchResults') ??
                                'No products match your search',
                      ),
                    );
                  }

                  return _isGridView
                      ? _buildProductGrid(context, sortedProducts)
                      : _buildProductList(context, sortedProducts);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    // Calculate columns and padding based on screen width
    int crossAxisCount;
    double padding;

    if (width < 600) {
      // Mobile
      crossAxisCount = 1;
      padding = 16.0;
    } else if (width < 900) {
      // Tablet
      crossAxisCount = 2;
      padding = 20.0;
    } else if (width < 1200) {
      // Small desktop
      crossAxisCount = 3;
      padding = 24.0;
    } else {
      // Large desktop
      crossAxisCount = 4;
      padding = 32.0;
    }

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        mainAxisSpacing: padding,
        crossAxisSpacing: padding,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = _selectedProducts.contains(product.id);

        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ProductDialogs.showEditProductDialog(context, product),
            onLongPress: () =>
                ProductDialogs.showEditProductDialog(context, product),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: product.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Row(
                              children: [
                                if (product.onSale)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'SALE',
                                      style: TextStyle(
                                        color: theme.colorScheme.onError,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (product.isHot)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.whatshot,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'HOT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (product.isNew)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.fiber_new,
                                          color: theme.colorScheme.onPrimary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              if (product.onSale &&
                                  product.salePrice != null) ...[
                                Text(
                                  '\$${product.price}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  '\$${product.salePrice}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else
                                Text(
                                  '\$${product.price}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          )),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: Text(l10n?.translate('edit') ?? 'Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete,
                            color: theme.colorScheme.error,
                          ),
                          title: Text(
                            l10n?.translate('delete') ?? 'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          ProductDialogs.showEditProductDialog(
                              context, product);
                          break;
                        case 'delete':
                          _showDeleteMenu(context, product);
                          break;
                      }
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      _toggleProductSelection(product.id);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleProductSelection(product.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(BuildContext context, List<Product> products) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = _selectedProducts.contains(product.id);

        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () => ProductDialogs.showEditProductDialog(context, product),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : null,
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _toggleProductSelection(product.id);
                      },
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleProductSelection(product.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (product.onSale && product.salePrice != null) ...[
                            Text(
                              '\$${product.price}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '\$${product.salePrice}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else
                            Text(
                              '\$${product.price}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            ProductDialogs.showEditProductDialog(
                                context, product);
                            break;
                          case 'delete':
                            _showDeleteMenu(context, product);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: Text(l10n?.translate('edit') ?? 'Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              l10n?.translate('delete') ?? 'Delete',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteMenu(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('deleteProduct') ?? 'Delete Product'),
        content: Text(l10n?.translate('confirmDeleteProduct') ??
            'Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: Text(
              l10n?.translate('delete') ?? 'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String translationKey,
    String fallback,
  ) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuItem(
      value: value,
      child: ListTile(
        leading: _sortBy == value
            ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
            : null,
        title: Text(l10n?.translate(translationKey) ?? fallback),
      ),
    );
  }
}
