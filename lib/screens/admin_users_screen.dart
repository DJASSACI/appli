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
  List<User> _users = [];

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
    if (_searchQuery.isEmpty) return _users;

    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
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
                Expanded(
                  child: _users.isEmpty
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
                                      Text('Vendeur certifié: ${isVerified ? 'Oui' : 'Non'}'),
                                      Text('Adresse: ${user.address}'),
                                      Text('Inscrit: ${user.dateInscription.substring(0, 10)}'),
                                    ],
                                  ),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isVerified ? Colors.grey : Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: isVerified
                                        ? null
                                        : () => _certifyUser(context, user.id),
                                    icon: const Icon(Icons.verified_user, size: 18),
                                    label: Text(isVerified ? 'Certifiée' : 'Certifier'),
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