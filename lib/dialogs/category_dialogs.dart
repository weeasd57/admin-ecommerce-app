import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import 'dart:html' as html;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';

class CategoryDialogState extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  void setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}

class CategoryDialogs {
  static Future<void> showDeleteCategoryDialog(
    BuildContext context,
    Category category,
  ) async {
    // Prevent deletion of public category
    if (category.name.toLowerCase() == 'public') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The public category cannot be deleted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Check if category has products
    final products = await provider.getProductsByCategory(category.id);
    if (products.isEmpty) {
      // If no products, show simple delete confirmation
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete ${category.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        final success = await provider.deleteCategory(category.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Category deleted successfully'
                    : 'Failed to delete category',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } else {
      // If has products, show product reassignment dialog
      final categories = await provider.getCategories();
      final otherCategories =
          categories.where((c) => c.id != category.id).toList();

      if (otherCategories.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot delete the last category. Create another category first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String? selectedCategoryId = otherCategories.first.id;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Category ${category.name} has ${products.length} products. Select a category to move them to:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Move products to',
                  border: OutlineInputBorder(),
                ),
                items: otherCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCategoryId = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete and Move Products'),
            ),
          ],
        ),
      );

      if (confirmed == true && selectedCategoryId != null) {
        final success = await provider.deleteCategoryAndMoveProducts(
          category.id,
          selectedCategoryId!,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Category deleted and products moved successfully'
                    : 'Failed to delete category',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    }
  }

  static Future<void> showAddCategoryDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final selectedImageNotifier = ValueNotifier<String?>(null);
    final dialogState = CategoryDialogState();

    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: dialogState,
        child: Consumer2<AppProvider, CategoryDialogState>(
          builder: (context, provider, state, _) => AlertDialog(
            title: const Text('Add Category'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        if (value.toLowerCase() == 'public') {
                          return 'Category name "Public" is reserved';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Select Image'),
                      onPressed: state.isSaving
                          ? null
                          : () async {
                              final uploadInput = html.FileUploadInputElement()
                                ..accept = 'image/*';
                              uploadInput.click();

                              try {
                                await uploadInput.onChange.first;
                                if (uploadInput.files!.isNotEmpty) {
                                  state.setSaving(true);
                                  final urls = await provider.uploadImages(
                                    files: uploadInput.files!,
                                    folder: 'categories',
                                  );
                                  if (urls.isNotEmpty) {
                                    selectedImageNotifier.value = urls.first;
                                  }
                                }
                              } finally {
                                state.setSaving(false);
                              }
                            },
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: selectedImageNotifier,
                      builder: (context, imageUrl, _) {
                        if (imageUrl == null) return const SizedBox();
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 200,
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    selectedImageNotifier.value = null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSaving || selectedImageNotifier.value == null
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          state.setSaving(true);
                          try {
                            final category = Category(
                              id: const Uuid().v4(),
                              name: nameController.text,
                              imageUrl: selectedImageNotifier.value!,
                            );
                            final success =
                                await provider.addCategory(category);
                            if (success && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          } finally {
                            if (context.mounted) {
                              state.setSaving(false);
                            }
                          }
                        }
                      },
                child: Text(state.isSaving ? 'Saving...' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showEditCategoryDialog(
    BuildContext context,
    Category category,
  ) async {
    if (category.name.toLowerCase() == 'public') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The public category cannot be edited'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final imageUrlNotifier = ValueNotifier<String>(category.imageUrl);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<AppProvider>(
        builder: (context, provider, _) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category name';
                      }
                      if (value.toLowerCase() == 'public') {
                        return 'Category name "Public" is reserved';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: imageUrlNotifier,
                    builder: (context, imageUrl, _) => Column(
                      children: [
                        if (imageUrl.isNotEmpty)
                          Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () => imageUrlNotifier.value = '',
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            provider.isUploadingImages
                                ? 'Uploading...'
                                : 'Change Image',
                          ),
                          onPressed: provider.isUploadingImages
                              ? null
                              : () async {
                                  final uploadInput =
                                      html.FileUploadInputElement()
                                        ..accept = 'image/*';
                                  uploadInput.click();

                                  try {
                                    await uploadInput.onChange.first;
                                    if (uploadInput.files!.isNotEmpty) {
                                      final url =
                                          await provider.uploadCategoryImage(
                                              uploadInput.files!.first);
                                      imageUrlNotifier.value = url;
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Failed to upload image'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await provider.updateCategory(
                    id: category.id,
                    name: nameController.text,
                    imageUrl: imageUrlNotifier.value,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully')),
      );
    }
  }

  static Future<void> showEditPublicCategoryImageDialog(
    BuildContext context,
    Category category,
  ) async {
    final dialogState = CategoryDialogState();
    final selectedImageNotifier = ValueNotifier<String?>(category.imageUrl);

    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: dialogState,
        child: Consumer2<AppProvider, CategoryDialogState>(
          builder: (context, provider, state, _) => AlertDialog(
            title: const Text('Change Public Category Image'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: selectedImageNotifier,
                    builder: (context, imageUrl, _) {
                      if (imageUrl == null || imageUrl.isEmpty) {
                        return const SizedBox();
                      }
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 200,
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label:
                        Text(state.isSaving ? 'Uploading...' : 'Change Image'),
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            final uploadInput = html.FileUploadInputElement()
                              ..accept = 'image/*';
                            uploadInput.click();

                            try {
                              await uploadInput.onChange.first;
                              if (uploadInput.files!.isNotEmpty) {
                                state.setSaving(true);
                                final urls = await provider.uploadImages(
                                  files: uploadInput.files!,
                                  folder: 'categories',
                                );
                                if (urls.isNotEmpty) {
                                  selectedImageNotifier.value = urls.first;
                                }
                              }
                            } finally {
                              state.setSaving(false);
                            }
                          },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: state.isSaving
                    ? null
                    : () async {
                        if (selectedImageNotifier.value != null) {
                          state.setSaving(true);
                          try {
                            final success = await provider.updateCategory(
                              id: category.id,
                              name: category.name, // Keep name unchanged
                              imageUrl: selectedImageNotifier.value!,
                            );
                            if (success && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          } finally {
                            state.setSaving(false);
                          }
                        }
                      },
                child: Text(state.isSaving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
