import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart';
import '../widgets/back_arrow.dart';

class AdminDeliveredOrdersScreen extends StatefulWidget {
  const AdminDeliveredOrdersScreen({super.key});

  @override
  State<AdminDeliveredOrdersScreen> createState() => _AdminDeliveredOrdersScreenState();
}

class _AdminDeliveredOrdersScreenState extends State<AdminDeliveredOrdersScreen> {
  bool _isLoading = true;
  String _searchQuery = '';

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

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_searchQuery.isEmpty) return orders;

    final query = _searchQuery.toLowerCase();
    return orders.where((order) {
      final firstArticle = order.articles.isNotEmpty
          ? order.articles.first as Map<String, dynamic>
          : <String, dynamic>{};

      final productName = (firstArticle['name'] ?? '').toLowerCase();
      final orderId = order.id.toString();
      final clientName = (order.nomCompte ?? '').toLowerCase();
      final phone = (order.telLivraison ?? '').toLowerCase();

      return productName.contains(query) ||
          orderId.contains(query) ||
          clientName.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Colis livrés'),
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
                final allOrders = ordersProvider.orders;
                final deliveredOrders = allOrders.where((o) => o.statut == 'livree').toList();
                final filteredOrders = _getFilteredOrders(deliveredOrders);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un colis...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _loadOrders,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 200),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text('Aucun colis livré', style: TextStyle(fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                                  final firstArticle = order.articles.isNotEmpty
                                      ? order.articles.first as Map<String, dynamic>
                                      : <String, dynamic>{};
                                  final productName = firstArticle['name'] ?? 'N/A';
                                  final productPrice = (firstArticle['price'] ?? 0).toDouble();
                                  final quantity = firstArticle['quantite'] ?? 1;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        child: Text('${order.total.toStringAsFixed(0)}FCFA'),
                                      ),
                                      title: Text('Colis #${order.id}'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Produit: $productName'),
                                          Text('Client: ${order.nomCompte ?? 'N/A'}'),
                                          Text('Téléphone: ${order.telLivraison ?? 'N/A'}'),
                                          Text('Statut: Livrée'),
                                          Text('Date: ${order.date}'),
                                        ],
                                      ),
                                      trailing: Text('${order.total.toStringAsFixed(0)} FCFA'),
                                      children: [
                                        ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(firstArticle['image'] ?? ''),
                                            onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                                          ),
                                          title: Text(productName),
                                          subtitle: Text('$quantity x ${productPrice.toStringAsFixed(0)} FCFA'),
                                        ),
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
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}