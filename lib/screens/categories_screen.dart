import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const Color _deepBlue = Color(0xFF0F172A);
  static const Color _turquoise = Color(0xFF00B8A9);

  static const List<Color> _pastelColors = [
    Color(0xFFE0F2FE),
    Color(0xFFF0FDF9),
    Color(0xFFFEF3C7),
    Color(0xFFDCFCE7),
    Color(0xFFFCE7F3),
    Color(0xFFEDE9FE),
    Color(0xFFFFEDD5),
    Color(0xFFECFEFF),
    Color(0xFFF1F5F9),
  ];

  String? _selectedCategory;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      if (productsProvider.products.isEmpty && !productsProvider.isLoading) {
        productsProvider.fetchProducts();
      }
    });
  }

  List<String> _extractCategories(List<Product> products) {
    final cats = products
        .map((p) => p.categorie)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()..sort();
    return cats;
  }

  List<String> _extractCities(List<Product> products, String category) {
    final cities = products
        .where((p) => p.categorie == category && p.vendeurLocalisation.isNotEmpty)
        .map((p) => p.vendeurLocalisation)
        .toSet()
        .toList()..sort();
    return cities;
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      final matchesCategory = _selectedCategory == null || p.categorie == _selectedCategory;
      final matchesCity = _selectedCity == null || _selectedCity == '' || p.vendeurLocalisation == _selectedCity;
      return matchesCategory && matchesCity;
    }).toList();
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'téléphones':
        return Icons.phone_android;
      case 'ordinateurs':
        return Icons.computer;
      case 'audio':
        return Icons.headphones;
      case 'accessoires':
        return Icons.devices_other;
      case 'tablettes':
        return Icons.tablet;
      case 'montres':
        return Icons.watch;
      case 'tv':
        return Icons.tv;
      case 'électroménager':
        return Icons.kitchen;
      default:
        return Icons.category;
    }
  }

  int _gridCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 700) return 4;
    if (w >= 400) return 3;
    return 2;
  }

  void _goBack() {
    if (_selectedCity != null) {
      setState(() {
        _selectedCity = null;
      });
    } else if (_selectedCategory != null) {
      setState(() {
        _selectedCategory = null;
        _selectedCity = null;
      });
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;
    final titleFontSize = screenWidth < 400 ? 16.0 : 20.0;

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _deepBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            _appBarTitle(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _goBack,
          ),
        ),
        body: Consumer<ProductsProvider>(
          builder: (context, productsProvider, child) {
            final products = productsProvider.products;

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: _buildContent(productsProvider, products, horizontalPadding),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _appBarTitle() {
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      return '$_selectedCategory • $_selectedCity';
    }
    if (_selectedCategory != null) {
      return _selectedCategory!;
    }
    return 'Catégories';
  }

  Widget _buildContent(ProductsProvider productsProvider, List<Product> products, double horizontalPadding) {
    if (productsProvider.isLoading && products.isEmpty) {
      return _buildLoadingState(horizontalPadding);
    }

    if (productsProvider.error != null && products.isEmpty) {
      return _buildErrorState(productsProvider, horizontalPadding);
    }

    if (_selectedCategory == null) {
      return _buildCategoryGrid(_extractCategories(products), horizontalPadding);
    }

    if (_selectedCity == null || _selectedCity == '') {
      final cities = _extractCities(products, _selectedCategory!);
      return _buildCityGrid(cities, horizontalPadding);
    }

    final filtered = _filterProducts(products);
    return _buildProductGrid(filtered, filtered.isEmpty, horizontalPadding);
  }

  Widget _buildLoadingState(double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
      width: double.infinity,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(ProductsProvider productsProvider, double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erreur: ${productsProvider.error}',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: productsProvider.fetchProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: _turquoise,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<String> categories, double horizontalPadding) {
    if (categories.isEmpty) {
      return _buildEmptyState(horizontalPadding, 'Aucune catégorie disponible', Icons.category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 16),
          child: const Text(
            'Toutes les catégories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _deepBlue,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = _pastelColors[index % _pastelColors.length];
              return _CategoryCard(
                icon: _categoryIcon(category),
                label: category,
                backgroundColor: color,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _selectedCity = null;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityGrid(List<String> cities, double horizontalPadding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
          child: Text(
            'Villes pour $_selectedCategory',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _deepBlue,
            ),
          ),
        ),
        if (cities.isEmpty)
          _buildCityItem('Tous les produits', _turquoise.withValues(alpha: 0.1), _turquoise, horizontalPadding, () {
            setState(() {
              _selectedCity = '';
            });
          })
        else
          ...[
            _buildCityItem('Tous les produits', _turquoise.withValues(alpha: 0.1), _turquoise, horizontalPadding, () {
              setState(() {
                _selectedCity = '';
              });
            }),
            ...cities.asMap().entries.map((entry) => _buildCityItem(entry.value, _pastelColors[entry.key % _pastelColors.length], Colors.grey.shade700, horizontalPadding, () {
              setState(() {
                _selectedCity = entry.value;
              });
            })),
          ],
      ],
    );
  }

  Widget _buildCityItem(String label, Color bgColor, Color iconColor, double horizontalPadding, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 4),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.location_on, color: iconColor, size: 24),
          ),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: _deepBlue, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, bool isEmpty, double horizontalPadding) {
    if (isEmpty) {
      return _buildEmptyState(horizontalPadding, 'Aucun produit dans cette ville', Icons.search_off);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
          child: Text(
            'Produits de $_selectedCategory',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _deepBlue,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _CategoryProductCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double horizontalPadding, String message, IconData icon) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final iconSize = isSmall ? 28.0 : 32.0;
    final fontSize = isSmall ? 12.0 : 13.0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmall ? 48 : 56,
                height: isSmall ? 48 : 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A), size: iconSize),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final Product product;

  const _CategoryProductCard({required this.product});

  bool _isSellerVerified() {
    final vendeur = product.vendeur;
    if (vendeur is Map<String, dynamic>) {
      return vendeur['sellerVerified'] == true || vendeur['seller_verified'] == true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isVerified = _isSellerVerified();
    const Color deepBlue = Color(0xFF0F172A);
    const Color turquoise = Color(0xFF00B8A9);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                context.push('/product/${product.id}', extra: product);
              },
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: deepBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: turquoise,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified, size: 12, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: turquoise,
                    ),
                  ),
                  Text(
                    '${product.categorie} • ${product.vendeurNom}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text('Panier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: deepBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        cartProvider.addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ajouté au panier'),
                            backgroundColor: turquoise,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
