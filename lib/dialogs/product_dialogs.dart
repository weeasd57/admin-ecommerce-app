import 'package:admin_ai_web/config/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:html' as html;

class ProductDialogState extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  List<String> _selectedImages = [];
  List<String> get selectedImages => _selectedImages;

  bool _isHot = false;
  bool get isHot => _isHot;

  bool _isNew = false;
  bool get isNew => _isNew;

  bool _onSale = false;
  bool get onSale => _onSale;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  bool get isValid => selectedImages.isNotEmpty && selectedCategoryId != null;

  String? get imageError =>
      selectedImages.isEmpty ? 'Please select at least one image' : null;

  void setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void addImages(List<String> images) {
    _selectedImages.addAll(images);
    notifyListeners();
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  void setHot(bool value) {
    _isHot = value;
    notifyListeners();
  }

  void setNew(bool value) {
    _isNew = value;
    notifyListeners();
  }

  void setOnSale(bool value) {
    _onSale = value;
    notifyListeners();
  }

  void setSelectedCategory(String? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void initFromProduct(Product product) {
    _selectedImages = List.from(product.imageUrls);
    _isHot = product.isHot;
    _isNew = product.isNew;
    _onSale = product.onSale;
    _selectedCategoryId = product.categoryId;
    notifyListeners();
  }

  Future<void> deleteImage(BuildContext context, AppProvider provider,
      Product product, int index) async {
    setSaving(true);
    try {
      final success = await provider.deleteProductImage(
        product.id,
        selectedImages[index],
      );
      if (!success) {
        throw Exception('Delete failed');
      }
      removeImage(index);
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.translate('imageDeleteError') ??
                'Failed to delete image'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setSaving(false);
    }
  }

  Future<void> uploadImages(BuildContext context, AppProvider provider) async {
    final uploadInput = html.FileUploadInputElement()
      ..multiple = true
      ..accept = 'image/*';

    uploadInput.click();

    try {
      await uploadInput.onChange.first;
      if (uploadInput.files!.isNotEmpty) {
        setSaving(true);
        final urls = await provider.uploadImages(
          files: uploadInput.files!,
          folder: 'products',
        );
        addImages(urls);
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.translate('errorUploadingImages') ??
                'Failed to upload images'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setSaving(false);
    }
  }
}

class ProductDialogs {
  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  static Future<void> showProductDialog(
    BuildContext context, {
    bool isEdit = false,
    Product? product,
  }) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final dialogState = ProductDialogState();

    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.8; // 80% of screen width
    final maxWidth = 800.0; // Maximum width

    final nameController = TextEditingController(text: product?.name);
    final descriptionController =
        TextEditingController(text: product?.description);
    final priceController =
        TextEditingController(text: product?.price.toString());
    final salePriceController =
        TextEditingController(text: product?.salePrice?.toString());

    if (isEdit && product != null) {
      dialogState.initFromProduct(product);
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider.value(
        value: dialogState,
        child: Consumer2<AppProvider, ProductDialogState>(
          builder: (context, provider, state, _) => Dialog(
            child: Container(
              width: dialogWidth > maxWidth ? maxWidth : dialogWidth,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit
                              ? l10n?.translate('editProduct') ?? 'Edit Product'
                              : l10n?.translate('addProduct') ?? 'Add Product',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: nameController,
                                label: l10n?.translate('productName') ??
                                    'Product Name',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n?.translate(
                                            'productNameRequired') ??
                                        'Please enter a product name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: descriptionController,
                                label: l10n?.translate('description') ??
                                    'Description',
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n?.translate(
                                            'descriptionRequired') ??
                                        'Please enter a description';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: priceController,
                                label: l10n?.translate('price') ?? 'Price',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n?.translate('priceRequired') ??
                                        'Please enter a price';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null) {
                                    return l10n?.translate('invalidPrice') ??
                                        'Please enter a valid number';
                                  }
                                  if (price <= 0) {
                                    return l10n?.translate(
                                            'priceMustBePositive') ??
                                        'Price must be greater than 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: Text(
                                    l10n?.translate('onSale') ?? 'On Sale'),
                                value: state.onSale,
                                onChanged: (value) {
                                  state.setOnSale(value);
                                },
                              ),
                              if (state.onSale) ...[
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: salePriceController,
                                  label: l10n?.translate('salePrice') ??
                                      'Sale Price',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a sale price';
                                    }
                                    final salePrice = double.tryParse(value);
                                    if (salePrice == null) {
                                      return 'Please enter a valid number';
                                    }
                                    final price =
                                        double.parse(priceController.text);
                                    if (salePrice >= price) {
                                      return 'Sale price must be less than regular price';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),
                              StreamBuilder<List<Category>>(
                                stream: provider.categoriesStream,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }
                                  final categories =
                                      snapshot.data!.toSet().toList();
                                  return DropdownButtonFormField<String>(
                                    value: state.selectedCategoryId,
                                    items: categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      state.setSelectedCategory(value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: l10n?.translate('category') ??
                                          'Category',
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon:
                                          const Icon(Icons.add_photo_alternate),
                                      label: Text(
                                        state.isSaving
                                            ? l10n?.translate('uploading') ??
                                                'Uploading...'
                                            : l10n?.translate('selectImages') ??
                                                'Select Images',
                                      ),
                                      onPressed: state.isSaving
                                          ? null
                                          : () async {
                                              await state.uploadImages(
                                                  context, provider);
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              if (state.selectedImages.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: state.selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    state.selectedImages[index],
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(Icons.close,
                                                      size: 20,
                                                      color: Colors.white),
                                                  onPressed: state.isSaving
                                                      ? null
                                                      : () async {
                                                          await state
                                                              .deleteImage(
                                                                  context,
                                                                  provider,
                                                                  product!,
                                                                  index);
                                                        },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (state.imageError != null) ...[
                                Text(
                                  state.imageError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              SwitchListTile(
                                title: Text(
                                    l10n?.translate('hot') ?? 'Hot Product'),
                                value: state.isHot,
                                onChanged: (value) {
                                  state.setHot(value);
                                },
                              ),
                              SwitchListTile(
                                title: Text(
                                    l10n?.translate('new') ?? 'New Product'),
                                value: state.isNew,
                                onChanged: (value) {
                                  state.setNew(value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: state.isSaving || !state.isValid
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    state.setSaving(true);
                                    try {
                                      final success = isEdit
                                          ? await provider.updateProduct(
                                              id: product!.id,
                                              name: nameController.text,
                                              description:
                                                  descriptionController.text,
                                              price: double.parse(
                                                  priceController.text),
                                              categoryId:
                                                  state.selectedCategoryId ??
                                                      '',
                                              images: state.selectedImages,
                                              isHot: state.isHot,
                                              isNew: state.isNew,
                                              onSale: state.onSale,
                                              salePrice: state.onSale
                                                  ? double.tryParse(
                                                      salePriceController.text)
                                                  : null,
                                            )
                                          : await provider.addProduct(
                                              name: nameController.text,
                                              description:
                                                  descriptionController.text,
                                              price: double.parse(
                                                  priceController.text),
                                              categoryId:
                                                  state.selectedCategoryId ??
                                                      '',
                                              images: state.selectedImages,
                                              isHot: state.isHot,
                                              isNew: state.isNew,
                                              onSale: state.onSale,
                                              salePrice: state.onSale
                                                  ? double.tryParse(
                                                      salePriceController.text)
                                                  : null,
                                            );

                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        state.setSaving(false);
                                      }
                                    }
                                  }
                                },
                          child: Text(state.isSaving
                              ? l10n?.translate('saving') ?? 'Saving...'
                              : l10n?.translate('save') ?? 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showEditProductDialog(
    BuildContext context,
    Product product,
  ) async {
    final l10n = AppLocalizations.of(context);
    final _formKey = GlobalKey<FormState>();
    final dialogState = ProductDialogState();

    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.8;

    // Initialize controllers with product data
    final nameController = TextEditingController(text: product.name);
    final descriptionController =
        TextEditingController(text: product.description);
    final priceController =
        TextEditingController(text: product.price.toString());
    final salePriceController =
        TextEditingController(text: product.salePrice?.toString() ?? '');

    // Initialize state with product data
    dialogState.initFromProduct(product);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider.value(
        value: dialogState,
        child: Consumer2<AppProvider, ProductDialogState>(
          builder: (context, provider, state, _) => Dialog(
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxWidth: 800), // Maximum width
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n?.translate('editProduct') ?? 'Edit Product',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: l10n?.translate('productName') ??
                                      'Product Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a product name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: descriptionController,
                                decoration: InputDecoration(
                                  labelText: l10n?.translate('description') ??
                                      'Description',
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: priceController,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n?.translate('price') ?? 'Price',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'Price must be greater than 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: Text(
                                    l10n?.translate('onSale') ?? 'On Sale'),
                                value: state.onSale,
                                onChanged: (value) {
                                  state.setOnSale(value);
                                },
                              ),
                              if (state.onSale) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: salePriceController,
                                  decoration: InputDecoration(
                                    labelText: l10n?.translate('salePrice') ??
                                        'Sale Price',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a sale price';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    final salePrice = double.parse(value);
                                    final price =
                                        double.parse(priceController.text);
                                    if (salePrice >= price) {
                                      return 'Sale price must be less than regular price';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),
                              StreamBuilder<List<Category>>(
                                stream: provider.categoriesStream,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }
                                  final categories =
                                      snapshot.data!.toSet().toList();
                                  return DropdownButtonFormField<String>(
                                    value: state.selectedCategoryId,
                                    items: categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      state.setSelectedCategory(value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: l10n?.translate('category') ??
                                          'Category',
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon:
                                          const Icon(Icons.add_photo_alternate),
                                      label: Text(
                                        state.isSaving
                                            ? l10n?.translate('uploading') ??
                                                'Uploading...'
                                            : l10n?.translate('selectImages') ??
                                                'Select Images',
                                      ),
                                      onPressed: state.isSaving
                                          ? null
                                          : () async {
                                              await state.uploadImages(
                                                  context, provider);
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              if (state.selectedImages.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: state.selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    state.selectedImages[index],
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(Icons.close,
                                                      size: 20,
                                                      color: Colors.white),
                                                  onPressed: state.isSaving
                                                      ? null
                                                      : () async {
                                                          await state
                                                              .deleteImage(
                                                                  context,
                                                                  provider,
                                                                  product,
                                                                  index);
                                                        },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (state.imageError != null) ...[
                                Text(
                                  state.imageError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              SwitchListTile(
                                title: Text(
                                    l10n?.translate('hot') ?? 'Hot Product'),
                                value: state.isHot,
                                onChanged: (value) {
                                  state.setHot(value);
                                },
                              ),
                              SwitchListTile(
                                title: Text(
                                    l10n?.translate('new') ?? 'New Product'),
                                value: state.isNew,
                                onChanged: (value) {
                                  state.setNew(value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: state.isSaving
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    state.setSaving(true);
                                    try {
                                      final success =
                                          await provider.updateProduct(
                                        id: product.id,
                                        name: nameController.text,
                                        description: descriptionController.text,
                                        price:
                                            double.parse(priceController.text),
                                        categoryId: state.selectedCategoryId!,
                                        images: state.selectedImages,
                                        isHot: state.isHot,
                                        isNew: state.isNew,
                                        onSale: state.onSale,
                                        salePrice: state.onSale
                                            ? double.tryParse(
                                                salePriceController.text)
                                            : null,
                                      );

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
                          child: Text(state.isSaving
                              ? l10n?.translate('saving') ?? 'Saving...'
                              : l10n?.translate('save') ?? 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showDeleteProductDialog(
    BuildContext context,
    Product product,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
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

    if (result == true) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final success = await provider.deleteProduct(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Product deleted successfully'
                  : 'Failed to delete product',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class ProductDialogForm extends StatefulWidget {
  final bool isEdit;
  final Product? product;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController salePriceController;
  final ValueNotifier<String?> selectedCategoryIdNotifier;
  final ValueNotifier<List<String>> selectedImagesNotifier;
  final ValueNotifier<bool> isHotNotifier;
  final ValueNotifier<bool> isNewNotifier;
  final ValueNotifier<bool> onSaleNotifier;
  final AppProvider provider;

  const ProductDialogForm({
    required this.isEdit,
    this.product,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.salePriceController,
    required this.selectedCategoryIdNotifier,
    required this.selectedImagesNotifier,
    required this.isHotNotifier,
    required this.isNewNotifier,
    required this.onSaleNotifier,
    required this.provider,
    super.key,
  });

  @override
  State<ProductDialogForm> createState() => _ProductDialogFormState();
}

class _ProductDialogFormState extends State<ProductDialogForm> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formKey = widget.formKey;
    final nameController = widget.nameController;
    final descriptionController = widget.descriptionController;
    final priceController = widget.priceController;
    final salePriceController = widget.salePriceController;
    final selectedCategoryIdNotifier = widget.selectedCategoryIdNotifier;
    final selectedImagesNotifier = widget.selectedImagesNotifier;
    final isHotNotifier = widget.isHotNotifier;
    final isNewNotifier = widget.isNewNotifier;
    final onSaleNotifier = widget.onSaleNotifier;
    final provider = widget.provider;

    return Form(
      key: formKey,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          spacing: 25,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: nameController,
              label: 'Product Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product name';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: priceController,
              label: 'Price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: onSaleNotifier,
              builder: (context, onSale, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: const Text('On Sale'),
                    value: onSale,
                    onChanged: (value) => onSaleNotifier.value = value ?? false,
                  ),
                  if (onSale)
                    _buildTextField(
                      controller: salePriceController,
                      label: 'Sale Price',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a sale price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        final salePrice = double.parse(value);
                        final price = double.parse(priceController.text);
                        if (salePrice >= price) {
                          return 'Sale price must be less than regular price';
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: selectedCategoryIdNotifier,
              builder: (context, selectedCategoryId, _) =>
                  FutureBuilder<List<Category>>(
                future: provider.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final categories = snapshot.data!;
                  final categoryExists =
                      categories.any((c) => c.id == selectedCategoryId);

                  if (!categoryExists && selectedCategoryId != null) {
                    Future.microtask(
                        () => selectedCategoryIdNotifier.value = null);
                  }

                  return DropdownButtonFormField<String>(
                    value: categoryExists ? selectedCategoryId : null,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Public'),
                      ),
                      ...categories.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (value) {
                      selectedCategoryIdNotifier.value = value;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                      _isSaving
                          ? l10n?.translate('uploading') ?? 'Uploading...'
                          : l10n?.translate('selectImages') ?? 'Select Images',
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final files = selectedImagesNotifier.value
                                .map((path) => html.File([path], 'image'))
                                .toList();
                            await provider.uploadImages(
                              files: files,
                              folder: 'products',
                            );
                          },
                  ),
                ),
              ],
            ),
            if (selectedImagesNotifier.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImagesNotifier.value.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: selectedImagesNotifier.value[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close,
                                    size: 20, color: Colors.white),
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        await provider.deleteProductImage(
                                          widget.product!.id,
                                          selectedImagesNotifier.value[index],
                                        );
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            ValueListenableBuilder<bool>(
              valueListenable: isHotNotifier,
              builder: (context, isHot, _) => CheckboxListTile(
                title: const Text('Hot Product'),
                value: isHot,
                onChanged: (value) => isHotNotifier.value = value ?? false,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isNewNotifier,
              builder: (context, isNew, _) => CheckboxListTile(
                title: const Text('New Product'),
                value: isNew,
                onChanged: (value) => isNewNotifier.value = value ?? false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
