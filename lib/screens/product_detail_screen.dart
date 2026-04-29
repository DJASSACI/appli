import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:geolocator/geolocator.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _paymentMethod;
  double? _buyerLat;
  double? _buyerLng;
  bool _isGettingGps = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nomLivraisonController = TextEditingController();
  final TextEditingController _telLivraisonController = TextEditingController();
  final TextEditingController _villeCommuneController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();

  final List<String> paymentOptions = [
    'Orange Money',
    'MTN Money',
    'Moov Money',
    'Wave',
    'Espèce'
  ];

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isGettingGps = true;
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _buyerLat = position.latitude;
          _buyerLng = position.longitude;
          _isGettingGps = false;
        });
      }
    } catch (e) {
      // Silent fail - no snackbar, just fallback
      if (mounted) {
        setState(() {
          _isGettingGps = false;
        });
      }
    }
  }

  Future<void> _buyDirect(Product product) async {
    if (_paymentMethod == null || _phoneController.text.isEmpty || _accountController.text.isEmpty ||
        _nomLivraisonController.text.isEmpty || _telLivraisonController.text.isEmpty ||
        _villeCommuneController.text.isEmpty || _quartierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final data = {
        'items': [
          {
            'id': product.id,
            'name': product.name,
            'price': product.price,
            'quantite': 1,
          }
        ],
        'paymentMethod': _paymentMethod!.toLowerCase().replaceAll(' ', '_'),
        'phoneNumber': _phoneController.text,
        'accountName': _accountController.text,
        'nomLivraison': _nomLivraisonController.text,
        'telLivraison': _telLivraisonController.text,
        'villeCommune': _villeCommuneController.text,
        'quartier': _quartierController.text,
        if (_buyerLat != null) 'buyerLat': _buyerLat,
        if (_buyerLng != null) 'buyerLng': _buyerLng,
        'notify_url': "https://djassa-backend-imxo.onrender.com/notify",
        'transactionId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      await ApiService.createOrder(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande réussie !'), backgroundColor: Colors.green),
      );

      _paymentMethod = null;
      _phoneController.clear();
      _accountController.clear();
      _nomLivraisonController.clear();
      _telLivraisonController.clear();
      _villeCommuneController.clear();
      _quartierController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPaymentDialog(Product product) async {
    _paymentMethod = null;
    _buyerLat = null;
    _buyerLng = null;
    _phoneController.clear();
    _accountController.clear();
    _nomLivraisonController.clear();
    _telLivraisonController.clear();
    _villeCommuneController.clear();
    _quartierController.clear();

    // Silently get GPS location
    _getCurrentLocation();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Acheter ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${product.price.toStringAsFixed(0)} $currencySymbol'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Méthode de paiement'),
                  items: paymentOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro téléphone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du compte',
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomLivraisonController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet livraison',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _villeCommuneController,
                  decoration: const InputDecoration(
                    labelText: 'Ville/Commune',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telLivraisonController,
                  decoration: const InputDecoration(
                    labelText: 'Tel livraison',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quartierController,
                  decoration: const InputDecoration(
                    labelText: 'Quartier / Adresse',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _buyDirect(product),
              child: const Text('Acheter maintenant'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = GoRouterState.of(context).extra as Product?;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produit')),
        body: const Center(child: Text('Produit non trouvé')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              child: Image.network(
                product.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price.toStringAsFixed(0)} $currencySymbol',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Catégorie: ${product.categorie}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    'Vendeur: ${product.vendeurNom}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    'Localisation: ${product.vendeurLocalisation}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  // Contact Vendeur
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contacter le vendeur',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: product.vendeurCompte.isNotEmpty ? () => launchUrl(
                                    Uri.parse('tel://${product.vendeurCompte}'),
                                    mode: LaunchMode.externalApplication,
                                  ) : null,
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Appel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: product.vendeurCompte.isNotEmpty ? () {
                                    final message = 'Je suis intéressé par ${product.name} quantite 1 et photo du produit ${product.description}';
                                    launchUrl(
                                      Uri.parse('whatsapp://send?phone=${product.vendeurCompte}&text=${Uri.encodeComponent(message)}'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } : null,
                                  icon: const Icon(Icons.chat),
                                  label: const Text('WhatsApp'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],

                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.store),
                              label: Text('Voir boutique ${product.vendeurNom}'),
                              onPressed: () => context.go('/seller/${product.vendeurNom}'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Vendeur: ${product.vendeurNom} (${product.vendeurLocalisation})',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Provider.of<CartProvider>(context, listen: false).addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ajouté au panier !')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: Text('Ajouter au panier'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(product),
                          icon: const Icon(Icons.payment),
                          label: const Text('Acheter maintenant'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

