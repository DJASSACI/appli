import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/promotion_savings.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class MySavingsPlansScreen extends StatefulWidget {
  const MySavingsPlansScreen({super.key});

  @override
  State<MySavingsPlansScreen> createState() => _MySavingsPlansScreenState();
}

class _MySavingsPlansScreenState extends State<MySavingsPlansScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await ApiService.instance.getMySavingsPlans();
      final data = response.data;
      final raw = (data is Map && data['items'] is List)
          ? data['items'] as List
          : (data is List ? data : const []);
      _items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _items.sort((a, b) => _ts(b['createdAt']).compareTo(_ts(a['createdAt'])));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _ts(dynamic v) => v == null ? '' : v.toString();

  String _fmtAmount(dynamic v) {
    if (v == null) return '—';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return '—';
    return '${n.toStringAsFixed(0)} FCFA';
  }

  String _fmtPct(Map<String, dynamic> p) {
    final v = p['progressPercent'] ?? p['progress'];
    if (v == null) return '—';
    var n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return '—';
    if (n <= 1.0 && p['progressPercent'] == null) n = n * 100;
    return '${n.clamp(0.0, 100.0).toStringAsFixed(1)} %';
  }

  double _progress(Map<String, dynamic> p) {
    final v = p['progressPercent'] ?? p['progress'];
    if (v == null) return 0;
    var n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return 0;
    if (n > 1.0 || p['progressPercent'] != null) n = n / 100.0;
    return n.clamp(0.0, 1.0);
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _statusLabel(dynamic status) {
    switch ((status ?? '').toString()) {
      case 'active':
        return 'En cours';
      case 'completed':
        return 'Objectif atteint';
      case 'expired':
        return 'Expiré';
      case 'cancelled':
        return 'Annulé';
      default:
        final s = (status ?? '').toString();
        return s.isEmpty ? '—' : s;
    }
  }

  Color _statusColor(dynamic status) {
    switch ((status ?? '').toString()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'expired':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _contribStatusLabel(dynamic status) {
    switch ((status ?? '').toString()) {
      case 'confirmed':
        return 'Confirmée';
      case 'pending':
      case 'initializing':
        return 'En attente';
      case 'failed':
        return 'Échouée';
      default:
        final s = (status ?? '').toString();
        return s.isEmpty ? '—' : s;
    }
  }

  Color _contribStatusColor(dynamic status) {
    switch ((status ?? '').toString()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
      case 'initializing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _productThumb(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.savings));
    }
    return CircleAvatar(
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
      child: const SizedBox.shrink(),
    );
  }

  void _openPlan(Map<String, dynamic> p) {
    final id = p['planId'];
    if (id == null) return;
    final plan = PromotionSavingsPlan.fromApiResponse({'plan': p});
    context.push('/savings/$id', extra: plan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Mes achats petit à petit'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 160),
                      const Icon(Icons.error_outline, size: 56, color: Colors.red),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Erreur: $_error', textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Icon(Icons.savings_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Center(child: Text('Aucun achat petit à petit')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final p = _items[index];
                          final contribs = (p['contributions'] is List)
                              ? (p['contributions'] as List).whereType<Map>().toList()
                              : const [];
                          final status = p['status'];
                          final saved = p['savedAmount'] ?? p['collectedAmount'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openPlan(p),
                              child: ExpansionTile(
                                leading: _productThumb(p['productImage']?.toString()),
                                title: Text(p['productName']?.toString() ?? 'Produit —', maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Prix cible: ${_fmtAmount(p['targetAmount'])}'),
                                    Text('Économisé: ${_fmtAmount(saved)}  •  Reste: ${_fmtAmount(p['remainingAmount'])}'),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: _progress(p),
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade300,
                                      color: _statusColor(status),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(_fmtPct(p)),
                                        const SizedBox(width: 8),
                                        Text('${p['contributionsCount'] ?? contribs.length} contribution(s)'),
                                        const Spacer(),
                                        Chip(
                                          label: Text(_statusLabel(status), style: const TextStyle(fontSize: 12)),
                                          backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    Text('Création: ${_fmtDate(p['createdAt'])}  •  Dernière contrib.: ${_fmtDate(p['lastContributionAt'])}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Historique des contributions', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  if (contribs.isEmpty)
                                    const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text('—'))
                                  else
                                    ...contribs.map((c) {
                                      final cm = Map<String, dynamic>.from(c);
                                      final cst = cm['paymentStatus'];
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(Icons.payments_outlined, color: _contribStatusColor(cst)),
                                        title: Text(_fmtAmount(cm['amount'])),
                                        subtitle: Text('Date: ${_fmtDate(cm['createdAt'] ?? cm['confirmedAt'])}'),
                                        trailing: Text(_contribStatusLabel(cst), style: TextStyle(color: _contribStatusColor(cst), fontWeight: FontWeight.w600, fontSize: 12)),
                                      );
                                    }),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _openPlan(p),
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Voir le détail'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
