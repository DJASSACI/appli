import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/product.dart';
import 'package:go_router/go_router.dart';
import 'payment_screen.dart';

import '../widgets/back_arrow.dart';



class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  String? _paymentMethod;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nomLivraisonController = TextEditingController();
  final TextEditingController _telLivraisonController = TextEditingController();
  final TextEditingController _villeCommuneController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _buyerLatController = TextEditingController();
  final TextEditingController _buyerLngController = TextEditingController();
  bool _isGettingLocation = false;

  final List<String> paymentOptions = [
    'Orange Money',
    'MTN Money',
    'Moov Money',
    'Wave',
    'Espèce'
  ];

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _buyerLatController.text = position.latitude.toString();
      _buyerLngController.text = position.longitude.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS obtenu: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur GPS: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _placeOrder(CartProvider cartProvider, BuildContext context) async {
    if (_paymentMethod == null || _phoneController.text.isEmpty || _accountController.text.isEmpty ||
        _nomLivraisonController.text.isEmpty || _telLivraisonController.text.isEmpty ||
        _villeCommuneController.text.isEmpty || _quartierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour passer commande'), backgroundColor: Colors.orange),
      );
      return;
    }



    try {
      final items = cartProvider.items.map((item) => ({
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'vendeur': item.product.vendeur,
        'image': item.product.image,
        'quantite': item.quantity,
      })).toList();

      final String paymentMethodKey = _paymentMethod!.toLowerCase().replaceAll(' ', '_');

      final data = {
        'items': items,
        'paymentMethod': paymentMethodKey,
        'phoneNumber': _phoneController.text,
        'accountName': _accountController.text,
        'nomLivraison': _nomLivraisonController.text,
        'telLivraison': _telLivraisonController.text,
        'villeCommune': _villeCommuneController.text,
        'quartier': _quartierController.text,
        'buyerLat': _buyerLatController.text.isNotEmpty ? double.tryParse(_buyerLatController.text) : null,
        'buyerLng': _buyerLngController.text.isNotEmpty ? double.tryParse(_buyerLngController.text) : null,
        'notify_url': "https://djassa-backend-imxo.onrender.com/notify",
        'transactionId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final res = await ApiService.createOrder(data);

      // Extraire orderId pour passer au paiement GeniusPay
      String? createdOrderId;
      final responseData = res.data;
      if (responseData is Map<String, dynamic>) {
        final order = responseData['order'];
        if (order is Map<String, dynamic>) {
          createdOrderId = order['id']?.toString();
        }
        createdOrderId ??= responseData['orderId']?.toString();
        createdOrderId ??= responseData['id']?.toString();
      }

      // Navigation additionnelle vers PaymentScreen (sans supprimer la redirection profile existante)
      if (createdOrderId != null && createdOrderId.isNotEmpty && mounted) {
        final amount = cartProvider.totalAmount.toInt();
        final phone = _phoneController.text;
        final name = _accountController.text;

        // Ouvrir directement l'écran de paiement, et éviter qu'il disparaisse
        // à cause de la redirection /profile.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              amount: amount,
              phone: phone,
              orderId: createdOrderId!,
              name: name,
            ),
          ),
        );

        return;
      }

      cartProvider.clear();
      _phoneController.clear();
      _accountController.clear();
      _nomLivraisonController.clear();
      _telLivraisonController.clear();
      _villeCommuneController.clear();
      _quartierController.clear();
      _paymentMethod = null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande passée avec succès! Total: ${cartProvider.totalAmount.toStringAsFixed(0)} $currencySymbol'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir profil',
            onPressed: () => GoRouter.of(context).go('/profile'),
          ),
        ),
      );

      if (!mounted) return;
      GoRouter.of(context).go('/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la commande: $e'), backgroundColor: Colors.red),
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
          'Panier',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: _orangePrimary),
            tooltip: 'Vider le panier',
            onPressed: () async {
              final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);

              await showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: _white,
                  surfaceTintColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Text(
                    'Vider le panier ?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suppression de tous les articles',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          text: 'Voulez-vous vraiment supprimer tous les articles de votre panier ? ',
                          style: const TextStyle(fontSize: 14, color: _textMuted, height: 1.4),
                          children: const [
                            TextSpan(
                              text: 'Cette action est irréversible.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(110, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        foregroundColor: _textMuted,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        cartProvider.clear();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(80, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        foregroundColor: Colors.red,
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('vider'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: _textDark),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.itemCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _orangePrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined, size: 40, color: _orangePrimary.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre panier est vide',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ajoutez des produits pour commencer',
                    style: TextStyle(fontSize: 14, color: _textMuted),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: _white,
                              surfaceTintColor: _white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: Text(
                                item.product.name,
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
                              ),
                              content: Text(
                                item.product.description,
                                style: const TextStyle(color: _textMuted, height: 1.4),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(foregroundColor: _orangePrimary),
                                  child: const Text('Fermer'),
                                ),
                              ],
                            ),
                          ),
                          child: Ink(
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
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      item.product.image,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 84,
                                        height: 84,
                                        color: _offWhite,
                                        child: Icon(Icons.image_not_supported_outlined, color: _textMuted.withValues(alpha: 0.7)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _textDark,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.product.categorie} • ${item.product.vendeurLocalisation ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 12, color: _textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: _offWhite,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _borderSoft),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_rounded, size: 18),
                                                    color: _textDark,
                                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                                    padding: EdgeInsets.zero,
                                                    visualDensity: VisualDensity.compact,
                                                    onPressed: () => cartProvider.updateQuantity(item.product.id, item.quantity - 1),
                                                  ),
                                                  Container(
                                                    constraints: const BoxConstraints(minWidth: 28),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: _textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_rounded, size: 18),
                                                    color: _orangePrimary,
                                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                                    padding: EdgeInsets.zero,
                                                    visualDensity: VisualDensity.compact,
                                                    onPressed: () => cartProvider.updateQuantity(item.product.id, item.quantity + 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${(item.quantity * item.product.price).toStringAsFixed(0)} $currencySymbol',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: _orangePrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderSoft),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textDark),
                      ),
                      Text(
                        '${cartProvider.totalAmount.toStringAsFixed(0)} $currencySymbol',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _orangePrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Commander sur WhatsApp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Exemple basé sur le contenu du panier
                      final cart = cartProvider.items;
                      final productLines = cart.map((item) {
                        return '${item.product.name} (Quantité : ${item.quantity})';
                      }).join('\n');

                      final totalLine = 'Montant total : ${cartProvider.totalAmount.toStringAsFixed(0)} $currencySymbol';

                      // NB: on ne dépend pas de l’éditeur ci-dessus, on suit exactement le message demandé
                      final message = 'Bonjour,\n\nJe souhaite commander les articles suivants sur Djassa CI :\n'
                          '$productLines\n\n'
                          '$totalLine\n\nMerci de me confirmer la disponibilité des produits ainsi que les modalités de livraison.\n\nCordialement.';

                      // Route vers le WhatsApp du vendeur (on prend le vendeur du premier item)
                      final sellerPhone = cart.isNotEmpty ? cart.first.product.vendeurCompte : '';
                      if (sellerPhone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Numéro vendeur introuvable')),
                        );
                        return;
                      }

                      final url = Uri.parse('whatsapp://send?phone=$sellerPhone&text=${Uri.encodeComponent(message)}');
                      // ignore: avoid_print
                      launchUrl(url);
                    },
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Commander sur WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

                      // Payment selection (désactivé demandé)
              // Card(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text('Méthode de paiement:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              //
              //         DropdownButtonFormField<String>(
              //           value: _paymentMethod,
              //           decoration: const InputDecoration(
              //             labelText: 'Sélectionnez',
              //             border: OutlineInputBorder(),
              //           ),
              //           items: paymentOptions.map((String option) {
              //             return DropdownMenuItem<String>(
              //               value: option,
              //               child: Text(option),
              //             );
              //           }).toList(),
              //           onChanged: (String? newValue) {
              //             setState(() {
              //               _paymentMethod = newValue;
              //             });
              //           },
              //         ),
              //         const SizedBox(height: 16),
              //         TextFormField(
              //           controller: _phoneController,
              //           decoration: const InputDecoration(
              //             labelText: 'Numéro téléphone *',
              //             prefixIcon: Icon(Icons.phone),
              //             border: OutlineInputBorder(),
              //           ),
              //           keyboardType: TextInputType.phone,
              //         ),
              //         const SizedBox(height: 8),
              //         TextFormField(
              //           controller: _accountController,
              //           decoration: const InputDecoration(
              //             labelText: 'Nom du compte *',
              //             prefixIcon: Icon(Icons.account_circle),
              //             border: OutlineInputBorder(),
              //           ),
              //         ),
              //         const SizedBox(height: 16),
              //         Text('Coordonnées livraison *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              //         TextFormField(
              //           controller: _nomLivraisonController,
              //           decoration: const InputDecoration(
              //             labelText: 'Nom complet *',
              //             prefixIcon: Icon(Icons.person),
              //             border: OutlineInputBorder(),
              //           ),
              //         ),
              //         TextFormField(
              //           controller: _villeCommuneController,
              //           decoration: const InputDecoration(
              //             labelText: 'Ville/Commune *',
              //             prefixIcon: Icon(Icons.location_city),
              //             border: OutlineInputBorder(),
              //           ),
              //         ),
              //         TextFormField(
              //           controller: _telLivraisonController,
              //           decoration: const InputDecoration(
              //             labelText: 'Numéro téléphone livraison *',
              //             prefixIcon: Icon(Icons.phone),
              //             border: OutlineInputBorder(),
              //           ),
              //           keyboardType: TextInputType.phone,
              //         ),
              //         TextFormField(
              //           controller: _quartierController,
              //           decoration: const InputDecoration(
              //             labelText: 'Quartier / Adresse *',
              //             prefixIcon: Icon(Icons.location_on),
              //             border: OutlineInputBorder(),
              //           ),
              //         ),
              //         const SizedBox(height: 8),
              //         Row(
              //           children: [
              //             Expanded(
              //               child: TextFormField(
              //                 controller: _buyerLatController,
              //                 decoration: const InputDecoration(
              //                   labelText: 'Latitude livraison (optionnel)',
              //                   border: OutlineInputBorder(),
              //                 ),
              //                 keyboardType: TextInputType.numberWithOptions(decimal: true),
              //               ),
              //             ),
              //             const SizedBox(width: 8),
              //             Expanded(
              //               child: TextFormField(
              //                 controller: _buyerLngController,
              //                 decoration: const InputDecoration(
              //                   labelText: 'Longitude livraison (optionnel)',
              //                   border: OutlineInputBorder(),
              //                 ),
              //                 keyboardType: TextInputType.numberWithOptions(decimal: true),
              //               ),
              //             ),
              //           ],
              //         ),
              //         const SizedBox(height: 8),
              //       ],
              //     ),
              //   ),
              // ),

              // Padding(
              //   padding: const EdgeInsets.all(16),
              //   child: SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       onPressed: cartProvider.itemCount > 0 ? () => _placeOrder(cartProvider, context) : null,
              //       style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              //       child: const Text('Passer la commande', style: TextStyle(fontSize: 18)),
              //     ),
              //   ),
              // ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _accountController.dispose();
    _nomLivraisonController.dispose();
    _telLivraisonController.dispose();
    _villeCommuneController.dispose();
    _quartierController.dispose();
    super.dispose();
  }
}

