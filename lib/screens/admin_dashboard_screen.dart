import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';
import '../providers/products_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? stats;
  List<Order> adminOrders = [];
  List<User> adminUsers = [];
  String adminUsersQuery = '';

  bool isLoading = true;
  bool ordersLoading = true;
  bool usersLoading = true;

  bool _showOrdersList = false;
  bool _showUsersList = false;

  bool _certifyingUser = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadStats();
      loadAdminOrders();
      loadAdminUsers();
    });
  }

  List<User> get filteredAdminUsers {
    final query = adminUsersQuery.trim().toLowerCase();
    if (query.isEmpty) return adminUsers;
    return adminUsers.where((u) {
      final fullName = '${u.prenom} ${u.nom}'.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  Future<void> loadAdminUsers() async {
    try {
      setState(() => usersLoading = true);
      final response = await ApiService.instance.get('/api/users');
      debugPrint('GET /api/users status=${response.statusCode}');

      if (!mounted) return;
      setState(() {
        adminUsers = (response.data as List)
            .map((json) => User.fromJson(json))
            .toList();
        usersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        usersLoading = false;
        error = 'Erreur loadAdminUsers: $e';
      });
    }
  }

  Future<void> loadAdminOrders() async {
    try {
      setState(() => ordersLoading = true);
      final ordersProvider =
          Provider.of<OrdersProvider>(context, listen: false);
      await ordersProvider.fetchOrders();

      if (!mounted) return;
      setState(() {
        adminOrders = ordersProvider.orders;
        ordersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => ordersLoading = false);
    }
  }

  Future<void> loadStats() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.instance.get('/api/stats');

      if (!mounted) return;
      setState(() {
        stats = response.data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _certifyUser(BuildContext context, int userId) async {
    if (_certifyingUser) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _certifyingUser = true);
    try {
      // NOTE: endpoint backend met à jour sellerVerified pour l’utilisateur authentifié.
      await ApiService.instance.put(
        '/api/admin/users/$userId/verify-seller',
        data: {},
      );

      await loadAdminUsers();

      // IMPORTANT: recharger la liste des produits côté admin (pour refléter la boutique certifiée).
      // Aussi, sur l’UI admin la liste dépend du ProductsProvider, donc on le recharge ici.
      try {
        final productsProvider =
            Provider.of<ProductsProvider>(context, listen: false);
        await productsProvider.fetchProducts();
      } catch (_) {}

      // Pour que le buyer voie le changement instantanément, la page buyer doit elle aussi
      // écouter/rafraîchir (par ex. via ProductsProvider + RefreshIndicator).
      // Ici, on ne peut pas forcer automatiquement la navigation/refresh du buyer depuis ce screen.


      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Utilisateur certifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erreur certification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _certifyingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
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
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Toggle commandes',
            onPressed: () => setState(() => _showOrdersList = !_showOrdersList),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Toggle utilisateurs',
            onPressed: () => setState(() => _showUsersList = !_showUsersList),
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
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistiques Globales',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
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
                                GestureDetector(
                                  onTap: loadAdminUsers,
                                  child: _StatCard(
                                    title: '1. Total utilisateurs',
                                    subtitle:
                                        'combien de comptes sont enregistrés',
                                    value:
                                        stats!['totalUsers'].toString(),
                                    icon: Icons.people,
                                    color: Colors.blue,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: _StatCard(
                                    title: '2. Total produits',
                                    subtitle:
                                        'tous les produits publiés sur Djassa CI',
                                    value:
                                        stats!['totalProducts'].toString(),
                                    icon: Icons.inventory_2,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            if (_showOrdersList)
                              SizedBox(
                                height: 300,
                                child: ordersLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : adminOrders.isEmpty
                                        ? const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.receipt_long_outlined,
                                                  size: 64,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Aucune commande',
                                                  style: TextStyle(fontSize: 18),
                                                ),
                                              ],
                                            ),
                                          )
                                        : RefreshIndicator(
                                            onRefresh: loadAdminOrders,
                                            child: ListView.builder(
                                              padding:
                                                  const EdgeInsets.all(0.0),
                                              itemCount: adminOrders.length,
                                              itemBuilder: (context, index) {
                                                final order =
                                                    adminOrders[index];
                                                final firstArticle =
                                                    order.articles.isNotEmpty
                                                        ? order.articles.first
                                                            as Map<String, dynamic>
                                                        : <String, dynamic>{};

                                                return Card(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12),
                                                  child: ExpansionTile(
                                                    leading: CircleAvatar(
                                                      child: Text(
                                                        '${order.total.toStringAsFixed(0)}FCFA',
                                                      ),
                                                    ),
                                                    title:
                                                        Text('Commande #${order.id}'),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Acheteur: ${order.utilisateurId} - ${order.nomCompte ?? 'N/A'}',
                                                        ),
                                                        Text(
                                                          'Vendeur: ${order.seller ?? 'N/A'} - ${firstArticle['vendeurNom'] ?? 'N/A'} (${firstArticle['vendeurCompte'] ?? ''})',
                                                        ),
                                                        Text(
                                                          'Statut: ${order.statut.toUpperCase()} | Vendeur: ${order.statutVendeur?.toUpperCase() ?? 'N/A'}',
                                                        ),
                                                        Text(
                                                          'Paiement: ${order.methodePaiement ?? ''} - ${order.numeroPaiement ?? ''}',
                                                        ),
                                                        Text('Date: ${order.date}'),
                                                      ],
                                                    ),
                                                    trailing: Text(
                                                        '${order.total.toStringAsFixed(0)} FCFA'),
                                                    children: [
                                                      ...order.articles
                                                          .map<Widget>((art) {
                                                        final item =
                                                            art
                                                                as Map<String,
                                                                    dynamic>;
                                                        return ListTile(
                                                          dense: true,
                                                          leading:
                                                              CircleAvatar(
                                                            backgroundImage:
                                                                NetworkImage(
                                                              item['image'] ?? '',
                                                            ),
                                                            onBackgroundImageError:
                                                                (_, __) => const Icon(
                                                              Icons.image_not_supported,
                                                            ),
                                                          ),
                                                          title:
                                                              Text(item['name'] ?? 'N/A'),
                                                          subtitle: Text(
                                                            '${item['quantite'] ?? 1} x ${(item['price'] ?? 0).toStringAsFixed(0)} FCFA',
                                                          ),
                                                        );
                                                      }).toList(),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                          16,
                                                        ),
                                                        child: Text(
                                                          'Livraison: ${order.nomLivraison ?? 'N/A'}, ${order.telLivraison ?? ''}, ${order.villeCommune ?? ''}, ${order.quartier ?? ''}',
                                                          style: const TextStyle(
                                                            fontStyle:
                                                                FontStyle.italic,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                              ),
                            if (_showUsersList)
                              SizedBox(
                                height: 300,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Rechercher par nom',
                                        prefixIcon:
                                            Icon(Icons.search),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() => adminUsersQuery = value);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: Builder(
                                        builder: (context) {
                                          if (usersLoading) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          return RefreshIndicator(
                                            onRefresh: loadAdminUsers,
                                            child: filteredAdminUsers.isEmpty
                                                ? const Center(
                                                    child: Text('Aucun utilisateur'),
                                                  )
                                                : ListView.builder(
                                                    padding:
                                                        const EdgeInsets.all(0.0),
                                                    itemCount:
                                                        filteredAdminUsers.length,
                                                    itemBuilder: (context, index) {
                                                      final user =
                                                          filteredAdminUsers[index];
                                                      return Card(
                                                        margin: const EdgeInsets
                                                            .only(bottom: 12),
                                                        child: ListTile(
                                                          leading: CircleAvatar(
                                                            child: Text(user
                                                                .numero
                                                                .substring(
                                                                    user.numero.length - 3)),
                                                          ),
                                                          title: Text(
                                                              '${user.prenom} ${user.nom}'),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text('Numéro: ${user.numero}'),
                                                              Text(
                                                                  'Rôle: ${user.role.toUpperCase()}'),
                                                              Text(
                                                                  'Vendeur certifié: ${user.sellerVerified == true ? 'Oui' : 'Non'}'),
                                                              Text('Adresse: ${user.address}'),
                                                              Text(
                                                                'Inscrit: ${user.dateInscription.substring(0, 10)}',
                                                              ),
                                                            ],
                                                          ),
                                                          trailing:
                                                              ElevatedButton.icon(
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  user.sellerVerified == true
                                                                      ? Colors.grey
                                                                      : Colors.green,
                                                              foregroundColor:
                                                                  Colors.white,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                            ),
                                                            onPressed: (user.sellerVerified == true ||
                                                                    _certifyingUser)
                                                                ? null
                                                                : () => _certifyUser(
                                                                      context,
                                                                      user.id,
                                                                    ),
                                                            icon: const Icon(
                                                              Icons.verified_user,
                                                            ),
                                                            label: Text(
                                                              user.sellerVerified == true
                                                                  ? 'Certifiée'
                                                                  : 'Certifiée',
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
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

