import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/team_purchase.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class MyTeamPurchasesScreen extends StatefulWidget {
  const MyTeamPurchasesScreen({super.key});

  @override
  State<MyTeamPurchasesScreen> createState() => _MyTeamPurchasesScreenState();
}

class _MyTeamPurchasesScreenState extends State<MyTeamPurchasesScreen> {
  // Orange Premium palette (visual only)
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

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
      final response = await ApiService.instance.getMyTeamPurchases();
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

  String _fmtPct(Map<String, dynamic> t) {
    final v = t['progressPercent'] ?? t['progress'];
    if (v == null) return '—';
    var n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return '—';
    if (n <= 1.0 && t['progressPercent'] == null) n = n * 100;
    return '${n.clamp(0.0, 100.0).toStringAsFixed(1)} %';
  }

  double _progress(Map<String, dynamic> t) {
    final v = t['progressPercent'] ?? t['progress'];
    if (v == null) return 0;
    var n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return 0;
    if (n > 1.0 || t['progressPercent'] != null) n = n / 100.0;
    return n.clamp(0.0, 1.0);
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _statusLabel(dynamic status) {
    switch ((status ?? '').toString()) {
      case 'open':
        return 'En cours';
      case 'completed':
        return 'Objectif atteint';
      case 'expired':
        return 'Expirée';
      case 'cancelled':
        return 'Annulée';
      default:
        final s = (status ?? '').toString();
        return s.isEmpty ? '—' : s;
    }
  }

  Color _statusColor(dynamic status) {
    switch ((status ?? '').toString()) {
      case 'open':
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

  Widget _productThumb(String? url) {
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        backgroundColor: _orangePrimary.withValues(alpha: 0.1),
        child: const Icon(Icons.groups, color: _orangePrimary),
      );
    }
    return CircleAvatar(
      backgroundColor: _offWhite,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
      child: const SizedBox.shrink(),
    );
  }

  void _openTeam(Map<String, dynamic> t) {
    final id = t['teamId'];
    if (id == null) return;
    final team = TeamPurchase.fromApiResponse({'team': t});
    context.push('/team/$id', extra: team);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: const Text(
          'Mes achats en équipe',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _textDark), onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orangePrimary))
          : _error != null
              ? RefreshIndicator(
                  color: _orangePrimary,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 160),
                      Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Erreur: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textDark),
                        ),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? RefreshIndicator(
                      color: _orangePrimary,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Icon(Icons.groups_outlined, size: 64, color: _textMuted),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Aucun achat en équipe',
                              style: TextStyle(color: _textMuted, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _orangePrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final t = _items[index];
                          final parts = (t['participants'] is List)
                              ? (t['participants'] as List).whereType<Map>().toList()
                              : const [];
                          final status = t['status'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: _white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: _borderSoft),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openTeam(t),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                childrenPadding: EdgeInsets.zero,
                                iconColor: _orangePrimary,
                                collapsedIconColor: _textMuted,
                                shape: const Border(),
                                collapsedShape: const Border(),
                                leading: _productThumb(t['productImage']?.toString()),
                                title: Text(
                                  t['productName']?.toString() ?? 'Produit —',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Créateur: ${t['creatorName'] ?? '—'}',
                                      style: const TextStyle(color: _textMuted, fontSize: 13),
                                    ),
                                    Text(
                                      'Collecté: ${_fmtAmount(t['collectedAmount'])} / ${_fmtAmount(t['targetAmount'])}  •  Reste: ${_fmtAmount(t['remainingAmount'])}',
                                      style: const TextStyle(color: _textDark, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: _progress(t),
                                        minHeight: 8,
                                        backgroundColor: _borderSoft,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _fmtPct(t),
                                          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${t['participantsCount'] ?? parts.length} participant(s)',
                                          style: const TextStyle(color: _textMuted, fontSize: 12),
                                        ),
                                        const Spacer(),
                                        Chip(
                                          label: Text(
                                            _statusLabel(status),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                                          side: BorderSide(color: _statusColor(status).withValues(alpha: 0.25)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Création: ${_fmtDate(t['createdAt'])}  •  Expiration: ${_fmtDate(t['expiresAt'])}',
                                      style: const TextStyle(fontSize: 12, color: _textMuted),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Participants (contributions confirmées)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark),
                                      ),
                                    ),
                                  ),
                                  if (parts.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Text('—', style: TextStyle(color: _textMuted)),
                                    )
                                  else
                                    ...parts.map((p) {
                                      final pm = Map<String, dynamic>.from(p);
                                      return ListTile(
                                        dense: true,
                                        leading: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: _orangePrimary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.person_outline, color: _orangePrimary, size: 18),
                                        ),
                                        title: Text(
                                          pm['name']?.toString() ?? 'Utilisateur #${pm['userId'] ?? '—'}',
                                          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                                        ),
                                        subtitle: Text(
                                          'Rejoint: ${_fmtDate(pm['joinedAt'])}',
                                          style: const TextStyle(color: _textMuted),
                                        ),
                                        trailing: Text(
                                          _fmtAmount(pm['confirmedAmountPaid']),
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark),
                                        ),
                                      );
                                    }),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _openTeam(t),
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Voir le détail'),
                                        style: TextButton.styleFrom(foregroundColor: _orangePrimary),
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
