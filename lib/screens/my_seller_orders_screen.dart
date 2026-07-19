import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/back_arrow.dart';


class MySellerOrdersScreen extends StatefulWidget {
  const MySellerOrdersScreen({super.key});

  @override
  State<MySellerOrdersScreen> createState() => _MySellerOrdersScreenState();
}


class _MySellerOrdersScreenState extends State<MySellerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUser();
      if (authProvider.isAuthenticated) {
        await Provider.of<OrdersProvider>(context, listen: false)
            .fetchSellerOrders(authProvider.user!.id.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Mes commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell),
            onPressed: () => context.go('/sell'),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () => context.go('/my-products'),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.user != null) {
                Provider.of<OrdersProvider>(context, listen: false).fetchSellerOrders(authProvider.user!.id.toString());
              }
            },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
      body: Consumer2<OrdersProvider, AuthProvider>(
        builder: (context, ordersProvider, authProvider, child) {
          if (ordersProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final mySellerOrders = ordersProvider.orders;

          if (mySellerOrders.isEmpty) {
          return RefreshIndicator(
              onRefresh: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.user != null) {
                  return ordersProvider.fetchSellerOrders(authProvider.user!.id.toString());
                }
                return Future.value();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucune commande', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Les commandes apparaîtront ici quand vos acheteurs commandent'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.user != null) {
                  return ordersProvider.fetchSellerOrders(authProvider.user!.id.toString());
                }
                return Future.value();
              },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mySellerOrders.length,
              itemBuilder: (context, index) {
                final order = mySellerOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      child: Text('\$${order.total.toStringAsFixed(0)}'),
                    ),
title: Row(
                      children: [
                        Expanded(child: Text('Commande #${order.id}')),
IconButton(
                          icon: const Icon(Icons.storefront),
                          onPressed: () => context.push('/seller-detail', extra: {
                            'sellerNom': order.articles.first['vendeurNom'] ?? 'Vendeur',
                            'sellerCompte': order.articles.first['vendeurCompte'] ?? '',
                            'sellerLocalisation': order.articles.first['vendeurLocalisation'] ?? '',
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person),
                          onPressed: () {
                            launchUrl(Uri.parse('tel:${order.numeroPaiement ?? ''}'));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.star),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Évaluations ${order.articles.first['vendeurNom'] ?? 'Vendeur'}'),
                              content: const Text('Évaluations à venir...'),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.blue),
                          tooltip: 'Chat Acheteur',
                          onPressed: () => context.push('/chat/${order.utilisateurId}', extra: {'name': order.nomCompte ?? 'Acheteur'}),
                        ),

                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text('Acheteur ID: ${order.utilisateurId}'),
                        Text('Nom: ${order.nomCompte ?? 'N/A'}'),
                        Text('Tel paiement: ${order.numeroPaiement ?? 'N/A'}'),
                        if (order.nomLivraison != null && order.nomLivraison!.isNotEmpty) ...[
                          Text('Livraison: ${order.nomLivraison}'),
                          Text('Tel livraison: ${order.telLivraison ?? ''}'),
                          Text('Ville/Commune: ${order.villeCommune ?? ''}'),
                          Text('Quartier: ${order.quartier ?? ''}'),
                        ],
                        Text('Statut: ${order.statut.toUpperCase()}'),
                        Text(order.date),

                      ],
                    ),
                    trailing: Text('${order.total.toStringAsFixed(0)} $currencySymbol'),
                    children: [
                      ...order.articles.map<Widget>((art) {
                        final item = art as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(item['image'] ?? ''),
                            onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                          ),
                          title: Text(item['name'] ?? 'N/A'),
                          subtitle: Text('${item['quantite'] ?? 1} x ${(item['price'] ?? 0).toStringAsFixed(0)} $currencySymbol'),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
  if (order.statut.toLowerCase() == "en_attente")

    const Expanded(
      child: Center(
        child: Text(
          "Paiement en cours...",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),

  if (order.statut.toLowerCase() == "payée")

    ElevatedButton.icon(
      onPressed: () async {
        try {
          await Provider.of<OrdersProvider>(context, listen: false)
              .markDelivered(order.id);

          String yangoUrl = 'yango://';
          if (order.buyerLat != null && order.buyerLng != null) {
            yangoUrl +=
                '?destination_lat=${order.buyerLat}&destination_lng=${order.buyerLng}';
          } else if (order.villeCommune?.isNotEmpty == true &&
              order.quartier?.isNotEmpty == true) {
            yangoUrl +=
                '?destination=${Uri.encodeComponent('${order.nomLivraison}, ${order.quartier}, ${order.villeCommune}')}';
          }

          await launchUrl(Uri.parse(yangoUrl));

          if (!context.mounted) return;
          await Provider.of<OrdersProvider>(context, listen: false)
              .fetchSellerOrders(authProvider.user!.id.toString());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison marquée'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      icon: const Icon(Icons.local_shipping),
      label: const Text("Livrer"),
    ),

  if (order.statut.toLowerCase() == "livree")

    ElevatedButton.icon(
      onPressed: () async {
        try {
          await Provider.of<OrdersProvider>(context, listen: false)
              .confirmDelivery(order.id);

          if (!context.mounted) return;
          await Provider.of<OrdersProvider>(context, listen: false)
              .fetchSellerOrders(authProvider.user!.id.toString());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison confirmée'),
              backgroundColor: Colors.blue,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      label: const Text("Confirmer livraison",
          style: TextStyle(color: Colors.white)),
    ),
],
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


