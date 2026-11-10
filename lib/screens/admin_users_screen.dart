import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/back_arrow.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'tous';
  List<User> _users = [];
  final Set<int> _actionLoading = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.instance.get('/api/users');
      if (response.statusCode == 200) {
        _users = (response.data as List).map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<User> _getFilteredUsers() {
    var filtered = _users;
    if (_roleFilter != 'tous') {
      filtered = filtered.where((u) => u.role == _roleFilter).toList();
    }
    if (_searchQuery.isEmpty) return filtered;

    final query = _searchQuery.toLowerCase();
    return filtered.where((user) {
      final fullName = '${user.prenom} ${user.nom}'.toLowerCase();
      final phone = user.numero.toLowerCase();
      return fullName.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Tous les utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: DropdownButtonFormField<String>(
                     value: _roleFilter,
                     decoration: const InputDecoration(
                       labelText: 'Filtrer par rôle',
                       border: OutlineInputBorder(),
                     ),
                     items: const [
                       DropdownMenuItem(value: 'tous', child: Text('Tous')),
                       DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                       DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                     ],
                     onChanged: (v) => setState(() => _roleFilter = v ?? 'tous'),
                   ),
                 ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _getFilteredUsers().isEmpty
                       ? RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 200),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Aucun utilisateur', style: TextStyle(fontSize: 18)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _getFilteredUsers().length,
                            itemBuilder: (context, index) {
                              final user = _getFilteredUsers()[index];
                              final isVerified = user.sellerVerified == true;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(user.numero.length >= 3
                                        ? user.numero.substring(user.numero.length - 3)
                                        : user.numero),
                                  ),
                                  title: Text('${user.prenom} ${user.nom}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Numéro: ${user.numero}'),
                                      Text('Rôle: ${user.role.toUpperCase()}'),
                                      Text('Statut: ${user.suspended == true ? 'Suspendu' : 'Actif'}'),
                                      Text('Vendeur certifié: ${isVerified ? 'Oui' : 'Non'}'),
                                      Text('Adresse: ${user.address}'),
                                      Text('Inscrit: ${user.dateInscription.substring(0, 10)}'),
                                    ],
                                  ),
                                   trailing: SizedBox(
                                     width: 130,
                                     child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                       ElevatedButton.icon(
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: isVerified ? Colors.grey : Colors.green,
                                           foregroundColor: Colors.white,
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                         ),
                                         onPressed: isVerified
                                             ? null
                                             : () => _certifyUser(context, user.id),
                                         icon: const Icon(Icons.verified_user, size: 16),
                                         label: Text(isVerified ? 'Certifiée' : 'Certifier', style: const TextStyle(fontSize: 11)),
                                       ),
                                       const SizedBox(height: 4),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: user.suspended == true ? Colors.blue : Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          onPressed: _actionLoading.contains(user.id)
                                              ? null
                                              : (user.suspended == true
                                                  ? () => _reactivateUser(context, user.id)
                                                  : () => _suspendUser(context, user.id)),
                                          icon: _actionLoading.contains(user.id)
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : Icon(user.suspended == true ? Icons.lock_open : Icons.lock, size: 16),
                                          label: Text(user.suspended == true ? 'Réactiver' : 'Suspendre', style: const TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _suspendUser(BuildContext context, int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspendre le compte ?'),
        content: const Text('L’utilisateur ne pourra plus accéder aux routes protégées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Suspendre')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionLoading.add(userId));
    try {
      final response = await ApiService.instance.put('/api/admin/users/$userId/suspend', data: {});
      debugPrint('Suspend response: ${response.statusCode} ${response.data}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte suspendu'), backgroundColor: Colors.orange));
      await _loadUsers();
    } catch (e) {
      debugPrint('Suspend error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _actionLoading.remove(userId));
    }
  }

  Future<void> _reactivateUser(BuildContext context, int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réactiver le compte ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Réactiver')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionLoading.add(userId));
    try {
      final response = await ApiService.instance.put('/api/admin/users/$userId/reactivate', data: {});
      debugPrint('Reactivate response: ${response.statusCode} ${response.data}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte réactivé'), backgroundColor: Colors.green));
      await _loadUsers();
    } catch (e) {
      debugPrint('Reactivate error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _actionLoading.remove(userId));
    }
  }

  Future<void> _certifyUser(BuildContext context, int userId) async {
    try {
      await ApiService.instance.put(
        '/api/admin/users/$userId/verify-seller',
        data: {},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur certifié avec succès'), backgroundColor: Colors.green),
      );
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur certification: $e'), backgroundColor: Colors.red),
      );
    }
  }
}