import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:go_router/go_router.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sellerNom),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => launchUrl(Uri.parse('tel:${widget.sellerCompte.replaceAll(' ', '')}')),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Infos vendeur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.store, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.sellerNom,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.sellerLocalisation,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${widget.sellerCompte.replaceAll(' ', '')}')),
                  icon: const Icon(Icons.phone),
                  label: const Text('Contacter'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue),
                ),
              ],
            ),
          ),
          
          // Évaluations (optionnel)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text('4.8/5 (12 avis)', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
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
                    .where((p) => p.vendeurNom == widget.sellerNom)
                    .toList();
                
                if (sellerProducts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucun produit disponible', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sellerProducts.length,
                  itemBuilder: (context, index) {
                    final product = sellerProducts[index];
                    return Card(
                      child: InkWell(
                        onTap: () => context.go('/product/${product.id}', extra: product),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${product.price.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    product.categorie,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
