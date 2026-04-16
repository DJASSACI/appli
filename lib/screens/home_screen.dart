import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Djassa CI - Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.go('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.sell),
            onPressed: () => context.go('/sell'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Consumer2<ProductsProvider, AuthProvider>(
        builder: (context, productsProvider, authProvider, child) {
          if (productsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${productsProvider.error}'),
                  ElevatedButton(
                    onPressed: () => productsProvider.fetchProducts(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher produits...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: productsProvider.searchProducts,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Tous'),
                        onSelected: (_) => productsProvider.filterByCategory(''),
                        selected: false,
                      ),
                      ...categories.map((cat) => ChoiceChip(
                        label: Text(cat),
                        onSelected: (_) => productsProvider.filterByCategory(cat),
                        selected: false,
                      )),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: productsProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : productsProvider.filteredProducts.isEmpty
                        ? const Center(child: Text('Aucun produit trouvé'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: productsProvider.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = productsProvider.filteredProducts[index];
                              return _ProductCard(product: product);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _CategoryChip({
  required String label,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      onSelected: (_) => onTap(),
      selected: false,
    ),
  );
}

class _ProductCard extends StatefulWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  String? _paymentMethod;
  double? _buyerLat;
  double? _buyerLng;
  bool _isGettingGps = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

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
      if (mounted) {
        setState(() {
          _isGettingGps = false;
        });
      }
    }
  }

  Future<void> _showQuickBuyDialog(BuildContext context, Product product) async {
_paymentMethod = null;
    _buyerLat = null;
    _buyerLng = null;
    _phoneController.clear();
    _accountController.clear();

    // Silently get GPS
    _getCurrentLocation();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Acheter ${widget.product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.product.price.toStringAsFixed(0)} FCFA'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Méthode paiement'),
                  items: paymentOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                  onChanged: (value) => setDialogState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Numéro téléphone', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountController,
                  decoration: const InputDecoration(labelText: 'Nom compte', prefixIcon: Icon(Icons.account_circle)),
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
              onPressed: _paymentMethod != null && _phoneController.text.isNotEmpty && _accountController.text.isNotEmpty && Provider.of<AuthProvider>(context, listen: false).isAuthenticated
                ? () async {
                    Navigator.pop(context);
                    final data = {
                      'items': [
                        {
                          'id': widget.product.id,
                          'name': widget.product.name,
                          'price': widget.product.price,
                          'quantite': 1,
                        }
                      ],
                      'paymentMethod': _paymentMethod!.toLowerCase().replaceAll(' ', '_'),
                      'phoneNumber': _phoneController.text,
                      'accountName': _accountController.text,
                      if (_buyerLat != null) 'buyerLat': _buyerLat,
                      if (_buyerLng != null) 'buyerLng': _buyerLng,
                    };
                    try {
                      await ApiService.createOrder(data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Commande réussie !'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                : null,
              child: const Text('Acheter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                context.go('/product/${widget.product.id}', extra: widget.product);
              },
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: widget.product.image,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.product.price.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '${widget.product.categorie} • ${widget.product.vendeurLocalisation}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Panier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        cartProvider.addItem(widget.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajouté au panier')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _accountController.dispose();
    super.dispose();
  }
}

