import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:go_router/go_router.dart';
import '../widgets/back_arrow.dart';


class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: Text('Commande #${order.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ce que tu as acheté - Produits
            Text('Produits achetés:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...order.articles.map((art) {
              Map<String, dynamic> productData;
              if ((art as Map)['product'] != null) {
                productData = Map<String, dynamic>.from((art as Map)['product']);
              } else {
                productData = Map<String, dynamic>.from(art as Map);
              }
              final product = Product.fromJson(productData);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(product.image),
                    onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                  ),
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${art['quantite'] ?? 1}x ${product.price.toStringAsFixed(0)} FCFA'),
                      Text('Sous-total: ${(art['quantite'] ?? 1 * product.price).toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                  trailing: Text('${(art['quantite'] ?? 1 * product.price).toStringAsFixed(0)} FCFA'),
                ),
              );
            }).toList(),
            const Divider(),
            
            // Total
            ListTile(
              title: const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Text('${order.total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ),
            const Divider(),
            
            // Statut de la commande
            Text('Statut commande:', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                title: Text('Commande: ${order.statut.toUpperCase()}'),
                subtitle: Text('Vendeur: ${order.statutVendeur?.toUpperCase() ?? "N/A"}'),
              ),
            ),
            const Divider(),
            
            // Paiement
            Text('Paiement:', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                title: Text(order.methodePaiement ?? 'N/A'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.numeroPaiement != null) Text('Numéro: ${order.numeroPaiement}'),
                    if (order.nomCompte != null) Text('Compte: ${order.nomCompte}'),
                  ],
                ),
              ),
            ),
            const Divider(),
            
            // Livraison
            Text('Livraison:', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                title: Text(order.nomLivraison ?? 'Retrait en magasin'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.telLivraison != null) Text('Tel: ${order.telLivraison}'),
                    if (order.villeCommune != null) Text('Ville: ${order.villeCommune}'),
                    if (order.quartier != null) Text('Quartier: ${order.quartier}'),
                  ],
                ),
              ),
            ),
            const Divider(),
            
            // Vendeur
            Text('Vendeur:', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.store)),
                    title: Text('Boutique principale'),
                    subtitle: Text('Seller ID: ${order.seller}'),
                  ),
                  if (order.articles.isNotEmpty) ...order.articles.map((art) {
                    Map<String, dynamic> productData = Map<String, dynamic>.from(art as Map);
                    final product = Product.fromJson(productData);
                    return ListTile(
                      dense: true,
                      title: Text(product.vendeurNom ?? 'Vendeur'),
                      subtitle: Text(product.vendeurCompte ?? ''),
                      trailing: Text(product.vendeurLocalisation ?? ''),
                    );
                  }).toList(),
                  ListTile(
                    dense: true,
                    title: const Text('Contacter Vendeur'),
                    leading: const Icon(Icons.chat, color: Colors.blue),
                    onTap: () {
                      final firstArt = order.articles.isNotEmpty ? order.articles.first as Map : {};
                      final productData = Map<String, dynamic>.from(firstArt);
                      final product = Product.fromJson(productData);
                      final sellerId = int.tryParse(order.seller ?? '0') ?? 0;
                      final sellerName = product.vendeurNom ?? 'Vendeur';
                      context.push('/chat/$sellerId', extra: {'name': sellerName});
                    },
                  ),

                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

