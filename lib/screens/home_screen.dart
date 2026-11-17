import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../services/mawa_service.dart';
import '../services/notification_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/certification_banner.dart';
import '../widgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static bool _welcomeShown = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';

  // Orange Premium palette
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

  static const Map<String,IconData> _categoryIcons = {
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
    'Cuisine': Icons.kitchen,
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

  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();

      if (!HomeScreen._welcomeShown) {
        HomeScreen._welcomeShown = true;
        await LocalNotificationService().showWelcomeNotification();
      }
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
      case 'Services':
        context.go('/services');
        break;
      case 'MAWA':
        context.go('/mawa');
        break;
      case 'Promotions':
        context.go('/promotions');
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
    final titleFontSize = isSmallScreen ? 18.0 : 22.0;
    final iconButtonSize = isSmallScreen ? 40.0 : 48.0;

    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'Djassa CI',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: titleFontSize,
            letterSpacing: -0.3,
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
            icon: Icons.add_circle_outline,
            tooltip: 'Vendre',
            onPressed: () => context.go('/sell'),
            buttonSize: iconButtonSize,
          ),
          const NotificationBell(),
          _buildAppBarActionButton(
            icon: Icons.person_outline,
            tooltip: 'Profil',
            onPressed: () => context.go('/profile'),
            buttonSize: iconButtonSize,
          ),
          if (!isSmallScreen) const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: RefreshIndicator(
        color: _orangePrimary,
        onRefresh: () =>
            Provider.of<ProductsProvider>(context, listen: false).fetchProducts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildWhiteSurface(screenWidth, horizontalPadding),
            ],
          ),
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
              icon: const Icon(Icons.shopping_cart_outlined, color: _textDark),
              tooltip: 'Panier',
              onPressed: () => context.go('/cart'),
            ),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _orangePrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 10,
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
      color: _textDark,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildWhiteSurface(double screenWidth, double horizontalPadding) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _offWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildWelcomeBanner(horizontalPadding),
          _buildSearchBar(horizontalPadding),
          _buildCertificationBanner(),
          _buildShortcutsGrid(horizontalPadding),
          _buildProductsSection(horizontalPadding),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(double horizontalPadding) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final prenom = (user?.prenom ?? '').trim();
        final nom = (user?.nom ?? '').trim();
        final fullName = ('$prenom $nom').trim();
        final displayName = fullName.isNotEmpty ? fullName : 'utilisateur';

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF2C2C2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _orangePrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orangeSecondary.withValues(alpha: 0.35)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.waving_hand_rounded, color: _orangeSecondary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue sur DJASSACI',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Heureux de vous retrouver !',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderSoft, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher des produits...',
            hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.8), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _orangePrimary),
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
      _ShortcutData(Icons.home_repair_service_outlined, 'Services'),
      _ShortcutData(Icons.storefront_outlined, 'Boutiques'),
      _ShortcutData(Icons.add_circle_outline, 'Vendre'),
      _ShortcutData(Icons.shopping_bag_outlined, 'Commandes'),
      _ShortcutData(Icons.grid_view_rounded, 'Catégories'),
      _ShortcutData(Icons.local_offer_outlined, 'Promotions'),
      _ShortcutData(Icons.inventory_2_outlined, 'Mes produits'),
      _ShortcutData(Icons.smart_toy_outlined, 'MAWA'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
      child: ValueListenableBuilder<int>(
        valueListenable: NotificationService.orderUnreadNotifier,
        builder: (context, orderCount, child) {
          return ValueListenableBuilder<int>(
            valueListenable: NotificationService.promoUnreadNotifier,
            builder: (context, promoCount, child) {
              return GridView.builder(
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
                  int badgeCount = 0;
                  if (item.label == 'Commandes') {
                    badgeCount = orderCount;
                  } else if (item.label == 'Promotions') {
                    badgeCount = promoCount;
                  }
                  return _ShortcutCard(
                    icon: item.icon,
                    label: item.label,
                    accentColor: index % 2 == 0 ? _orangePrimary : _orangeSecondary,
                    onTap: () => _handleShortcutTap(item.label),
                    badgeCount: badgeCount,
                  );
                },
              );
            },
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
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
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
                    'Produits récents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            _buildCategoryChips(productsProvider),
            if (productsProvider.isLoading && products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _orangePrimary)),
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
        ? _orangePrimary
        : (label == 'Tous' ? _white : _pastelColors[idx < 0 ? 0 : idx].withValues(alpha: 0.6));
    final textColor = isSelected ? _white : _textDark;
    final icon = label == 'Tous' ? Icons.all_inclusive : _categoryIcons[label];

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
        avatar: icon != null ? Icon(icon, size: 16, color: textColor) : null,
        backgroundColor: bgColor,
        selected: isSelected,
        selectedColor: _orangePrimary,
        checkmarkColor: _white,
        side: BorderSide(color: isSelected ? _orangePrimary : _borderSoft, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

  Widget _buildEmptyState(double horizontalPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
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
            child: Icon(Icons.search_off_rounded, size: 34, color: _orangePrimary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun produit trouvé',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Essayez une autre recherche ou catégorie',
            style: TextStyle(fontSize: 13, color: _textMuted),
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
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: products.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (isLoading && index == products.length) {
            return Center(child: CircularProgressIndicator(color: _orangePrimary));
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
  final Color accentColor;
  final VoidCallback onTap;
  final int badgeCount;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final iconSize = screenW < 400 ? 24.0 : 26.0;
    final fontSize = screenW < 400 ? 11.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: _HomeScreenState._white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomeScreenState._borderSoft),
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
                badgeCount > 0
                    ? Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: accentColor, size: iconSize),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _HomeScreenState._orangePrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: iconSize),
                      ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: _HomeScreenState._textDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
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
                        const SnackBar(content: Text('Commande réussie !'), backgroundColor: _HomeScreenState._orangePrimary),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red.shade300),
                      );
                    }
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _HomeScreenState._orangePrimary,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.push(
            '/product/${widget.product.id}',
            extra: widget.product,
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: _HomeScreenState._white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomeScreenState._borderSoft),
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
                        imageUrl: widget.product.image,
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _HomeScreenState._offWhite,
                          child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: _HomeScreenState._offWhite,
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
                            color: _HomeScreenState._orangePrimary,
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
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _HomeScreenState._textDark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.price.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _HomeScreenState._orangePrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.product.categorie} • ${widget.product.vendeurNom}',
                        style: const TextStyle(
                          color: _HomeScreenState._textMuted,
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
                            backgroundColor: _HomeScreenState._orangePrimary.withValues(alpha: 0.08),
                            foregroundColor: _HomeScreenState._orangePrimary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: _HomeScreenState._orangePrimary.withValues(alpha: 0.15)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            cartProvider.addItem(widget.product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ajouté au panier'), backgroundColor: _HomeScreenState._orangePrimary),
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
