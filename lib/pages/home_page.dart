import 'package:admin_ai_web/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../widgets/responsive_sidebar.dart';
import 'categories_page.dart';
import 'dashboard_page.dart';
import 'orders_page.dart';
import 'products_page.dart';
import 'users_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      labelKey: 'dashboard',
    ),
    const NavigationItem(
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      label: 'Categories',
      labelKey: 'categories',
    ),
    const NavigationItem(
      icon: Icons.inventory_outlined,
      selectedIcon: Icons.inventory,
      label: 'Products',
      labelKey: 'products',
    ),
    const NavigationItem(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'Orders',
      labelKey: 'orders',
    ),
    const NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Users',
      labelKey: 'users',
    ),
  ];

  void _handleLanguageChange(BuildContext context, String? code) {
    if (code != null) {
      final provider = Provider.of<LanguageProvider>(context, listen: false);
      // Close the popup menu first
      Navigator.pop(context);
      // Then change the locale
      Future.microtask(() {
        provider.setLocale(Locale(code));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Row(
        children: [
          ResponsiveSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            items: _navigationItems,
            bottomItems: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                tooltip: l10n?.translate('settings') ?? 'Settings',
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n?.translate('language') ?? 'Language'),
                      trailing: Consumer<LanguageProvider>(
                        builder: (context, provider, _) =>
                            DropdownButton<String>(
                          value: provider.locale.languageCode,
                          items: [
                            DropdownMenuItem(
                              value: 'en',
                              child:
                                  Text(l10n?.translate('english') ?? 'English'),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child:
                                  Text(l10n?.translate('arabic') ?? 'العربية'),
                            ),
                          ],
                          onChanged: (code) =>
                              _handleLanguageChange(context, code),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: _buildPage(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const CategoriesPage();
      case 2:
        return const ProductsPage();
      case 3:
        return const OrdersPage();
      case 4:
        return const UsersPage();
      default:
        return const DashboardPage();
    }
  }
}
