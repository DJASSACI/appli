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
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  static const List<Color> _pastelColors = [
    Color(0xFFFFF3EA),
    Color(0xFFF8F7F5),
    Color(0xFFFFF7EF),
    Color(0xFFF5F5F5),
    Color(0xFFFFF1E6),
    Color(0xFFFAFAFA),
    Color(0xFFFFF8F2),
    Color(0xFFF7F6F4),
    Color(0xFFFFF5EC),
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
    const icons = <String,IconData>{
      'Téléphones': Icons.smartphone,
      'Ordinateurs': Icons.computer,
      'Tablettes': Icons.tablet,
      'Audio': Icons.headphones,
      'TV': Icons.tv,
      'Électroménager': Icons.kitchen,
      'Accessoires': Icons.headset_mic,
      'Montres': Icons.watch,
      'Vêtements': Icons.checkroom,
      'Chaussures': Icons.sports_soccer,
      'Sacs': Icons.backpack,
      'Beauté & Cosmétiques': Icons.face,
      'Bijoux': Icons.diamond,
      'Maison & Décoration': Icons.home,
      'Meubles': Icons.chair,
      'Cuisine': Icons.restaurant,
      'Jardin & Extérieur': Icons.local_florist,
      'Sports & Loisirs': Icons.sports_soccer,
      'Jeux & Jouets': Icons.toys,
      'Livres & Fournitures': Icons.menu_book,
      'Bébé & Enfant': Icons.child_care,
      'Auto & Moto': Icons.motorcycle,
      'Immobilier': Icons.apartment,
      'Services': Icons.handyman,
      'Alimentation': Icons.restaurant,
      'Animaux': Icons.pets,
      'Instruments de musique': Icons.music_note,
      'Matériel professionnel': Icons.business_center,
      'Électronique': Icons.devices,
      'Autre': Icons.category,
    };
    return icons[category] ?? Icons.category;
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
        backgroundColor: _offWhite,
        appBar: AppBar(
          backgroundColor: _white,
          foregroundColor: _textDark,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: _white,
          automaticallyImplyLeading: false,
          title: Text(
            _appBarTitle(),
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
            onPressed: _goBack,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _borderSoft),
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
                      color: _offWhite,
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
      return _buildCategoryGrid(categories, horizontalPadding);
    }

    if (_selectedCity == null || _selectedCity == '') {
      final categoryProducts = products
          .where((p) => p.categorie == _selectedCategory)
          .toList();
      if (categoryProducts.isEmpty) {
        return _buildEmptyState(
          horizontalPadding,
          'Aucun produit dans cette catégorie',
          Icons.search_off,
        );
      }
      final cities = _extractCities(categoryProducts, _selectedCategory!);
      return _buildCityGrid(cities, horizontalPadding);
    }

    final filtered = _filterProducts(products);
    return _buildProductGrid(filtered, filtered.isEmpty, horizontalPadding);
  }

  Widget _buildLoadingState(double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
      width: double.infinity,
      child: const Center(child: CircularProgressIndicator(color: _orangePrimary)),
    );
  }

  Widget _buildErrorState(ProductsProvider productsProvider, double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: _orangePrimary.withValues(alpha: 0.8)),
          const SizedBox(height: 16),
          Text(
            'Erreur: ${productsProvider.error}',
            style: const TextStyle(color: _textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: productsProvider.fetchProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orangePrimary,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _orangePrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Toutes les catégories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: -0.2,
                ),
              ),
            ],
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCityGrid(List<String> cities, double horizontalPadding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _orangePrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Villes pour $_selectedCategory',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (cities.isEmpty)
          _buildCityItem('Tous les produits', _orangePrimary.withValues(alpha: 0.08), _orangePrimary, horizontalPadding, () {
            setState(() {
              _selectedCity = '';
            });
          })
        else
          ...[
            _buildCityItem('Tous les produits', _orangePrimary.withValues(alpha: 0.08), _orangePrimary, horizontalPadding, () {
              setState(() {
                _selectedCity = '';
              });
            }),
            ...cities.asMap().entries.map((entry) => _buildCityItem(entry.value, _pastelColors[entry.key % _pastelColors.length], _textMuted, horizontalPadding, () {
              setState(() {
                _selectedCity = entry.value;
              });
            })),
          ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCityItem(String label, Color bgColor, Color iconColor, double horizontalPadding, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_rounded, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 22, color: _textMuted),
                ],
              ),
            ),
          ),
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
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _orangePrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Produits de $_selectedCategory',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCount(context),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _orangePrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: _orangePrimary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
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
    final iconSize = isSmall ? 24.0 : 26.0;
    final fontSize = isSmall ? 11.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: _CategoriesScreenState._white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CategoriesScreenState._borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmall ? 46 : 50,
                height: isSmall ? 46 : 50,
                decoration: BoxDecoration(
                  color: _CategoriesScreenState._orangePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _CategoriesScreenState._orangePrimary, size: iconSize),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: _CategoriesScreenState._textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.push('/product/${product.id}', extra: product);
        },
        child: Ink(
          decoration: BoxDecoration(
            color: _CategoriesScreenState._white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CategoriesScreenState._borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _CategoriesScreenState._offWhite,
                          child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: _CategoriesScreenState._offWhite,
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    if (isVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: _CategoriesScreenState._orangePrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Certifié', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _CategoriesScreenState._textDark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.price.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _CategoriesScreenState._orangePrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.categorie} • ${product.vendeurNom}',
                        style: const TextStyle(
                          color: _CategoriesScreenState._textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: const Text('Panier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _CategoriesScreenState._orangePrimary.withValues(alpha: 0.08),
                            foregroundColor: _CategoriesScreenState._orangePrimary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: _CategoriesScreenState._orangePrimary.withValues(alpha: 0.15)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            cartProvider.addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ajouté au panier'),
                                backgroundColor: _CategoriesScreenState._orangePrimary,
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
        ),
      ),
    );
  }
}
