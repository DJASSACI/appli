import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
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
      body: authProvider.user == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(
                authProvider.user!.nom[0].toUpperCase(),
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${authProvider.user!.prenom} ${authProvider.user!.nom}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              authProvider.user!.numero,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Téléphone'),
                subtitle: Text(authProvider.user!.numero),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Adresse'),
                subtitle: Text(authProvider.user!.address),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Accueil'),
            ),
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
            ElevatedButton.icon(
              onPressed: () => context.go('/my-products'),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Mes produits'),
            ),
            if (authProvider.user?.role == 'admin')
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
        ),
    );
  }
}

