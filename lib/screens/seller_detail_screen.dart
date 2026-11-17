import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:go_router/go_router.dart';
import '../widgets/back_arrow.dart';


class SellerDetailScreen extends StatefulWidget {
  final String sellerNom;
  final String sellerCompte;
  final String sellerLocalisation;

  const SellerDetailScreen({
    super.key, 
    required this.sellerNom,
    required this.sellerCompte,
    required this.sellerLocalisation,
  });

  @override
  State<SellerDetailScreen> createState() => _SellerDetailScreenState();
}

class _SellerDetailScreenState extends State<SellerDetailScreen> {
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  bool _isSellerVerified(Product product) {
    final vendeur = product.vendeur;
    if (vendeur is Map<String, dynamic>) {
      return vendeur['sellerVerified'] == true || vendeur['seller_verified'] == true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 700 ? 3 : 2;

    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: Text(
          widget.sellerNom,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: _orangePrimary),
            onPressed: () => launchUrl(Uri.parse('tel:${widget.sellerCompte.replaceAll(' ', '')}')),
            tooltip: 'Appeler',
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: _textDark),
            onPressed: () => context.pop(),
            tooltip: 'Retour',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Column(
        children: [
          // Infos vendeur
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
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
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _orangePrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orangeSecondary.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 38, color: _orangePrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.sellerNom,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: _textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.sellerLocalisation,
                        style: const TextStyle(fontSize: 14, color: _textMuted),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${widget.sellerCompte.replaceAll(' ', '')}')),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text('Contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orangePrimary,
                      foregroundColor: _white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Évaluations (optionnel)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _orangeSecondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: _orangePrimary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  '4.8/5 (12 avis)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: _textDark),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Avis ${widget.sellerNom}'),
                        content: const Text('Évaluations à venir...\\n\\nFonctionnalité en développement.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: _orangePrimary),
                  child: const Text('Voir tous les avis'),
                ),
              ],
            ),
          ),

          // Tous ses produits
          Expanded(
            child: Consumer<ProductsProvider>(
              builder: (context, productsProvider, child) {
final sellerProducts = productsProvider.products
                    .where((p) {
                      // Support robuste: filtrer sur vendor name (legacy) ou vendor id (si dispo)
                      final vendeur = p.vendeur;
                      final vendeurObj = (vendeur is Map<String, dynamic>) ? vendeur : null;
                      final sellerIdFromProduct = vendeurObj?['id'];
                      final sellerNomMatch = p.vendeurNom == widget.sellerNom;

                      // Si le vendeur a un id côté produit, on compare à l’id stocké dans l’argument.
                      // Sinon on retombe sur le nom.
                      final sellerIdMatch = sellerIdFromProduct != null && sellerIdFromProduct.toString() == widget.key?.toString();

                      return sellerNomMatch || sellerIdMatch;
                    })
                    .toList();
                
                if (productsProvider.isLoading && sellerProducts.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: _orangePrimary));
                }

                if (productsProvider.error != null && sellerProducts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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

                if (sellerProducts.isEmpty) {
                  return Center(
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
                          child: Icon(Icons.inventory_2_outlined, size: 34, color: _orangePrimary.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun produit disponible',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: sellerProducts.length,
                  itemBuilder: (context, index) {
                    final product = sellerProducts[index];
                    final isVerified = _isSellerVerified(product);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(
                          '/product/${product.id}',
                          extra: product,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _borderSoft),
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
                                      child: Image.network(
                                        product.image,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: double.infinity,
                                          color: _offWhite,
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
                                            color: _orangePrimary,
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
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _textDark,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${product.price.toStringAsFixed(0)} FCFA',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _orangePrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        product.categorie,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
