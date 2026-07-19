import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'package:go_router/go_router.dart';
import '../widgets/back_arrow.dart';



class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUser();
      Provider.of<OrdersProvider>(context, listen: false).fetchMyOrders();
    });
  }

  Future<void> _markReceived(int orderId) async {
    try {
      await ApiService().put('/api/orders/$orderId/received');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colis reçu!'), backgroundColor: Colors.green),
      );
      Provider.of<OrdersProvider>(context, listen: false).fetchMyOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Mes commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, child) {
          if (ordersProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ordersProvider.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune commande', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordersProvider.orders.length,
            itemBuilder: (context, index) {
              final order = ordersProvider.orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    child: Text('\$${order.total.toStringAsFixed(0)}'),
                  ),
title: Text('Commande #${order.id}'),
            trailing: Wrap(
              children: [
          /*
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => context.push('/order-detail', extra: order),
                ),
                */
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.blue),
                  tooltip: 'Chat Vendeur',
                  onPressed: () {
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statut: ${order.statut.toUpperCase()}'),
                      Text('Vendeur: ${order.statutVendeur?.toUpperCase() ?? "N/A"}'),
                      Text(order.date),
                      if (order.nomLivraison?.isNotEmpty == true) ...[
                        Text('Livraison: ${order.nomLivraison}'),
                        Text('Tel: ${order.telLivraison ?? ''}'),
                      ],
                    ],
                  ),
                  children: [
                    ...order.articles.map<Widget>((art) {
                      Map<String, dynamic> productData;
                      if ((art as Map)['product'] != null) {
                        productData = Map<String, dynamic>.from((art as Map)['product']);
                      } else {
                        productData = Map<String, dynamic>.from(art as Map);
                      }
                      final product = Product.fromJson(productData);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.image),
                          onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                        ),
                        title: Text(product.name),
                        subtitle: Text('${art['quantite'] ?? 1}x ${product.price.toStringAsFixed(0)} FCFA'),
                      );
                    }).toList(),
                    if (order.statut == 'livraison_confirmee')
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () => _markReceived(order.id),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check),
                          label: const Text('Colis Reçu'),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


