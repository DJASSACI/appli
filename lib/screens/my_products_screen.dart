
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/product.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../widgets/back_arrow.dart';



class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);


  Future<void> _deleteProduct(int productId) async {
    try {
      await ApiService.instance.delete('/api/products/$productId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé !'), backgroundColor: Colors.green),
      );
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression: $e'), backgroundColor: Colors.red),
      );
    }
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
          'Mes produits',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell, color: _textDark),
            onPressed: () => context.go('/sell'),
          ),
          IconButton(
            icon: const Icon(Icons.link, color: _textDark),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final link = '${Uri.base.origin}/seller/${authProvider.user!.nom.toLowerCase().replaceAll(' ', '-')}';
              await Clipboard.setData(ClipboardData(text: link));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien boutique copié !'), backgroundColor: Colors.green),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home, color: _textDark),
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Consumer2<ProductsProvider, AuthProvider>(
builder: (context, productsProvider, authProvider, child) {
            final myProducts = productsProvider.products.where((p) {
            final user = authProvider.user;
            if (user == null) return false;

            // Utiliser uniquement l'id vendeur pour éviter les mismatches champs/format.
final sellerId = user.id?.toString();
            // Selon les données backend, le champ `vendeur` côté produit peut contenir soit l'id du vendeur,
            // soit un objet (ex: { id: ..., ...}). On gère les deux cas.
            final pVendeur = p.vendeur;
            if (pVendeur is Map<String, dynamic>) {
              final pid = pVendeur['id']?.toString();
              return pid != null && pid == sellerId;
            }
            return pVendeur.toString() == sellerId;
          }).toList();


          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _orangePrimary));
          }

          if (myProducts.isEmpty) {
            return RefreshIndicator(
              color: _orangePrimary,
              onRefresh: () => productsProvider.fetchProducts(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _orangePrimary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.inventory_2_outlined, size: 38, color: _orangePrimary.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun produit publié',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Cliquez le + pour vendre votre premier article',
                            style: TextStyle(color: _textMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _orangePrimary,
            onRefresh: () => productsProvider.fetchProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: myProducts.length,
              itemBuilder: (context, index) {
                final product = myProducts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.image,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: _offWhite,
                              child: Icon(Icons.image_not_supported_outlined, color: _textMuted.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: _textDark, fontSize: 15),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.price.toStringAsFixed(0)} $currencySymbol',
                                style: const TextStyle(color: _orangePrimary, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${product.categorie} • ${product.vendeurLocalisation ?? 'N/A'}',
                                style: const TextStyle(color: _textMuted, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 26),
                          tooltip: 'Supprimer "${product.name}"',
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: _white,
                              surfaceTintColor: _white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Supprimer article',
                                    style: TextStyle(color: _textDark, fontWeight: FontWeight.w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voulez-vous vraiment supprimer "${product.name}" ?',
                                    style: const TextStyle(color: _textDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Cette action est irréversible.',
                                    style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(foregroundColor: _textMuted),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteProduct(product.id);
                                  },
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

