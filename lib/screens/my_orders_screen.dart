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
import 'package:url_launcher/url_launcher.dart';

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

  bool _hasDeliveryInfo(Order order) {
    return (order.nomLivraison?.isNotEmpty == true) &&
           (order.telLivraison?.isNotEmpty == true) &&
           (order.villeCommune?.isNotEmpty == true) &&
           (order.quartier?.isNotEmpty == true);
  }

  Future<void> _showDeliveryForm(Order order) async {
    final nomController = TextEditingController(text: order.nomLivraison ?? '');
    final telController = TextEditingController(text: order.telLivraison ?? '');
    final villeController = TextEditingController(text: order.villeCommune ?? '');
    final quartierController = TextEditingController(text: order.quartier ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Coordonner la livraison'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de livraison *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone *',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: villeController,
                  decoration: const InputDecoration(
                    labelText: 'Ville / Commune *',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quartierController,
                  decoration: const InputDecoration(
                    labelText: 'Quartier *',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);

              try {
                final data = {
                  'nomLivraison': nomController.text.trim(),
                  'telLivraison': telController.text.trim(),
                  'villeCommune': villeController.text.trim(),
                  'quartier': quartierController.text.trim(),
                };
                await Provider.of<OrdersProvider>(context, listen: false).updateDeliveryInfo(order.id, data);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informations de livraison enregistrées'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProblem(Order order) async {
    final firstArt = order.articles.isNotEmpty ? order.articles.first as Map : {};
    Map<String, dynamic> productData;
    if (firstArt['product'] != null) {
      productData = Map<String, dynamic>.from(firstArt['product']);
    } else {
      productData = Map<String, dynamic>.from(firstArt);
    }
    final product = Product.fromJson(productData);

    final message = 'Bonjour, je souhaite signaler un problème sur le colis.\n\n'
        'Nom du colis : ${product.name}\n'
        'Prix : ${product.price.toStringAsFixed(0)} FCFA\n'
        'Description : ${product.description}\n\n'
        'Merci de m\'aider à résoudre ce problème.';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/+2250715926401?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp non disponible'), backgroundColor: Colors.red),
        );
      }
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
              final hasDeliveryInfo = _hasDeliveryInfo(order);
              final isPayee = order.statut == 'payée';
              final showCoordinateButton = isPayee && !hasDeliveryInfo;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    child: Text('\$${order.total.toStringAsFixed(0)}'),
                  ),
                  title: Text('Commande #${order.id}'),
                  trailing: Wrap(
                    children: [
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
                      if (hasDeliveryInfo) ...[
                        Text('Livraison: ${order.nomLivraison}'),
                        Text('Tel: ${order.telLivraison ?? ''}'),
                        Text('Ville: ${order.villeCommune ?? ''}'),
                        Text('Quartier: ${order.quartier ?? ''}'),
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
                    if (showCoordinateButton)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeliveryForm(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          icon: const Icon(Icons.local_shipping),
                          label: const Text('Coordonner la livraison'),
                        ),
                      ),
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => _reportProblem(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Signaler un problème'),
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

