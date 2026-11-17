import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
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
      Provider.of<OrdersProvider>(context, listen: false).fetchMyOrders();
      // Marquer les notifications de commandes comme lues à l'ouverture de la page
      await NotificationService().markAllOrderRead();
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

    InputDecoration _fieldDecoration(String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textMuted),
          prefixIcon: Icon(icon, color: _orangePrimary),
          filled: true,
          fillColor: _offWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _borderSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _orangePrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _white,
        surfaceTintColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Coordonner la livraison',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: _fieldDecoration('Nom de livraison *', Icons.person),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telController,
                  decoration: _fieldDecoration('Numéro de téléphone *', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: villeController,
                  decoration: _fieldDecoration('Ville / Commune *', Icons.location_city),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quartierController,
                  decoration: _fieldDecoration('Quartier *', Icons.location_on),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: _textMuted),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: _orangePrimary,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProblem(Order order) async {
    // Informations réelles de la commande sélectionnée (aucune valeur inventée).
    final productNames = <String>[];
    final vendeurNames = <String>{};
    for (final art in order.articles) {
      final map = art is Map ? Map<String, dynamic>.from(art) : <String, dynamic>{};
      Map<String, dynamic> productData;
      if (map['product'] is Map) {
        productData = Map<String, dynamic>.from(map['product'] as Map);
      } else {
        productData = Map<String, dynamic>.from(map);
      }
      final product = Product.fromJson(productData);
      if (product.name.trim().isNotEmpty) {
        productNames.add(product.name.trim());
      }
      final vendeurNom = (product.vendeurNom ?? '').trim();
      if (vendeurNom.isNotEmpty) {
        vendeurNames.add(vendeurNom);
      }
    }
    final produit = productNames.isEmpty ? 'Non disponible' : productNames.join(', ');
    final vendeur = vendeurNames.isEmpty ? 'Non disponible' : vendeurNames.join(', ');
    final montant = '${order.total.toStringAsFixed(0)} FCFA';
    final statut = order.statut.trim().isEmpty ? 'Non disponible' : order.statut;

    final message = 'Bonjour, je souhaite signaler un problème concernant une commande effectuée sur DJASSACI.\n\n'
        '- Numéro de commande : ${order.id}\n'
        '- Produit : $produit\n'
        '- Vendeur : $vendeur\n'
        '- Montant : $montant\n'
        '- Statut : $statut\n\n'
        'Description du problème :\n'
        'Je souhaite obtenir de l\'assistance concernant cette commande.\n\n'
        'Merci de m\'aider à résoudre ce problème.';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse(
      'https://wa.me/2250715926401?text=$encodedMessage',
    );

    try {
      // Tente WhatsApp (app) ; fallback navigateur/WhatsApp Web si indisponible.
      final openedExternal = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) return;

      final openedFallback = await launchUrl(
        whatsappUri,
        mode: LaunchMode.platformDefault,
      );
      if (openedFallback) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir WhatsApp. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
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
            icon: const Icon(Icons.home_rounded, color: _textDark),
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, child) {
          if (ordersProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _orangePrimary));
          }

          if (ordersProvider.orders.isEmpty) {
            return Center(
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
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: ordersProvider.orders.length,
            itemBuilder: (context, index) {
              final order = ordersProvider.orders[index];
              final hasDeliveryInfo = _hasDeliveryInfo(order);
              final isPayee = order.statut == 'payée';
              final showCoordinateButton = isPayee && !hasDeliveryInfo;

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
                    title: Text(
                      'Commande #${order.id}',
                      style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat, color: _orangePrimary),
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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _StatusBadge(label: 'Statut: ${order.statut.toUpperCase()}', color: _orangePrimary),
                              _StatusBadge(label: 'Vendeur: ${order.statutVendeur?.toUpperCase() ?? "N/A"}', color: _textMuted),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(order.date, style: const TextStyle(color: _textMuted, fontSize: 12)),
                          if (hasDeliveryInfo) ...[
                            const SizedBox(height: 8),
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
                                  Text('Tel: ${order.telLivraison ?? ''}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                                  Text('Ville: ${order.villeCommune ?? ''}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                                  Text('Quartier: ${order.quartier ?? ''}', style: const TextStyle(color: _textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    children: [
                    const Divider(height: 20, color: _borderSoft),
                    ...order.articles.map<Widget>((art) {
                      Map<String, dynamic> productData;
                      if ((art as Map)['product'] != null) {
                        productData = Map<String, dynamic>.from((art as Map)['product']);
                      } else {
                        productData = Map<String, dynamic>.from(art as Map);
                      }
                      final product = Product.fromJson(productData);
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
                                product.image,
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
                                    product.name,
                                    style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${art['quantite'] ?? 1}x ${product.price.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(color: _orangePrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (showCoordinateButton)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeliveryForm(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orangePrimary,
                            foregroundColor: _white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.local_shipping_rounded),
                          label: const Text('Coordonner la livraison', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (order.statut == 'livraison_confirmee')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          onPressed: () => _markReceived(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Colis Reçu', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _reportProblem(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orangeSecondary,
                          foregroundColor: _textDark,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.report_problem_rounded),
                        label: const Text('Signaler un probl�me', style: TextStyle(fontWeight: FontWeight.w600)),
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
