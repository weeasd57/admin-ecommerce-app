import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/app_provider.dart';
import '../widgets/responsive_layout.dart';
import '../dialogs/category_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'dart:html' as html;

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  Set<String> _selectedCategories = {};
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _selectedCategories.isEmpty
            ? Text(l10n?.translate('categories') ?? 'Categories')
            : Text('${_selectedCategories.length} Selected'),
        actions: [
          if (_selectedCategories.isNotEmpty) ...[
            // Cancel selection button
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n?.translate('cancelSelection') ?? 'Cancel Selection',
              onPressed: () {
                setState(() {
                  _selectedCategories.clear();
                });
              },
            ),
            // Delete selected button
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n?.translate('deleteSelected') ?? 'Delete Selected',
              onPressed: () => _showDeleteSelectedDialog(context),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => CategoryDialogs.showAddCategoryDialog(context),
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Category>>(
          stream: provider.categoriesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text(
                      l10n?.translate('error') ?? 'Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return Center(
                  child: Text(l10n?.translate('loading') ?? 'Loading...'));
            }

            final categories = snapshot.data!;
            if (categories.isEmpty) {
              return Center(
                  child: Text(l10n?.translate('noCategories') ??
                      'No categories found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ResponsiveLayout(
                mobile: _buildCategoriesGrid(context, categories,
                    crossAxisCount: 1),
                tablet: _buildCategoriesGrid(context, categories,
                    crossAxisCount: 2),
                desktop: _buildCategoriesGrid(context, categories,
                    crossAxisCount: 4),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    List<Category> categories, {
    required int crossAxisCount,
  }) {
    final l10n = AppLocalizations.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategories.contains(category.id);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Main content with click handler
              InkWell(
                onTap: () => _showCategoryProducts(context, category),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: category.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.category),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Checkbox
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category.id);
                      } else {
                        _selectedCategories.add(category.id);
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),

              // Tools Menu
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.white,
                    ),
                    onSelected: (value) async {
                      final isPublic = category.name.toLowerCase() == 'public';
                      switch (value) {
                        case 'edit':
                          await _showEditCategoryDialog(context, category);
                          break;
                        case 'delete':
                          if (!isPublic) {
                            await _showDeleteConfirmDialog(context, category);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      final isPublic = category.name.toLowerCase() == 'public';
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: Text(l10n?.translate('edit') ?? 'Edit'),
                          ),
                        ),
                        if (!isPublic)
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading:
                                  const Icon(Icons.delete, color: Colors.red),
                              title:
                                  Text(l10n?.translate('delete') ?? 'Delete'),
                            ),
                          ),
                      ];
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    // Get categories and filter
    provider.getCategories().then((categories) {
      final selectedCategoriesToDelete = _selectedCategories.where((id) {
        final category = categories.firstWhere(
          (c) => c.id == id,
          orElse: () => Category(id: '', name: '', imageUrl: ''),
        );
        return category.name.toLowerCase() != 'public';
      }).toList();

      if (selectedCategoriesToDelete.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.translate('cannotDeletePublic') ??
                'Cannot delete public category'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:
              Text(l10n?.translate('deleteCategories') ?? 'Delete Categories'),
          content: Text(
            l10n?.translate('confirmDeleteMultiple')?.replaceAll(
                      '{count}',
                      selectedCategoriesToDelete.length.toString(),
                    ) ??
                'Are you sure you want to delete these ${selectedCategoriesToDelete.length} categories?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () async {
                Navigator.pop(context);

                for (final id in selectedCategoriesToDelete) {
                  await provider.deleteCategory(id);
                }

                setState(() {
                  _selectedCategories.clear();
                });
              },
              child: Text(l10n?.translate('delete') ?? 'Delete'),
            ),
          ],
        ),
      );
    });
  }

  void _showCategoryProducts(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Consumer<AppProvider>(
        builder: (context, provider, _) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.translate('productsInCategory')?.replaceAll(
                                '{category}',
                                category.name,
                              ) ??
                          '${category.name} Products',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<Product>>(
                    future: provider.getProductsByCategory(category.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(l10n?.translate('error') ??
                              'Error: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!;
                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            l10n?.translate('noCategoryProducts')?.replaceAll(
                                      '{category}',
                                      category.name,
                                    ) ??
                                'No products in ${category.name}',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: CachedNetworkImage(
                                  imageUrl: product.imageUrls.first,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (product.isHot)
                                  Tooltip(
                                    message: l10n?.translate('hot') ?? 'Hot',
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.whatshot,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                if (product.isNew)
                                  Tooltip(
                                    message: l10n?.translate('new') ?? 'New',
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.fiber_new,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                if (product.onSale)
                                  Tooltip(
                                    message:
                                        l10n?.translate('onSale') ?? 'On Sale',
                                    child: const Icon(
                                      Icons.local_offer,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '\$${product.price}',
                                  style: product.onSale
                                      ? const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                        )
                                      : null,
                                ),
                                if (product.onSale) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${product.salePrice}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditCategoryDialog(
      BuildContext context, Category category) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: category.name);
    final imageChanged = ValueNotifier<bool>(false);
    final selectedImageNotifier = ValueNotifier<String?>(category.imageUrl);
    final isPublic = category.name.toLowerCase() == 'public';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('editCategory') ?? 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPublic)
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n?.translate('categoryName') ?? 'Category Name',
                ),
              ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: selectedImageNotifier,
              builder: (context, imageUrl, _) {
                return Column(
                  children: [
                    if (imageUrl != null)
                      Stack(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                          l10n?.translate('changeImage') ?? 'Change Image'),
                      onPressed: () async {
                        final provider = context.read<AppProvider>();
                        final uploadInput = html.FileUploadInputElement()
                          ..accept = 'image/*';
                        uploadInput.click();

                        await uploadInput.onChange.first;
                        if (uploadInput.files!.isNotEmpty) {
                          final urls = await provider.uploadImages(
                            files: uploadInput.files!,
                            folder: 'categories',
                          );
                          if (urls.isNotEmpty) {
                            selectedImageNotifier.value = urls.first;
                            imageChanged.value = true;
                          }
                        }
                      },
                    ),
                  ],
                );
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
            onPressed: () async {
              final provider = context.read<AppProvider>();
              if (imageChanged.value) {
                // Delete old image if changed
                final oldImageRef = storage.FirebaseStorage.instance
                    .refFromURL(category.imageUrl);
                await oldImageRef.delete();
              }

              await provider.updateCategory(
                id: category.id,
                name: isPublic ? category.name : nameController.text,
                imageUrl: selectedImageNotifier.value!,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n?.translate('save') ?? 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(
      BuildContext context, Category category) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate('deleteCategory') ?? 'Delete Category'),
        content: Text(
          l10n?.translate('confirmDeleteCategory')?.replaceAll(
                    '{category}',
                    category.name,
                  ) ??
              'Are you sure you want to delete ${category.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.translate('delete') ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<AppProvider>();

      // Delete image from storage first
      final imageRef =
          storage.FirebaseStorage.instance.refFromURL(category.imageUrl);
      await imageRef.delete();

      // Then delete the category
      await provider.deleteCategory(category.id);
    }
  }
}
