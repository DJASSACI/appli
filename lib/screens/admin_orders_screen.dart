import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart';
import '../widgets/back_arrow.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
      await ordersProvider.fetchOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deliverOrder(int orderId) async {
    try {
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
      await ordersProvider.updateOrderStatus(orderId, 'livree');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande marquée comme livrée'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
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
        title: const Text('Toutes les commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                if (ordersProvider.orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Aucune commande', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ordersProvider.orders.length,
                    itemBuilder: (context, index) {
                      final order = ordersProvider.orders[index];
                      final firstArticle = order.articles.isNotEmpty
                          ? order.articles.first as Map<String, dynamic>
                          : <String, dynamic>{};
                      final isPayee = order.statut == 'payée';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            child: Text('${order.total.toStringAsFixed(0)}FCFA'),
                          ),
                          title: Text('Commande #${order.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Acheteur: ${order.utilisateurId} - ${order.nomCompte ?? 'N/A'}'),
                              Text('Vendeur: ${order.seller ?? 'N/A'} - ${firstArticle['vendeurNom'] ?? 'N/A'} (${firstArticle['vendeurCompte'] ?? ''})'),
                              Text('Statut: ${order.statut.toUpperCase()} | Vendeur: ${order.statutVendeur?.toUpperCase() ?? 'N/A'}'),
                              Text('Paiement: ${order.methodePaiement ?? ''} - ${order.numeroPaiement ?? ''}'),
                              Text('Date: ${order.date}'),
                            ],
                          ),
                          trailing: isPayee
                              ? ElevatedButton.icon(
                                  onPressed: () => _deliverOrder(order.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.local_shipping, size: 18),
                                  label: const Text('Livrer', style: TextStyle(fontSize: 12)),
                                )
                              : order.statut == 'livree'
                                  ? const Text('Livrée', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                  : Text(order.statut.toUpperCase()),
                          children: [
                            ...order.articles.map<Widget>((art) {
                              final item = art as Map<String, dynamic>;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(item['image'] ?? ''),
                                  onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                                ),
                                title: Text(item['name'] ?? 'N/A'),
                                subtitle: Text('${item['quantite'] ?? 1} x ${(item['price'] ?? 0).toStringAsFixed(0)} FCFA'),
                              );
                            }).toList(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Livraison: ${order.nomLivraison ?? 'N/A'}, ${order.telLivraison ?? ''}, ${order.villeCommune ?? ''}, ${order.quartier ?? ''}',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
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