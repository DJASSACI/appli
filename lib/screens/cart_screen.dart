import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import '../models/product.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
        title: const Text('Panier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Provider.of<CartProvider>(context, listen: false).clear(),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.itemCount == 0) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Votre panier est vide', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(item.product.image),
                          onBackgroundImageError: (_,__) => const Icon(Icons.image_not_supported),
                          radius: 30,
                        ),
                        title: Text(item.product.name),
                        subtitle: Text('${item.product.categorie} • ${item.product.vendeurLocalisation ?? 'N/A'}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => cartProvider.updateQuantity(item.product.id, item.quantity - 1),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => cartProvider.updateQuantity(item.product.id, item.quantity + 1),
                                ),
                              ],
                            ),
                            Text(
                              '${(item.quantity * item.product.price).toStringAsFixed(0)} $currencySymbol',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(item.product.name),
                            content: Text(item.product.description),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '${cartProvider.totalAmount.toStringAsFixed(0)} $currencySymbol',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartProvider.itemCount > 0
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Commande en cours... Total: ${cartProvider.totalAmount.toStringAsFixed(0)} $currencySymbol')),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Passer la commande', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
