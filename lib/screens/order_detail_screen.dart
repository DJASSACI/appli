import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'package:go_router/go_router.dart';
import '../widgets/back_arrow.dart';


class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _orangeSecondary = Color(0xFFFFB15C);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _orangePrimary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
          'Commande #${order.id}',
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ce que tu as acheté - Produits
            _sectionTitle('Produits achetés:'),
            ...order.articles.map((art) {
              Map<String, dynamic> productData;
              if ((art as Map)['product'] != null) {
                productData = Map<String, dynamic>.from((art as Map)['product']);
              } else {
                productData = Map<String, dynamic>.from(art as Map);
              }
              final product = Product.fromJson(productData);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: _cardDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.image,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
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
                              product.name,
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
                              '${art['quantite'] ?? 1}x ${product.price.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontSize: 13, color: _textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sous-total: ${(art['quantite'] ?? 1 * product.price).toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontSize: 13, color: _textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(art['quantite'] ?? 1 * product.price).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _orangePrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 14),

            // Total
            Container(
              decoration: _cardDecoration,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: _textDark),
                    ),
                    Text(
                      '${order.total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _orangePrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Statut de la commande
            _sectionTitle('Statut commande:'),
            Container(
              decoration: _cardDecoration,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusBadge('Commande: ${order.statut.toUpperCase()}', _orangePrimary),
                    const SizedBox(height: 8),
                    _statusBadge('Vendeur: ${order.statutVendeur?.toUpperCase() ?? "N/A"}', _textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Paiement
            _sectionTitle('Paiement:'),
            Container(
              decoration: _cardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _orangePrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment_rounded, color: _orangePrimary, size: 20),
                ),
                title: Text(
                  order.methodePaiement ?? 'N/A',
                  style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.numeroPaiement != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Numéro: ${order.numeroPaiement}', style: const TextStyle(color: _textMuted)),
                      ),
                    if (order.nomCompte != null)
                      Text('Compte: ${order.nomCompte}', style: const TextStyle(color: _textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Livraison
            _sectionTitle('Livraison:'),
            Container(
              decoration: _cardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _orangePrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: _orangePrimary, size: 20),
                ),
                title: Text(
                  order.nomLivraison ?? 'Retrait en magasin',
                  style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.telLivraison != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Tel: ${order.telLivraison}', style: const TextStyle(color: _textMuted)),
                      ),
                    if (order.villeCommune != null)
                      Text('Ville: ${order.villeCommune}', style: const TextStyle(color: _textMuted)),
                    if (order.quartier != null)
                      Text('Quartier: ${order.quartier}', style: const TextStyle(color: _textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Vendeur
            _sectionTitle('Vendeur:'),
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _orangePrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: _orangePrimary, size: 20),
                    ),
                    title: const Text(
                      'Boutique principale',
                      style: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Seller ID: ${order.seller}', style: const TextStyle(color: _textMuted)),
                  ),
                  if (order.articles.isNotEmpty)
                    const Divider(height: 1, color: _borderSoft, indent: 16, endIndent: 16),
                  if (order.articles.isNotEmpty) ...order.articles.map((art) {
                    Map<String, dynamic> productData = Map<String, dynamic>.from(art as Map);
                    final product = Product.fromJson(productData);
                    return ListTile(
                      dense: true,
                      title: Text(
                        product.vendeurNom ?? 'Vendeur',
                        style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(product.vendeurCompte ?? '', style: const TextStyle(color: _textMuted)),
                      trailing: Text(
                        product.vendeurLocalisation ?? '',
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    );
                  }).toList(),
                  const Divider(height: 1, color: _borderSoft, indent: 16, endIndent: 16),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: const Icon(Icons.chat_rounded, color: _orangePrimary),
                    title: const Text(
                      'Contacter Vendeur',
                      style: TextStyle(color: _orangePrimary, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: _textMuted),
                    onTap: () {
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
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

