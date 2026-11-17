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
  // Orange Premium palette (visual only)
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  bool _isFollowing = false;
  int _followersCount = 0;
  bool _isLoadingFollow = true;
  bool _isUpdatingFollow = false;

  // Profil public du vendeur
  String? _sellerAvatarUrl;
  bool _sellerVerified = false;
  String? _sellerVerifiedUntil;
  bool _isLoadingSellerProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
      _loadFollowStatus();
      _loadSellerProfile();
    });
  }

  Future<void> _loadSellerProfile() async {
    final sellerId = widget.sellerId;
    if (sellerId == null) {
      if (mounted) {
        setState(() => _isLoadingSellerProfile = false);
      }
      return;
    }

    try {
      final response = await ApiService.instance.get('/api/users/$sellerId');
      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _sellerAvatarUrl = data['avatarUrl'];
          _sellerVerified = data['sellerVerified'] == true;
          _sellerVerifiedUntil = data['sellerVerifiedUntil'];
          _isLoadingSellerProfile = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingSellerProfile = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSellerProfile = false);
      }
    }
  }

  bool _isSellerCurrentlyCertified() {
    if (!_sellerVerified) return false;
    if (_sellerVerifiedUntil == null) return true;
    try {
      final until = DateTime.parse(_sellerVerifiedUntil!);
      return until.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
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

  void _showFullScreenAvatar(BuildContext context) {
    final avatarUrl = _sellerAvatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image, color: Colors.white70, size: 64),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowHeader(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: true).user;
    final isOwnSeller =
        currentUser != null && widget.sellerId != null && currentUser.id == widget.sellerId;

    if (isOwnSeller) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _orangePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: _orangePrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Votre boutique',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _textDark, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isCertified = _isSellerCurrentlyCertified();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar du vendeur
                _isLoadingSellerProfile
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _offWhite,
                          border: Border.all(color: _borderSoft, width: 2),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: _orangePrimary),
                        ),
                      )
                    : GestureDetector(
                        onTap: (_sellerAvatarUrl != null && _sellerAvatarUrl!.isNotEmpty)
                            ? () => _showFullScreenAvatar(context)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _orangePrimary.withValues(alpha: 0.45), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _offWhite,
                            backgroundImage: (_sellerAvatarUrl != null && _sellerAvatarUrl!.isNotEmpty)
                                ? NetworkImage(_sellerAvatarUrl!)
                                : null,
                            child: (_sellerAvatarUrl == null || _sellerAvatarUrl!.isEmpty)
                                ? Text(
                                    widget.sellerName.isNotEmpty
                                        ? widget.sellerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _orangePrimary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                // Nom + badge certifié
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.sellerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCertified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Certifié',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 15, color: _textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$_followersCount abonnés',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: _textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoadingFollow)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _orangePrimary),
                  )
                else
                  _isFollowing
                      ? OutlinedButton.icon(
                          onPressed: _isUpdatingFollow ? null : _toggleFollow,
                          icon: _isUpdatingFollow
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _orangePrimary),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: const Text('Abonné'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _orangePrimary,
                            side: const BorderSide(color: _orangePrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isUpdatingFollow ? null : _toggleFollow,
                          icon: _isUpdatingFollow
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _white),
                                )
                              : const Icon(Icons.person_add, size: 18),
                          label: const Text('S\'abonner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orangePrimary,
                            foregroundColor: _white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: Text(
          widget.sellerName,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: _textDark),
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _orangePrimary));
          }

          final sellerProducts = productsProvider.products
              .where((p) => p.vendeurNom == widget.sellerName)
              .toList();

          if (sellerProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 56, color: _textMuted.withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun produit trouvé pour ce vendeur',
                    style: TextStyle(color: _textMuted, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
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
                    return Container(
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderSoft),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push(
                          '/product/${product.id}',
                          extra: product,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: _offWhite,
                                    child: const Icon(Icons.image_outlined, color: _textMuted),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.price.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _orangePrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${product.categorie} • ${product.vendeurLocalisation}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textMuted,
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
