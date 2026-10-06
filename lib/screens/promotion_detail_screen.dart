import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotion.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';
import '../utils/theme.dart';
import 'payment_screen.dart';

class PromotionDetailScreen extends StatefulWidget {
  final Promotion promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  String? _paymentMethod;
  double? _buyerLat;
  double? _buyerLng;
  bool _isGettingGps = false;

  late final PageController _pageController;
  int _currentImageIndex = 0;

  List<String> get _promotionImages {
    final images = widget.promotion.images;
    return images.isNotEmpty ? images : [widget.promotion.image];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nomLivraisonController = TextEditingController();
  final TextEditingController _telLivraisonController = TextEditingController();
  final TextEditingController _villeCommuneController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<String> paymentOptions = [
    'Orange Money',
    'MTN Money',
    'Moov Money',
    'Wave',
    'Espèce',
  ];

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isGettingGps = true);

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
    } catch (_) {
      if (mounted) {
        setState(() => _isGettingGps = false);
      }
    }
  }

  Future<void> _buyPromotion(Promotion promotion) async {
    if (_paymentMethod == null ||
        _phoneController.text.isEmpty ||
        _accountController.text.isEmpty ||
        _nomLivraisonController.text.isEmpty ||
        _telLivraisonController.text.isEmpty ||
        _villeCommuneController.text.isEmpty ||
        _quartierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final data = {
        'items': [
          {
            'id': promotion.id,
            'name': promotion.name,
            'price': promotion.discountedPrice,
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

      final response = await ApiService.createOrder(data);

      // Récupérer l'orderId retourné par le backend
      final orderId = response.data['order']['id'].toString();

      // Initialiser le paiement GeniusPay avec le prix promotionnel
      final checkoutUrl = await ApiService.instance.initGeniusPayCheckoutUrl(
        amount: promotion.discountedPrice.toInt(),
        phone: _phoneController.text,
        orderId: orderId,
        name: _nomLivraisonController.text,
      );

      if (checkoutUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Impossible d\'initialiser le paiement GeniusPay'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Ouvrir la page de paiement GeniusPay
      await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);

      // Ne pas afficher "Commande réussie" ici - le webhook confirmera le paiement
      // Fermer le dialog après lancement
      _paymentMethod = null;
      _phoneController.clear();
      _accountController.clear();
      _nomLivraisonController.clear();
      _telLivraisonController.clear();
      _villeCommuneController.clear();
      _quartierController.clear();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPaymentDialog(Promotion promotion) async {
    _paymentMethod = null;
    _buyerLat = null;
    _buyerLng = null;
    _phoneController.clear();
    _accountController.clear();
    _nomLivraisonController.clear();
    _telLivraisonController.clear();
    _villeCommuneController.clear();
    _quartierController.clear();

    _getCurrentLocation();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Acheter ${promotion.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Prix promo: ',
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                      ),
                      Text(
                        _formatPrice(promotion.discountedPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Méthode de paiement *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: paymentOptions.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value),
                  validator: (value) => value == null ? 'Choisissez une méthode' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du compte *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomLivraisonController,
                  decoration: const InputDecoration(
                    labelText: 'Nom pour la livraison *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telLivraisonController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone livraison *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _villeCommuneController,
                  decoration: const InputDecoration(
                    labelText: 'Ville/Commune *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quartierController,
                  decoration: const InputDecoration(
                    labelText: 'Quartier *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isGettingGps ? null : _getCurrentLocation,
                  icon: _isGettingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_buyerLat != null
                      ? 'Position GPS: ${_buyerLat!.toStringAsFixed(4)}, ${_buyerLng!.toStringAsFixed(4)}'
                      : 'Utiliser ma position GPS'),
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
              onPressed: () => _buyPromotion(promotion),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer l\'achat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _nomLivraisonController.dispose();
    _telLivraisonController.dispose();
    _villeCommuneController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: Text(promotion.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(_promotionImages[_currentImageIndex]),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _promotionImages.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final imageUrl = _promotionImages[index];
                          return Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 250,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_promotionImages.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${_promotionImages.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${promotion.discountPercent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promotion.categorie,
                    style: TextStyle(
                      color: Colors.deepOrange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              promotion.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _formatPrice(promotion.discountedPrice),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatPrice(promotion.price),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Économie de ${_formatPrice(promotion.price - promotion.discountedPrice)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              promotion.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(promotion),
                icon: const Icon(Icons.shopping_cart),
                label: Text(
                  'Acheter pour ${_formatPrice(promotion.discountedPrice)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}