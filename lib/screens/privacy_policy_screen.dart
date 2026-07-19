import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/back_arrow.dart';


class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSection({
    required String title,
    required String content,
    IconData? icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.orange),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletSection({
    required String title,
    required List<String> items,
    IconData? icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.orange),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        leading: const BackArrow(),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Accueil',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.lock,
                    size: 60,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '🔐 POLITIQUE DE CONFIDENTIALITÉ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'DJASSA CI',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Introduction',
              icon: Icons.info,
              content:
                  
                  'Djassa CI est une plateforme de commerce électronique permettant aux utilisateurs d\'acheter et de vendre des produits entre particuliers en Côte d\'Ivoire.\n\n'
                  'Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos données personnelles lorsque vous utilisez notre application et nos services.\n\n'
                  '⚠️ NOTE IMPORTANTE : Certaines fonctionnalités de l\'application (telles que le système de paiement intégré, la geolocalisation, données de transaction et le chat interne...) ont été désactivées momentanément pour des raisons de sécurité et de maintenance technique.\n\n',

            ),
            _buildBulletSection(
              title: '2. Données collectées',
              icon: Icons.storage,
              items: [
                'Informations d\'inscription : nom, prénom, numéro de téléphone, adresse de livraison, mot de passe (stocké sous forme cryptée)',
                'Données de transaction : produits achetés ou vendus, historique des commandes, montant des paiements, méthode de paiement utilisée, informations de livraison(momentanément indisponible)',
                'Données de navigation et utilisation : mise en contacte vendeur et acheteur via WhatsApp/appel , produits consultés ou recherchés, actions effectuées sur la plateforme',
                'Données techniques : adresse IP, type de navigateur, logs de connexion',
              ],
            ),
            _buildBulletSection(
              title: '3. Utilisation des données',
              icon: Icons.data_usage,
              items: [
                'Créer et gérer votre compte utilisateur',
                'Permettre les achats et ventes de produits',
                'Gérer les transactions et les paiements(momentanément indisponible)',
                'Assurer la sécurité de la plateforme',
                'Améliorer les services et l\'expérience utilisateur',
                'Permettre la communication entre acheteurs et vendeurs (watsapp, appel)',
              ],
            ),

             _buildBulletSection(
              title: '4. Géolocalisation au Premier Plan',
              icon: Icons.location_on,
              items: [
                  'L\'application accède aux coordonnées GPS (Latitude et Longitude) de votre appareil uniquement lorsque l\'application est active à l\'écran, et exclusivement au moment où un vendeur demande la certification officielle de sa boutique.\n\n'
                  'L\'accès au GPS requiert votre consentement obligatoire via la boîte de dialogue du système Android/iOS. Aucun suivi de localisation n\'est réalisé en arrière-plan lorsque l\'application est fermée.',
             ]
            ),  
            _buildBulletSection(
              title: '5. Partage des données',
              icon: Icons.share,
              items: [
                'Nous ne vendons pas vos données personnelles.',
                'Avec les vendeurs pour traiter une commande',
                'Avec les acheteurs pour organiser la livraison',
                'Avec des services de paiement (ex: genuispay) momentanément indisponible',
                'Avec les autorités en cas d\'obligation légale',
              ],
            ),
            _buildSection(
              title: '6. Stockage et sécurité',
              icon: Icons.security,
              content:
                  'Vos données sont stockées de manière sécurisée sur nos serveurs.\n\n'
                  'Nous utilisons :\n'
                  '• Authentification par token JWT\n'
                  '• Cryptage des mots de passe (SHA-256)\n'
                  '• Contrôle d\'accès selon les rôles (utilisateur / vendeur / admin)\n\n'
                  'Cependant, aucun système n\'est totalement sécurisé à 100%.',
            ),
            _buildSection(
              title: '7. Durée de conservation',
              icon: Icons.timer,
              content:
                  'Les données sont conservées tant que votre compte est actif.\n\n'
                  'Vous pouvez demander la suppression de votre compte à tout moment.',
            ),
            _buildBulletSection(
              title: '8. Vos droits',
              icon: Icons.verified_user,
              items: [
                'Accéder à vos données personnelles',
                'Modifier vos informations',
                'Demander la suppression de votre compte',
                'Refuser certaines utilisations (dans les limites techniques du service)',
              ],
            ),
            _buildSection(
              title: '9. Cookies et technologies similaires',
              icon: Icons.cookie,
              content:
                  'Djassa CI peut utiliser des cookies pour :\n'
                  '• Maintenir la session utilisateur\n'
                  '• Améliorer la navigation\n'
                  '• Analyser l\'utilisation de l\'application',
            ),
            _buildSection(
              title: '10. Services tiers',
              icon: Icons.cloud,
              content:
                  'Nous utilisons certains services externes :\n'
                  '• pour la gestion des images (ex : cloudinary)\n'
                  '• Notifications (FCM / Firebase)\n'
                  '• Hébergement du serveur\n\n'
                  'Ces services ont leurs propres politiques de confidentialité.',
            ),
            _buildSection(
              title: '11. Responsabilité de l\'utilisateur',
              icon: Icons.person,
              content:
                  'L\'utilisateur est responsable :\n'
                  '• De la confidentialité de son mot de passe\n'
                  '• Des informations qu\'il publie (produits, messages)\n'
                  '• De l\'usage de son compte',
            ),
            _buildSection(
              title: '12. Modifications',
              icon: Icons.update,
              content:
                  'Cette politique peut être mise à jour à tout moment pour améliorer le service ou respecter la loi.',
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_mail, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '12. Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'Pour toute question concernant cette politique :',
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('djassaci3@gmail.com'),
                      onTap: () => launchUrl(
                        Uri.parse('mailto:djassaci3@gmail.com'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

