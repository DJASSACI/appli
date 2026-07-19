
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
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Mes produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell),
            onPressed: () => context.go('/sell'),
          ),
          IconButton(
            icon: const Icon(Icons.link),
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
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
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
            return const Center(child: CircularProgressIndicator());
          }

          if (myProducts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => productsProvider.fetchProducts(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucun produit publié', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Cliquez le + pour vendre votre premier article'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => productsProvider.fetchProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myProducts.length,
              itemBuilder: (context, index) {
                final product = myProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(product.image),
                      onBackgroundImageError: (_, __) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${product.price.toStringAsFixed(0)} $currencySymbol'),
                        Text('${product.categorie} • ${product.vendeurLocalisation ?? 'N/A'}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                      tooltip: 'Supprimer "${product.name}"',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer article'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
                              Text('Cette action est irréversible.', style: TextStyle(color: Colors.red[600])),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

