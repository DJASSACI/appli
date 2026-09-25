import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class SellerScreen extends StatefulWidget {
  final String sellerName;
  final int? sellerId;

  const SellerScreen({
    super.key,
    required this.sellerName,
    this.sellerId,
  });

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  bool _isFollowing = false;
  int _followersCount = 0;
  bool _isLoadingFollow = true;
  bool _isUpdatingFollow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
      _loadFollowStatus();
    });
  }

  Future<void> _loadFollowStatus() async {
    final sellerId = widget.sellerId;
    if (sellerId == null) {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
      return;
    }

    try {
      final response =
          await ApiService.instance.get('/api/users/$sellerId/follow');
      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _isFollowing = data['isFollowing'] == true;
          _followersCount = (data['followersCount'] as num?)?.toInt() ?? 0;
          _isLoadingFollow = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final sellerId = widget.sellerId;
    if (sellerId == null || _isUpdatingFollow) return;

    final authUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour vous abonner.')),
      );
      return;
    }
    if (authUser.id == sellerId) return;

    setState(() => _isUpdatingFollow = true);
    try {
      final endpoint = '/api/users/$sellerId/follow';
      final response = _isFollowing
          ? await ApiService.instance.delete(endpoint)
          : await ApiService.instance.post(endpoint, data: {});
      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _isFollowing =
              data['isFollowing'] == true || data['subscribed'] == true;
          _followersCount =
              (data['followersCount'] as num?)?.toInt() ?? _followersCount;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de modifier l\'abonnement.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFollow = false);
      }
    }
  }

  Widget _buildFollowHeader(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: true).user;
    final isOwnSeller =
        currentUser != null && widget.sellerId != null && currentUser.id == widget.sellerId;

    if (isOwnSeller) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          'Votre boutique',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$_followersCount abonnés',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (_isLoadingFollow)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ElevatedButton.icon(
              onPressed: _isUpdatingFollow ? null : _toggleFollow,
              icon: Icon(
                _isFollowing ? Icons.check : Icons.person_add,
                size: 18,
              ),
              label: Text(_isFollowing ? 'Abonné' : "S'abonner"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: Text(widget.sellerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sellerProducts = productsProvider.products
              .where((p) => p.vendeurNom == widget.sellerName)
              .toList();

          if (sellerProducts.isEmpty) {
            return const Center(child: Text('Aucun produit trouvé pour ce vendeur'));
          }

          return Column(
            children: [
              _buildFollowHeader(context),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sellerProducts.length,
                  itemBuilder: (context, index) {
                    final product = sellerProducts[index];
                    return Card(
                      child: InkWell(
                        onTap: () => context.push(
                          '/product/${product.id}',
                          extra: product,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${product.price.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${product.categorie} • ${product.vendeurLocalisation}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
