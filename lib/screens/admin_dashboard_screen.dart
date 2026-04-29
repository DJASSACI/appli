import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? stats;
  List<Order> adminOrders = [];
  List<User> adminUsers = [];
  bool isLoading = true;
  bool ordersLoading = true;
  bool usersLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadStats();
    loadAdminOrders();
    loadAdminUsers();
  }

  Future<void> loadAdminUsers() async {
    try {
      setState(() => usersLoading = true);
      final response = await ApiService.instance.get('/api/users');
      if (mounted) {
        setState(() {
          adminUsers = (response.data as List).map((json) => User.fromJson(json)).toList();
          usersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => usersLoading = false);
    }
  }

  Future<void> loadAdminOrders() async {
    try {
      setState(() => ordersLoading = true);
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
      await ordersProvider.fetchOrders();
      if (mounted) {
        setState(() {
          adminOrders = ordersProvider.orders;
          ordersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => ordersLoading = false);
    }
  }

  Future<void> loadStats() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.instance.get('/api/stats');
      setState(() {
        stats = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadStats,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : stats == null
                  ? const Center(child: Text('Aucune donnée'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Statistiques Globales',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
_StatCard(
                                title: '1. Total utilisateurs',
                                subtitle: 'combien de comptes sont enregistrés',
                                value: stats!['totalUsers'].toString(),
                                icon: Icons.people,
                                color: Colors.blue,
                              ),
_StatCard(
                                title: '2. Total produits',
                                subtitle: 'tous les produits publiés sur Djassa CI',
                                value: stats!['totalProducts'].toString(),
                                icon: Icons.inventory_2,
                                color: Colors.green,
                              ),
_StatCard(
                                title: '3. Total commandes',
                                subtitle: 'toutes les commandes passées',
                                value: stats!['totalOrders'].toString(),
                                icon: Icons.shopping_cart,
                                color: Colors.orange,
                              ),
_StatCard(
                                title: '4. Revenus totaux',
                                subtitle: 'argent total généré',
                                value: '${stats!['totalRevenue'].toStringAsFixed(0)} FCFA',
                                icon: Icons.attach_money,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Commandes Détaillées',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: ordersLoading ? null : loadAdminOrders,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(ordersLoading ? 'Chargement...' : 'Refresh'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Utilisateurs Inscrits',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: usersLoading ? null : loadAdminUsers,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(usersLoading ? 'Chargement...' : 'Refresh'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: usersLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : adminUsers.isEmpty
                                          ? const Center(child: Text('Aucun utilisateur'))
                                          : RefreshIndicator(
                                              onRefresh: loadAdminUsers,
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: adminUsers.length,
                                                itemBuilder: (context, index) {
                                                  final user = adminUsers[index];
                                                  return Card(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    child: ListTile(
                                                      leading: CircleAvatar(
                                                        child: Text(user.numero.substring(user.numero.length - 3)),
                                                      ),
                                                      title: Text('${user.prenom} ${user.nom}'),
                                                      subtitle: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Numéro: ${user.numero}'),
                                                          Text('Rôle: ${user.role.toUpperCase()}'),
                                                          Text('Adresse: ${user.address}'),
                                                          Text('Inscrit: ${user.dateInscription.substring(0, 10)}'),
                                                        ],
                                                      ),
                                                      trailing: const Icon(Icons.person),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                                  : RefreshIndicator(
                      onRefresh: loadAdminOrders,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: adminOrders.length,
                        itemBuilder: (context, index) {
                          final order = adminOrders[index];
                          final firstArticle = order.articles.isNotEmpty ? order.articles.first as Map<String, dynamic> : {};
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                child: Text('${order.total.toStringAsFixed(0)}FCFA'),
                              ),
                              title: Text('Commande #${order.id}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Acheteur: ${order.utilisateurId} - ${order.nomCompte ?? 'N/A'}'),
                                  Text('Vendeur: ${order.seller ?? 'N/A'} - ${firstArticle['vendeurNom'] ?? 'N/A'} (${firstArticle['vendeurCompte'] ?? ''})'),
                                  Text('Statut: ${order.statut.toUpperCase()} | Vendeur: ${order.statutVendeur?.toUpperCase() ?? 'N/A'}'),
                                  Text('Paiement: ${order.methodePaiement ?? ''} - ${order.numeroPaiement ?? ''}'),
                                  Text('Date: ${order.date}'),
                                ],
                              ),
                              trailing: Text('${order.total.toStringAsFixed(0)} FCFA'),
                              children: [
                                ...order.articles.map<Widget>((art) {
                                  final item = art as Map<String, dynamic>;
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(item['image'] ?? ''),
                                      onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                                    ),
                                    title: Text(item['name'] ?? 'N/A'),
                                    subtitle: Text('${item['quantite'] ?? 1} x ${(item['price'] ?? 0).toStringAsFixed(0)} FCFA'),
                                  );
                                }).toList(),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Livraison: ${order.nomLivraison ?? 'N/A'}, ${order.telLivraison ?? ''}, ${order.villeCommune ?? ''}, ${order.quartier ?? ''}',
                                    style: const TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                                      ? const Center(child: CircularProgressIndicator())
                                      : adminOrders.isEmpty
                                          ? const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                                                  SizedBox(height: 16),
                                                  Text('Aucune commande', style: TextStyle(fontSize: 18)),
                                                ],
                                              ),
                                            )
                                          : RefreshIndicator(
                                              onRefresh: loadAdminOrders,
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: adminOrders.length,
                                                itemBuilder: (context, index) {
                                                  final order = adminOrders[index];
                                                  final firstArticle = order.articles.isNotEmpty ? order.articles.first as Map<String, dynamic> : {};
                                                  return Card(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    child: ExpansionTile(
                                                      leading: CircleAvatar(
                                                        child: Text('${order.total.toStringAsFixed(0)}FCFA'),
                                                      ),
                                                      title: Text('Commande #${order.id}'),
                                                      subtitle: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Acheteur: ${order.utilisateurId} - ${order.nomCompte ?? 'N/A'}'),
                                                          Text('Vendeur: ${order.seller ?? 'N/A'} - ${firstArticle['vendeurNom'] ?? 'N/A'} (${firstArticle['vendeurCompte'] ?? ''})'),
                                                          Text('Statut: ${order.statut.toUpperCase()} | Vendeur: ${order.statutVendeur?.toUpperCase() ?? 'N/A'}'),
                                                          Text('Paiement: ${order.methodePaiement ?? ''} - ${order.numeroPaiement ?? ''}'),
                                                          Text('Date: ${order.date}'),
                                                        ],
                                                      ),
                                                      trailing: Text('${order.total.toStringAsFixed(0)} FCFA'),
                                                      children: [
                                                        ...order.articles.map<Widget>((art) {
                                                          final item = art as Map<String, dynamic>;
                                                          return ListTile(
                                                            dense: true,
                                                            leading: CircleAvatar(
                                                              backgroundImage: NetworkImage(item['image'] ?? ''),
                                                              onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                                                            ),
                                                            title: Text(item['name'] ?? 'N/A'),
                                                            subtitle: Text('${item['quantite'] ?? 1} x ${(item['price'] ?? 0).toStringAsFixed(0)} FCFA'),
                                                          );
                                                        }).toList(),
                                                        Padding(
                                                          padding: const EdgeInsets.all(16),
                                                          child: Text(
                                                            'Livraison: ${order.nomLivraison ?? 'N/A'}, ${order.telLivraison ?? ''}, ${order.villeCommune ?? ''}, ${order.quartier ?? ''}',
                                                            style: const TextStyle(fontStyle: FontStyle.italic),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

