import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class FollowingScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const FollowingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _following = [];

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.get(
        '/api/users/${widget.userId}/following',
      );
      if (!mounted) return;
      final data = response.data;
      if (data is List) {
        setState(() {
          _following = data.cast<Map<String, dynamic>>();
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
        _error = 'Impossible de charger les abonnements';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: Text('Abonnements de ${widget.userName}'),
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
              onPressed: _loadFollowing,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_following.isEmpty) {
      return const Center(
        child: Text('Aucun abonnement pour le moment'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final user = _following[index];
        final nom = user['nom'] ?? '';
        final prenom = user['prenom'] ?? '';
        final numero = user['numero'] ?? '';
        final sellerVerified = user['sellerVerified'] == true;

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