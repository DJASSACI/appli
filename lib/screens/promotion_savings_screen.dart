import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotion_savings.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class PromotionSavingsScreen extends StatefulWidget {
  final int planId;
  final PromotionSavingsPlan? initialPlan;

  const PromotionSavingsScreen({
    super.key,
    required this.planId,
    this.initialPlan,
  });

  @override
  State<PromotionSavingsScreen> createState() => _PromotionSavingsScreenState();
}

class _PromotionSavingsScreenState extends State<PromotionSavingsScreen> {
  PromotionSavingsPlan? _plan;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isContributing = false;
  String? _error;
  String? _paymentStatusMessage;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null && widget.initialPlan!.planId == widget.planId) {
      _plan = widget.initialPlan;
    }
    _loadPlan(initial: true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan({bool initial = false}) async {
    if (!mounted) return;
    setState(() {
      if (initial) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
      _error = null;
    });
    try {
      final response = await ApiService.instance.getPromotionSavingsPlan(widget.planId);
      final loaded = PromotionSavingsPlan.fromApiResponse(response.data);
      if (loaded.planId <= 0) {
        throw Exception('Réponse du serveur invalide.');
      }
      if (!mounted) return;
      setState(() {
        _plan = loaded;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        _handleAuthError();
        return;
      }
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = _friendlyLoadError(e);
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing || _isLoading) return;
    setState(() => _paymentStatusMessage = null);
    await _loadPlan(initial: false);
  }

  void _handleAuthError() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session expirée ou accès refusé. Veuillez vous reconnecter.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Connexion',
          textColor: Colors.white,
          onPressed: () => context.go('/login'),
        ),
      ),
    );
  }

  String _friendlyLoadError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String? backendMessage;
      if (data is Map) {
        final raw = data['error'] ?? data['message'];
        if (raw is String && raw.trim().isNotEmpty) backendMessage = raw.trim();
      }
      if (status == 404) return 'Objectif introuvable ou inaccessible.';
      if (status == 401 || status == 403) return 'Accès refusé. Veuillez vous reconnecter.';
      if (status == 500) return backendMessage ?? 'Erreur serveur. Réessayez plus tard.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
      }
      return backendMessage ?? 'Erreur lors du chargement.';
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '').trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Erreur inattendue.';
  }

  String _formatPrice(double value) {
    final rounded = value.isFinite ? value.round() : 0;
    final text = rounded.toString();
    return '${text.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  Color _statusColor(String status) {
    switch (status) {
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
      case 'initializing':
        return Icons.hourglass_top;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _contribute() async {
    final plan = _plan;
    if (plan == null || _isContributing) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    if (plan.isCompleted) return;

    final raw = _amountController.text.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (raw.isEmpty) {
      _showError('Veuillez saisir un montant.');
      return;
    }
    final amount = double.tryParse(raw);
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showError('Le montant doit être strictement supérieur à zéro.');
      return;
    }
    final remaining = plan.remainingAmount > 0 ? plan.remainingAmount : 0.0;
    if (remaining > 0 && amount > remaining) {
      _showError('Le montant ne doit pas dépasser le montant restant affiché (${_formatPrice(remaining)}). Le backend reste l\'autorité finale.');
      return;
    }

    await _initAndOpenContribution(amount);
  }

  Future<void> _initAndOpenContribution(double amount) async {
    if (_isContributing) return;
    setState(() {
      _isContributing = true;
      _paymentStatusMessage = null;
    });
    try {
      final response = await ApiService.instance.initSavingsContribution(widget.planId, amount);
      final data = response.data;
      if (data is! Map) {
        throw Exception('Réponse du serveur invalide.');
      }
      final map = Map<String, dynamic>.from(data);
      final success = map['success'] == true;
      final checkoutUrlRaw = map['checkout_url'];
      final checkoutUrl = checkoutUrlRaw is String ? checkoutUrlRaw.trim() : '';

      if (!success) {
        final msg = map['error'] ?? map['message'] ?? 'Initialisation du paiement échouée.';
        throw Exception(msg.toString());
      }
      if (checkoutUrl.isEmpty) {
        throw Exception('URL GeniusPay absente ou invalide.');
      }
      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        throw Exception('URL GeniusPay absente ou invalide.');
      }

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec d\'ouverture de GeniusPay. Aucune contribution n\'a été confirmée. Réessayez après vérification.'),
            backgroundColor: Colors.red,
          ),
        );
        await _loadPlan(initial: false);
        return;
      }

      if (!mounted) return;
      _amountController.clear();
      setState(() {
        _paymentStatusMessage = 'Paiement en attente de confirmation. Actualisez le statut pour voir le montant confirmé par le backend.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page de paiement ouverte. La confirmation dépend du webhook backend.')),
      );
      await _loadPlan(initial: false);
    } catch (e) {
      if (!mounted) return;
      await _handleContributionError(e);
    } finally {
      if (mounted) setState(() => _isContributing = false);
    }
  }

  Future<void> _handleContributionError(Object error) async {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String? backendMessage;
      String? reference;
      if (data is Map) {
        final raw = data['error'] ?? data['message'];
        if (raw is String && raw.trim().isNotEmpty) backendMessage = raw.trim();
        final ref = data['reference'];
        if (ref != null && ref.toString().trim().isNotEmpty) reference = ref.toString().trim();
      }
      if (status == 401 || status == 403) {
        _handleAuthError();
        return;
      }
      if (status == 404) {
        _showError('Plan introuvable ou inaccessible.');
        return;
      }
      if (status == 400) {
        _showError(backendMessage ?? 'Contribution refusée. Vérifiez le montant et l\'état de l\'objectif.');
        await _loadPlan(initial: false);
        return;
      }
      if (status == 502) {
        _showError(backendMessage ?? 'L\'initialisation du paiement a échoué. Réessayez plus tard.');
        return;
      }
      if (status == 500 && reference != null) {
        setState(() {
          _paymentStatusMessage = 'Le statut de ce paiement doit être vérifié (réf. $reference). Ne relancez pas immédiatement la contribution ; actualisez le statut.';
        });
        _showError(backendMessage ?? 'Enregistrement local incertain. Vérifiez le statut avant de réessayer.');
        await _loadPlan(initial: false);
        return;
      }
      if (status == 500) {
        _showError(backendMessage ?? 'Erreur serveur. Réessayez plus tard.');
        return;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        _showError('Erreur réseau. Vérifiez votre connexion puis actualisez le statut de l\'objectif.');
        return;
      }
      _showError(backendMessage ?? 'Erreur lors de l\'initialisation de la contribution.');
      return;
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '').trim();
      if (msg.isNotEmpty) {
        _showError(msg);
        return;
      }
    }
    _showError('Erreur inattendue.');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Acheter petit à petit'),
        actions: [
          IconButton(
            onPressed: (_isLoading || _isRefreshing) ? null : _refresh,
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser le statut',
          ),
        ],
      ),
      body: _buildBody(plan),
    );
  }

  Widget _buildBody(PromotionSavingsPlan? plan) {
    if (_isLoading && plan == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && plan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadPlan(initial: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (plan == null) {
      return const Center(child: Text('Objectif introuvable.'));
    }
    return RefreshIndicator(
      onRefresh: () => _loadPlan(initial: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          if (_paymentStatusMessage != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: _notice(_paymentStatusMessage!, color: Colors.orange.shade50)),
          if (plan.isCompleted) _buildCompletedBanner(plan),
          _buildSummaryCard(plan),
          const SizedBox(height: 16),
          _buildContributionForm(plan),
          const SizedBox(height: 16),
          _buildHistory(plan),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner(PromotionSavingsPlan plan) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.celebration, color: Colors.green),
              SizedBox(width: 8),
              Text('Objectif atteint !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('La commande finale a été créée.'),
          if (plan.finalOrderId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Commande #${plan.finalOrderId}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PromotionSavingsPlan plan) {
    final percent = (plan.progress * 100).clamp(0, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.promotionName != null && plan.promotionName!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(plan.promotionName!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            _row('Montant cible', _formatPrice(plan.targetAmount)),
            _row('Montant déjà confirmé', _formatPrice(plan.collectedAmount)),
            _row('Montant restant', _formatPrice(plan.remainingAmount)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: plan.progress.clamp(0.0, 1.0), minHeight: 10),
            const SizedBox(height: 6),
            Text('${percent.toStringAsFixed(1)} % atteint', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Le montant confirmé correspond aux contributions validées par le webhook backend.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionForm(PromotionSavingsPlan plan) {
    if (plan.isCompleted) {
      return _notice('L\'objectif est atteint. Aucune nouvelle contribution n\'est possible.', color: Colors.grey.shade100);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contribuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
              decoration: InputDecoration(
                labelText: 'Montant (FCFA)',
                hintText: 'Ex. 1000',
                border: const OutlineInputBorder(),
                helperText: 'Restant affiché : ${_formatPrice(plan.remainingAmount)}',
              ),
              enabled: !_isContributing,
              onSubmitted: (_) => _contribute(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isContributing ? null : _contribute,
                    icon: _isContributing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.volunteer_activism),
                    label: Text(_isContributing ? 'Initialisation...' : 'Contribuer'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: (_isRefreshing || _isLoading) ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser le statut'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(PromotionSavingsPlan plan) {
    final items = plan.contributions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historique des contributions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Aucune contribution pour le moment.')
            else
              ...items.map((c) {
                final color = _statusColor(c.paymentStatus);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_statusIcon(c.paymentStatus), color: color),
                  title: Text(_formatPrice(c.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${c.statusLabel}'
                    '${c.createdAt != null && c.createdAt!.isNotEmpty ? ' · ${_formatDate(c.createdAt)}' : ''}'
                    '${c.isConfirmed && c.confirmedAt != null ? '\nConfirmée : ${_formatDate(c.confirmedAt)}' : ''}',
                  ),
                  isThreeLine: c.isConfirmed && c.confirmedAt != null,
                  trailing: Text(c.statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _notice(String text, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color ?? Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Text(text),
    );
  }
}
