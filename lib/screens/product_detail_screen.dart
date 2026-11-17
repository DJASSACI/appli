import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';

import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import 'payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  String? _paymentMethod;
  double? _buyerLat;
  double? _buyerLng;
  bool _isGettingGps = false;
  int _currentImageIndex = 0;
  late PageController _pageController;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nomLivraisonController = TextEditingController();
  final TextEditingController _telLivraisonController = TextEditingController();
  final TextEditingController _villeCommuneController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();

  final List<String> paymentOptions = [
    'Orange Money',
    'MTN Money',
    'Moov Money',
    'Wave',
    'Espèce',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _getProductImages(Product product) {
    if (product.images.isNotEmpty) {
      return product.images;
    }
    return product.image.isNotEmpty ? [product.image] : [];
  }

  Widget _buildImageGallery(Product product) {
    final images = _getProductImages(product);
    final bool hasMultipleImages = images.length > 1;

    return Column(
      children: [
        // Image principale avec PageView pour swipe
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return InkWell(
                        onTap: () => _showFullScreenImage(images, index),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: _offWhite,
                            child: Icon(Icons.image_not_supported_outlined, size: 48, color: _textMuted.withValues(alpha: 0.7)),
                          ),
                        ),
                      );
                    },
                  ),
                  // Indicateur 1 / N
                  if (hasMultipleImages)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _textDark.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Miniatures
        if (hasMultipleImages)
          Container(
            height: 76,
            margin: const EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 68,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? _orangePrimary : _borderSoft,
                        width: isSelected ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _orangePrimary.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: 68,
                        height: 68,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _offWhite,
                          child: Icon(Icons.image_not_supported_outlined, size: 20, color: _textMuted.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showFullScreenImage(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: Colors.white70, size: 50),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 24,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isGettingGps = true);

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
    } catch (_) {
      if (mounted) {
        setState(() => _isGettingGps = false);
      }
    }
  }

  Future<void> _buyDirect(Product product) async {
    if (_paymentMethod == null ||
        _phoneController.text.isEmpty ||
        _accountController.text.isEmpty ||
        _nomLivraisonController.text.isEmpty ||
        _telLivraisonController.text.isEmpty ||
        _villeCommuneController.text.isEmpty ||
        _quartierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final data = {
        'items': [
          {
            'id': product.id,
            'name': product.name,
            'price': product.price,
            'quantite': 1,
          }
        ],
        'paymentMethod': _paymentMethod!.toLowerCase().replaceAll(' ', '_'),
        'phoneNumber': _phoneController.text,
        'accountName': _accountController.text,
        'nomLivraison': _nomLivraisonController.text,
        'telLivraison': _telLivraisonController.text,
        'villeCommune': _villeCommuneController.text,
        'quartier': _quartierController.text,
        if (_buyerLat != null) 'buyerLat': _buyerLat,
        if (_buyerLng != null) 'buyerLng': _buyerLng,
        'notify_url': "https://djassa-backend-imxo.onrender.com/notify",
        'transactionId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      await ApiService.createOrder(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande réussie !'),
          backgroundColor: Colors.green,
        ),
      );

      _paymentMethod = null;
      _phoneController.clear();
      _accountController.clear();
      _nomLivraisonController.clear();
      _telLivraisonController.clear();
      _villeCommuneController.clear();
      _quartierController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPaymentDialog(Product product) async {
    _paymentMethod = null;
    _buyerLat = null;
    _buyerLng = null;
    _phoneController.clear();
    _accountController.clear();
    _nomLivraisonController.clear();
    _telLivraisonController.clear();
    _villeCommuneController.clear();
    _quartierController.clear();

    _getCurrentLocation();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _white,
          surfaceTintColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Acheter ${product.name}',
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.price.toStringAsFixed(0)} $currencySymbol',
                  style: const TextStyle(
                    color: _orangePrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Méthode de paiement',
                    labelStyle: const TextStyle(color: _textMuted),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                  items: paymentOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro téléphone',
                    labelStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.phone, color: _orangePrimary),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    labelText: 'Nom du compte',
                    labelStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.account_circle, color: _orangePrimary),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomLivraisonController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet livraison',
                    labelStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.person, color: _orangePrimary),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _villeCommuneController,
                  decoration: InputDecoration(
                    labelText: 'Ville/Commune',
                    labelStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.location_city, color: _orangePrimary),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telLivraisonController,
                  decoration: InputDecoration(
                    labelText: 'Tel livraison',
                    labelStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.phone, color: _orangePrimary),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quartierController,
                  decoration: InputDecoration(
                    labelText: 'Quartier / Adresse',
                    labelStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.location_on, color: _orangePrimary),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orangePrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _textMuted),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Commande désactivée (mode test).'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orangePrimary,
                foregroundColor: _white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Acheter maintenant'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    final state = GoRouterState.of(context);
    final productFromExtra = state.extra as Product?;
    final productId = state.pathParameters['id'];

    // IMPORTANT:
    // On ignore state.extra (qui peut contenir un ancien Product avec un vendeur non
    // encore certifié). On recalcule toujours depuis ProductsProvider.
    final product = (productId != null)
        ? context
            .read<ProductsProvider>()
            .products
            .firstWhere((p) => p.id.toString() == productId)
        : null;


    if (product == null) {
      return Scaffold(
        backgroundColor: _offWhite,
        appBar: AppBar(
          backgroundColor: _white,
          foregroundColor: _textDark,
          elevation: 0,
          surfaceTintColor: _white,
          title: const Text('Produit', style: TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _borderSoft),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _orangePrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inventory_2_outlined, size: 34, color: _orangePrimary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              const Text('Produit non trouvé', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final sellerVerified = (product.vendeur is Map<String, dynamic>)
        ? (product.vendeur['sellerVerified'] == true ||
            product.vendeur['seller_verified'] == true)
        : false;

    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        title: Text(
          product.name,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: _textDark),
            onPressed: () => context.go('/home'),
            tooltip: 'Accueil',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galerie d'images
            _buildImageGallery(product),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte principale produit
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${product.price.toStringAsFixed(0)} $currencySymbol',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _orangePrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _offWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderSoft),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category_outlined, size: 14, color: _textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    product.categorie,
                                    style: const TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            if (product.vendeur != null && sellerVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _orangePrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: _orangePrimary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Vendeur certifié',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _orangePrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borderSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                            const Text(
                              'Description',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: const TextStyle(fontSize: 15, height: 1.55, color: _textMuted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Carte vendeur / contact
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _orangePrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront_rounded, color: _orangePrimary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          product.vendeurNom,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (sellerVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified_rounded, size: 16, color: _orangePrimary),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.vendeurLocalisation,
                                    style: const TextStyle(fontSize: 13, color: _textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Contacter le vendeur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: product.vendeurCompte.isNotEmpty
                                    ? () => launchUrl(
                                          Uri.parse('tel://${product.vendeurCompte}'),
                                          mode: LaunchMode.externalApplication,
                                        )
                                    : null,
                                icon: const Icon(Icons.phone_rounded, size: 18),
                                label: const Text('Appel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: product.vendeurCompte.isNotEmpty
                                    ? () {
final message =
                                            'Bonjour ! Je viens de voir votre annonce pour ${product.name} au prix de ${product.price.toStringAsFixed(0)} FCFA sur l\'application DJASSA-CI . Est-il toujours disponible ? Voici la description de l\'article : ${product.description}';
                                        launchUrl(
                                          Uri.parse(
                                            'whatsapp://send?phone=${product.vendeurCompte}&text=${Uri.encodeComponent(message)}',
                                          ),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.chat_rounded, size: 18),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
// Afficher la boutique pour tout le monde (supprime la restriction sellerVerified)
if (product.vendeur != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.storefront_rounded, size: 18),
                              label: Text('Voir boutique ${product.vendeurNom}'),
                              onPressed: () {
                                final vendeur = product.vendeur;
                                final sellerId = vendeur is Map<String, dynamic>
                                    ? (vendeur['id'] as num?)?.toInt()
                                    : null;
                                final encoded = Uri.encodeComponent(product.vendeurNom);
                                final query = sellerId == null ? '' : '?sellerId=$sellerId';
                                context.push('/seller/$encoded$query');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _orangePrimary,
                                side: BorderSide(color: _orangePrimary.withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Actions en bas: Ajouter au panier puis Voir panier juste après
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Provider.of<CartProvider>(context, listen: false)
                            .addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ajouté au panier !'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_rounded, size: 20),
                      label: const Text('Ajouter au panier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orangePrimary,
                        foregroundColor: _white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      label: const Text('Voir panier'),
                      onPressed: () => context.go('/cart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textDark,
                        side: const BorderSide(color: _borderSoft),
                        backgroundColor: _white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

