import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int? _actingId;

  Future<void> _toggleHide(Map<String, dynamic> p, bool hide) async {
    final id = p['id'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hide ? 'Masquer le produit ?' : 'Restaurer le produit ?'),
        content: Text(hide
            ? 'Le produit ne sera plus visible dans le catalogue.'
            : 'Le produit redeviendra visible dans le catalogue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actingId = id);
    try {
      if (hide) {
        await ApiService.instance.delete('/api/products/$id');
      } else {
        await ApiService.instance.put('/api/products/$id/restore', data: {});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hide ? 'Produit masqué' : 'Produit restauré'), backgroundColor: Colors.green),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('/api/products');
      if (response.statusCode == 200) {
        _products = response.data as List<dynamic>;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      final m = p as Map<String, dynamic>;
      return (m['name'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Produits (admin)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un produit...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('Aucun produit'))
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final p = _filtered[index] as Map<String, dynamic>;
                                final id = p['id'];
                                final isActive = p['isActive'] != false;
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    leading: (p['image'] != null)
                                        ? Image.network(p['image'], width: 48, height: 48, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image))
                                        : const Icon(Icons.image),
                                    title: Text(p['name']?.toString() ?? 'N/A'),
                                    subtitle: Text('${p['price'] ?? ''} FCFA - ${p['categorie'] ?? ''} ${isActive ? '' : '(masqué)'}'),
                                    trailing: _actingId == id
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                        : (isActive
                                            ? IconButton(icon: const Icon(Icons.visibility_off), onPressed: () => _toggleHide(p, true))
                                            : IconButton(icon: const Icon(Icons.visibility), onPressed: () => _toggleHide(p, false))),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
