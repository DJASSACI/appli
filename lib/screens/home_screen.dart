import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/certification_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';

  static const Color _deepBlue = Color(0xFF0F172A);
  static const Color _turquoise = Color(0xFF00B8A9);
  static const Color _white = Colors.white;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _shortcutsCrossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 800) return 6;
    if (w >= 400) return 4;
    return 2;
  }

  int _productsCrossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    Provider.of<ProductsProvider>(context, listen: false).filterByCategory(category);
  }

  void _handleShortcutTap(String label) {
    switch (label) {
      case 'Boutiques':
        context.go('/boutiques');
        break;
      case 'Catégories':
        context.go('/categories');
        break;
      case 'Vendre':
        context.go('/sell');
        break;
      case 'Commandes':
        context.go('/my-orders');
        break;
      case 'Mes produits':
        context.go('/my-products');
        break;
      case 'Profil':
        context.go('/profile');
        break;
      default:
        _onCategorySelected('');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;
    final isSmallScreen = screenWidth < 400;
    final titleFontSize = isSmallScreen ? 17.0 : 22.0;
    final iconButtonSize = isSmallScreen ? 40.0 : 48.0;

    return Scaffold(
      backgroundColor: _deepBlue,
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: _white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'Djassa CI',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _buildCartButton(iconButtonSize),
          _buildAppBarActionButton(
            icon: Icons.storefront_outlined,
            tooltip: 'Boutiques',
            onPressed: () => context.go('/boutiques'),
            buttonSize: iconButtonSize,
          ),
          _buildAppBarActionButton(
            icon: Icons.add_circle,
            tooltip: 'Vendre',
            onPressed: () => context.go('/sell'),
            buttonSize: iconButtonSize,
          ),
          _buildAppBarActionButton(
            icon: Icons.person,
            tooltip: 'Profil',
            onPressed: () => context.go('/profile'),
            buttonSize: iconButtonSize,
          ),
          if (!isSmallScreen) const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWhiteSurface(screenWidth, horizontalPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(double buttonSize) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              constraints: BoxConstraints(
                minWidth: buttonSize,
                minHeight: buttonSize,
              ),
              icon: const Icon(Icons.shopping_cart, color: _white),
              tooltip: 'Panier',
              onPressed: () => context.go('/cart'),
            ),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _turquoise,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAppBarActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required double buttonSize,
  }) {
    return IconButton(
      constraints: BoxConstraints(
        minWidth: buttonSize,
        minHeight: buttonSize,
      ),
      icon: Icon(icon),
      color: _white,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildWhiteSurface(double screenWidth, double horizontalPadding) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(horizontalPadding),
          _buildCertificationBanner(),
          _buildShortcutsGrid(horizontalPadding),
          _buildProductsSection(horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher des produits...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: Provider.of<ProductsProvider>(context, listen: false).searchProducts,
        ),
      ),
    );
  }

  Widget _buildCertificationBanner() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return CertificationBanner(
          sellerVerifiedUntil: authProvider.user?.sellerVerifiedUntil,
          sellerVerified: authProvider.user?.sellerVerified,
          sellerName: authProvider.user?.nom ?? '',
          onRenew: () => authProvider.refreshUserInBackground(),
        );
      },
    );
  }

  Widget _buildShortcutsGrid(double horizontalPadding) {
    final items = [
      _ShortcutData(Icons.grid_view, 'Produits'),
      _ShortcutData(Icons.storefront, 'Boutiques'),
      _ShortcutData(Icons.add_circle, 'Vendre'),
      _ShortcutData(Icons.shopping_bag, 'Commandes'),
      _ShortcutData(Icons.category, 'Catégories'),
      _ShortcutData(Icons.local_offer, 'Promotions'),
      _ShortcutData(Icons.inventory_2, 'Mes produits'),
      _ShortcutData(Icons.person, 'Profil'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _shortcutsCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final bgColor = _pastelColors[index % _pastelColors.length];
          return _ShortcutCard(
            icon: item.icon,
            label: item.label,
            backgroundColor: bgColor,
            onTap: () => _handleShortcutTap(item.label),
          );
        },
      ),
    );
  }

  Widget _buildProductsSection(double horizontalPadding) {
    return Consumer<ProductsProvider>(
      builder: (context, productsProvider, child) {
        final products = productsProvider.filteredProducts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
              child: const Text(
                'Produits récents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            _buildCategoryChips(productsProvider),
            if (productsProvider.isLoading && products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (productsProvider.error != null && products.isEmpty)
              _buildErrorState(productsProvider, horizontalPadding)
            else if (products.isEmpty)
              _buildEmptyState(horizontalPadding)
            else
              _buildProductGrid(products, productsProvider.isLoading, horizontalPadding),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(ProductsProvider productsProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(productsProvider, '', 'Tous'),
            ...categories.map((cat) {
              return _buildCategoryChip(productsProvider, cat, cat);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ProductsProvider productsProvider, String category, String label) {
    final isSelected = _selectedCategory == category;
    final idx = categories.indexOf(category) % _pastelColors.length;
    final bgColor = isSelected
        ? _turquoise
        : _pastelColors['Tous' == label ? 0 : idx].withValues(alpha: 0.7);
    final textColor = isSelected ? _white : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        backgroundColor: bgColor,
        selected: isSelected,
        selectedColor: _turquoise,
        checkmarkColor: _white,
        side: BorderSide(color: isSelected ? _turquoise : Colors.grey.shade300, width: 1),
        onSelected: (_) {
          Provider.of<ProductsProvider>(context, listen: false).searchProducts('');
          _onCategorySelected(category);
          productsProvider.filterByCategory(category);
        },
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildErrorState(ProductsProvider productsProvider, double horizontalPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 32, horizontalPadding, 32),
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
              foregroundColor: _white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double horizontalPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 32, horizontalPadding, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun produit trouvé',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, bool isLoading, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _productsCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (isLoading && index == products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class _ShortcutData {
  final IconData icon;
  final String label;
  const _ShortcutData(this.icon, this.label);
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final iconSize = screenW < 400 ? 28.0 : 32.0;
    final fontSize = screenW < 400 ? 12.0 : 13.0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                width: 56,
                height: 56,
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

class _ProductCard extends StatefulWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  String? _paymentMethod;
  double? _buyerLat;
  double? _buyerLng;
  bool _isGettingGps = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  final List<String> paymentOptions = [
    'Orange Money',
    'MTN Money',
    'Moov Money',
    'Wave',
    'Espèce'
  ];

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isGettingGps = true;
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _buyerLat = position.latitude;
          _buyerLng = position.longitude;
          _isGettingGps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGettingGps = false;
        });
      }
    }
  }

  Future<void> _showQuickBuyDialog(BuildContext context, Product product) async {
    _paymentMethod = null;
    _buyerLat = null;
    _buyerLng = null;
    _phoneController.clear();
    _accountController.clear();

    _getCurrentLocation();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.grey.shade700, size: 24),
              const SizedBox(width: 8),
              Text('Acheter ${widget.product.name}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.product.price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Méthode paiement',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: paymentOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                  onChanged: (value) => setDialogState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro téléphone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    labelText: 'Nom compte',
                    prefixIcon: const Icon(Icons.account_circle),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: _paymentMethod != null && _phoneController.text.isNotEmpty && _accountController.text.isNotEmpty && Provider.of<AuthProvider>(context, listen: false).isAuthenticated
                ? () async {
                    Navigator.pop(context);
                    final data = {
                      'items': [
                        {
                          'id': widget.product.id,
                          'name': widget.product.name,
                          'price': widget.product.price,
                          'quantite': 1,
                        }
                      ],
                      'paymentMethod': _paymentMethod!.toLowerCase().replaceAll(' ', '_'),
                      'phoneNumber': _phoneController.text,
                      'accountName': _accountController.text,
                      if (_buyerLat != null) 'buyerLat': _buyerLat,
                      if (_buyerLng != null) 'buyerLng': _buyerLng,
                    };
                    try {
                      await ApiService.createOrder(data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Commande réussie !'), backgroundColor: Color(0xFF00B8A9)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red.shade300),
                      );
                    }
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B8A9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Acheter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isVerified = _isSellerVerifiedFromProduct(widget.product);

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
                context.push(
                  '/product/${widget.product.id}',
                  extra: widget.product,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: widget.product.image,
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
                          widget.product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B8A9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified, size: 12, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.product.price.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF00B8A9),
                    ),
                  ),
                  Text(
                    '${widget.product.categorie} • ${widget.product.vendeurNom}',
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
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        cartProvider.addItem(widget.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajouté au panier'), backgroundColor: Color(0xFF00B8A9)),
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

  bool _isSellerVerifiedFromProduct(Product product) {
    final vendeur = product.vendeur;
    if (vendeur is Map<String, dynamic>) {
      return vendeur['sellerVerified'] == true || vendeur['seller_verified'] == true;
    }
    return false;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _accountController.dispose();
    super.dispose();
  }
}
