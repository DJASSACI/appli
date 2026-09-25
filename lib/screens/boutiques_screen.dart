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

  void _goToSeller(String nom) {
    final encoded = Uri.encodeComponent(nom);
    context.push('/seller/$encoded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text(
          'Boutiques certifiées',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${productsProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: productsProvider.fetchProducts,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final boutiques = _groupBySeller(productsProvider.products);
          final filteredBoutiques = _filterBoutiques(boutiques);
          final entries = filteredBoutiques.entries.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une boutique',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      children: const [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune boutique trouvée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
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
                      children: const [
                        Icon(Icons.store_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune boutique certifiée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final nom = entries[index].key;
                      final product = entries[index].value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(product.image),
                            onBackgroundImageError: (_, _) => const Icon(Icons.store),
                            backgroundColor: Colors.grey[200],
                          ),
                          title: Text(
                            nom,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text(
                            'Vendeur certifié',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.storefront, color: Colors.blue),
                            onPressed: () => _goToSeller(nom),
                            tooltip: 'Voir la boutique',
                          ),
                          onTap: () => _goToSeller(nom),
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
