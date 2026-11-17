import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../widgets/back_arrow.dart';

class BoutiquesScreen extends StatefulWidget {
  const BoutiquesScreen({super.key});

  @override
  State<BoutiquesScreen> createState() => _BoutiquesScreenState();
}

class _BoutiquesScreenState extends State<BoutiquesScreen> {
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      if (productsProvider.products.isEmpty && !productsProvider.isLoading) {
        productsProvider.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSellerVerified(Product product) {
    final vendeur = product.vendeur;
    if (vendeur is Map<String, dynamic>) {
      return vendeur['sellerVerified'] == true || vendeur['seller_verified'] == true;
    }
    return false;
  }

  Map<String, Product> _groupBySeller(List<Product> products) {
    final Map<String, Product> boutiques = {};
    for (final product in products) {
      if (!_isSellerVerified(product)) continue;
      final nom = product.vendeurNom;
      if (nom.isEmpty) continue;
      if (!boutiques.containsKey(nom)) {
        boutiques[nom] = product;
      }
    }
    return boutiques;
  }

  Map<String, Product> _filterBoutiques(Map<String, Product> boutiques) {
    if (_searchQuery.isEmpty) return boutiques;
    final query = _searchQuery.toLowerCase();
    final filtered = <String, Product>{};
    for (final entry in boutiques.entries) {
      if (entry.key.toLowerCase().contains(query)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  int? _sellerId(Product product) {
    final vendeur = product.vendeur;
    if (vendeur is Map<String, dynamic>) {
      return (vendeur['id'] as num?)?.toInt();
    }
    return null;
  }

  void _goToSeller(String nom, Product product) {
    final encoded = Uri.encodeComponent(nom);
    final sellerId = _sellerId(product);
    final query = sellerId == null ? '' : '?sellerId=$sellerId';
    context.push('/seller/$encoded$query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: const Text(
          'Boutiques certifiées',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _orangePrimary));
          }

          if (productsProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
              ),
            );
          }

          final boutiques = _groupBySeller(productsProvider.products);
          final filteredBoutiques = _filterBoutiques(boutiques);
          final entries = filteredBoutiques.entries.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 15, color: _textDark),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une boutique',
                      hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.85), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: _orangePrimary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: _textMuted),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              if (entries.isEmpty && _searchQuery.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                          'Aucune boutique trouvée',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Essayez un autre nom de boutique',
                          style: TextStyle(fontSize: 13, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else if (entries.isEmpty && _searchQuery.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _orangePrimary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storefront_outlined, size: 34, color: _orangePrimary.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune boutique certifiée',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final nom = entries[index].key;
                      final product = entries[index].value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _goToSeller(nom, product),
                            child: Ink(
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
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        product.image,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 56,
                                          height: 56,
                                          color: _offWhite,
                                          child: const Icon(Icons.storefront_outlined, color: _textMuted),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: _textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _orangePrimary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.verified_rounded, size: 13, color: _orangePrimary),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Vendeur certifié',
                                                      style: TextStyle(
                                                        color: _orangePrimary,
                                                        fontSize: 12,
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
                                    IconButton(
                                      icon: const Icon(Icons.storefront_rounded, color: _orangePrimary),
                                      onPressed: () => _goToSeller(nom, product),
                                      tooltip: 'Voir la boutique',
                                      style: IconButton.styleFrom(
                                        backgroundColor: _orangePrimary.withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ],
                                ),
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
        },
      ),
    );
  }
}
