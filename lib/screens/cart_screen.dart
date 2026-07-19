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
      appBar: AppBar(
        leading: const BackArrow(),
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
                      margin: const EdgeInsets.symmetric(vertical: 4),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                    label: const Text('Commander sur WhatsApp'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

