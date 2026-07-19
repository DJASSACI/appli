import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/back_arrow.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';




class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _triedRestoreOnce = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_triedRestoreOnce) return;
      _triedRestoreOnce = true;

      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) return;

      await authProvider.loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final user = authProvider.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.isLoading
                        ? 'Chargement...'
                        : 'Session indisponible. Rechargez la page.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.loadCurrentUser();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 50,
                child: Text(
                  user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${user.prenom} ${user.nom}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                user.numero,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Téléphone'),
                  subtitle: Text(user.numero),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Adresse'),
                  subtitle: Text(user.address),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text('Accueil'),
              ),
              /*
              ElevatedButton.icon(
                onPressed: () => context.go('/my-orders'),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Mes commandes'),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/my-seller-orders'),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Mes commandes vendeur'),
              ),
              */
              ElevatedButton.icon(
                onPressed: () => context.go('/my-products'),
                icon: const Icon(Icons.inventory_2),
                label: const Text('Mes produits'),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () async {
                  final numeroCompte = user.numero.trim();
                  final nomCompte = user.nom.trim();
                  final message =
                      'Bonjour DJASSA CI, je souhaite demander la suppression de mon compte lié au $numeroCompte et $nomCompte ';

                  const phone = '+2250715926401';
                  final url = Uri.parse(
                    'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}',
                  );

                  await launchUrl(url);
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Demander la suppression de mon compte'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),

              ElevatedButton.icon(
                onPressed: () async {

                  // Refresh seller status before requesting a new certification window
                  try {
                    await ApiService.instance.post('/api/users/refresh-seller-verified', data: {});
                  } catch (_) {}

                  // Redirection directe WhatsApp (sans formulaire)
                  final nomVendeur = user.nom.trim();
                  final message =
                      'Bonjour l\'équipe Djassa-ci, je souhaite certifier ma boutique. Voici mon nom de vendeur : $nomVendeur';

                  const adminPhone = '+2250715926401';
                  final url = Uri.parse(
                    'whatsapp://send?phone=$adminPhone&text=${Uri.encodeComponent(message)}',
                  );

                  await launchUrl(url);
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('Devenir boutique certifiée'),
              ),
              
              if (user.role == 'admin')
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin-dashboard'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              Card(

                child: ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text('Politique de confidentialité'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/privacy-policy'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.orange),
                  title: const Text('Support / Contact'),
                  subtitle: const Text('0715926401'),
                  trailing: const Icon(Icons.phone),
                  onTap: () => launchUrl(Uri.parse('tel:0715926401')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

