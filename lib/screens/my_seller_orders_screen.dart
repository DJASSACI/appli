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
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

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
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: const Text(
          'Mes commandes',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell, color: _textDark),
            onPressed: () => context.go('/sell'),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2, color: _textDark),
            onPressed: () => context.go('/my-products'),
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
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.user != null) {
                Provider.of<OrdersProvider>(context, listen: false).fetchSellerOrders(authProvider.user!.id.toString());
              }
            },
        backgroundColor: _orangePrimary,
        foregroundColor: _white,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
      body: Consumer2<OrdersProvider, AuthProvider>(
        builder: (context, ordersProvider, authProvider, child) {
          if (ordersProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _orangePrimary));
          }

          final mySellerOrders = ordersProvider.orders;

          if (mySellerOrders.isEmpty) {
          return RefreshIndicator(
              color: _orangePrimary,
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
                          child: Icon(Icons.receipt_long_outlined, size: 38, color: _orangePrimary.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune commande',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Les commandes apparaîtront ici quand vos acheteurs commandent',
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
            onRefresh: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.user != null) {
                  return ordersProvider.fetchSellerOrders(authProvider.user!.id.toString());
                }
                return Future.value();
              },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: mySellerOrders.length,
              itemBuilder: (context, index) {
                final order = mySellerOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _orangePrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '\$${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(color: _orangePrimary, fontWeight: FontWeight.w700, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Commande #${order.id}',
                            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
IconButton(
                          icon: const Icon(Icons.storefront, color: _orangePrimary),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => context.push('/seller-detail', extra: {
                            'sellerNom': order.articles.first['vendeurNom'] ?? 'Vendeur',
                            'sellerCompte': order.articles.first['vendeurCompte'] ?? '',
                            'sellerLocalisation': order.articles.first['vendeurLocalisation'] ?? '',
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person, color: _textDark),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            launchUrl(Uri.parse('tel:${order.numeroPaiement ?? ''}'));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.star, color: _orangeSecondary),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: _white,
                              surfaceTintColor: _white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: Text(
                                'Évaluations ${order.articles.first['vendeurNom'] ?? 'Vendeur'}',
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
                              ),
                              content: const Text(
                                'Évaluations à venir...',
                                style: TextStyle(color: _textMuted),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: _orangePrimary), child: const Text('OK'))],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: _orangePrimary),
                          tooltip: 'Chat Acheteur',
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => context.push('/chat/${order.utilisateurId}', extra: {'name': order.nomCompte ?? 'Acheteur'}),
                        ),

                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text('Acheteur ID: ${order.utilisateurId}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                          Text('Nom: ${order.nomCompte ?? 'N/A'}', style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('Tel paiement: ${order.numeroPaiement ?? 'N/A'}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                          if (order.nomLivraison != null && order.nomLivraison!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _offWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderSoft),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Livraison: ${order.nomLivraison}', style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text('Tel livraison: ${order.telLivraison ?? ''}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                                  Text('Ville/Commune: ${order.villeCommune ?? ''}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                                  Text('Quartier: ${order.quartier ?? ''}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _orangePrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _orangePrimary.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'Statut: ${order.statut.toUpperCase()}',
                              style: const TextStyle(color: _orangePrimary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(order.date, style: const TextStyle(color: _textMuted, fontSize: 12)),

                        ],
                      ),
                    ),
                    trailing: Text(
                      '${order.total.toStringAsFixed(0)} $currencySymbol',
                      style: const TextStyle(color: _orangePrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    children: [
                      const Divider(height: 20, color: _borderSoft),
                      ...order.articles.map<Widget>((art) {
                        final item = art as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _offWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['image'] ?? '',
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 52,
                                    height: 52,
                                    color: _white,
                                    child: Icon(Icons.image_not_supported_outlined, color: _textMuted.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'N/A',
                                      style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['quantite'] ?? 1} x ${(item['price'] ?? 0).toStringAsFixed(0)} $currencySymbol',
                                      style: const TextStyle(color: _textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
  if (order.statut.toLowerCase() == "en_attente")

    Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _orangeSecondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _orangeSecondary.withValues(alpha: 0.4)),
          ),
          child: const Text(
            "Paiement en cours...",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark),
          ),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: _orangePrimary,
        foregroundColor: _white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.local_shipping),
      label: const Text("Livrer", style: TextStyle(fontWeight: FontWeight.w600)),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      label: const Text("Confirmer livraison",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    ),
],
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


