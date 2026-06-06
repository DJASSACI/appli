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
                  // Refresh seller status before requesting a new certification window
                  try {
                    await ApiService.instance.post('/api/users/refresh-seller-verified', data: {});
                  } catch (_) {}

                  // (Optionnel) on pourrait aussi afficher un message si besoin


                  final nomController = TextEditingController();
                  final numeroController = TextEditingController();


                  showDialog(
                    context: context,
                  builder: (context) => AlertDialog(
                      title: const Text('Devenir boutique certifiée'),

                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nomController,
                              decoration: const InputDecoration(
                                labelText: 'Nom de compte',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: numeroController,
                              decoration: const InputDecoration(
                                labelText: 'Numéro de compte',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
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
                          onPressed: () async {
                            // On garde l’UI et on remplace juste le flow de redirection.
                            // Nouveau: ouvrir WhatsApp de l’admin avec un message pré-rempli.
                            try {
                              // On ne met pas le nom/numéro dans WhatsApp (selon demande)
                              // final nomVendeur = nomController.text;
                              // final numeroCompte = numeroController.text;

                              final message = 'Bonjour l\'équipe Djassa-ci, je souhaite certifier ma boutique.';

                              const adminPhone = '0715926401';
                              final url = Uri.parse(
                                'whatsapp://send?phone=$adminPhone&text=${Uri.encodeComponent(message)}',
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await launchUrl(url);
                            } catch (e) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur ouverture WhatsApp: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Certifier'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('Certifier mon compte'),
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

