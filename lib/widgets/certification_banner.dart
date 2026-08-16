import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Affiche une bannière d'avertissement lorsque la certification vendeur
/// expire dans 4 jours ou moins, ou est déjà expirée.
class CertificationBanner extends StatefulWidget {
  final String? sellerVerifiedUntil;
  final bool? sellerVerified;
  final String sellerName;
  final VoidCallback? onRenew;

  const CertificationBanner({
    super.key,
    required this.sellerVerifiedUntil,
    required this.sellerVerified,
    required this.sellerName,
    this.onRenew,
  });

  @override
  State<CertificationBanner> createState() => _CertificationBannerState();
}

class _CertificationBannerState extends State<CertificationBanner> {
  bool _isDismissed = false;

  /// Calcule le nombre de jours restants jusqu'à la date d'expiration.
  /// Retourne un int négatif si déjà expiré.
  int _daysRemaining(String untilStr) {
    try {
      final until = DateTime.parse(untilStr);
      final now = DateTime.now();
      final diff = until.difference(DateTime(now.year, now.month, now.day));
      return diff.inDays;
    } catch (_) {
      return 999; // si la date est invalide, on ne montre pas de bannière
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    // Pas de sellerVerifiedUntil => pas de bannière
    if (widget.sellerVerifiedUntil == null || widget.sellerVerifiedUntil!.isEmpty) {
      return const SizedBox.shrink();
    }

    final daysRemaining = _daysRemaining(widget.sellerVerifiedUntil!);

    // Pas de bannière si > 4 jours restants
    if (daysRemaining > 4) {
      return const SizedBox.shrink();
    }

    // Déterminer le message, l'icône et la couleur selon les jours restants
    String message;
    IconData icon;
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (daysRemaining < 0) {
      // Expiré
      message =
          '❌ Votre certification de vendeur a expiré. Votre badge de vendeur certifié a été désactivé. Renouvelez votre certification pour retrouver votre badge.';
      icon = Icons.error_outline;
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      borderColor = Colors.red.shade300;
    } else if (daysRemaining == 0) {
      // Aujourd'hui
      message =
          '⚠️ Votre certification de vendeur expire aujourd\'hui. Renouvelez-la pour éviter la désactivation de votre badge.';
      icon = Icons.warning_amber_rounded;
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade300;
    } else if (daysRemaining == 1) {
      // Demain
      message =
          '⚠️ Votre certification de vendeur expire demain. Renouvelez-la afin de conserver votre badge de vendeur certifié.';
      icon = Icons.warning_amber_rounded;
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade300;
    } else {
      // 2, 3 ou 4 jours
      message =
          '⚠️ Votre certification de vendeur expire dans $daysRemaining jours. Renouvelez-la afin de conserver votre badge de vendeur certifié.';
      icon = Icons.info_outline;
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade200;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.only(left: 12, top: 12, right: 8, bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: textColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _isDismissed = true),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Renouveler ma certification',
                style: TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: daysRemaining < 0
                    ? Colors.red.shade600
                    : Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _launchWhatsApp(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final message =
        'Bonjour l\'équipe Djassa-ci, je souhaite renouveler ma certification. Voici mon nom de vendeur : ${widget.sellerName}';

    const adminPhone = '+2250715926401';
    final url = Uri.parse(
      'whatsapp://send?phone=$adminPhone&text=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(url);
      // Déclencher le rafraîchissement des données utilisateur
      // pour que la bannière disparaisse dès que le backend est mis à jour
      widget.onRenew?.call();
    } catch (_) {
      // Fallback si WhatsApp n'est pas installé
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez installer WhatsApp pour contacter le support.'),
          ),
        );
      }
    }
  }
}
