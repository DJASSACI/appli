import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class FollowersScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _followers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.get(
        '/api/users/${widget.userId}/followers',
      );
      if (!mounted) return;
      final data = response.data;
      if (data is List) {
        setState(() {
          _followers = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Format de réponse inattendu';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les abonnés';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: Text('Abonnés de ${widget.userName}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowers,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_followers.isEmpty) {
      return const Center(
        child: Text('Aucun abonné pour le moment'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final follower = _followers[index];
        final nom = follower['nom'] ?? '';
        final prenom = follower['prenom'] ?? '';
        final numero = follower['numero'] ?? '';
        final sellerVerified = follower['sellerVerified'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text('$prenom $nom'.trim()),
            subtitle: Text(numero),
            trailing: sellerVerified
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Certifié',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}