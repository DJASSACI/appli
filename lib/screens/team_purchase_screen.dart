import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/team_purchase.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class TeamPurchaseScreen extends StatefulWidget {
  final int teamId;
  final TeamPurchase? initialTeam;

  const TeamPurchaseScreen({
    super.key,
    required this.teamId,
    this.initialTeam,
  });

  @override
  State<TeamPurchaseScreen> createState() => _TeamPurchaseScreenState();
}

class _TeamPurchaseScreenState extends State<TeamPurchaseScreen> {
  TeamPurchase? _team;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isJoining = false;
  bool _isContributing = false;
  String? _error;
  String? _paymentStatusMessage;

  static const int _maxParticipants = 10;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeam != null && widget.initialTeam!.teamId == widget.teamId) {
      _team = widget.initialTeam;
    }
    _loadFullTeam(initial: true);
  }

  Future<void> _loadFullTeam({bool initial = false}) async {
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
      final response = await ApiService.instance.getTeam(widget.teamId);
      final loaded = TeamPurchase.fromApiResponse(response.data);
      if (loaded.teamId <= 0) {
        throw Exception('Réponse du serveur invalide.');
      }
      if (!mounted) return;
      setState(() {
        _team = _mergeKeepingKnownComplete(_team, loaded);
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = _friendlyError(e, notFoundMessage: 'Équipe introuvable.');
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing || _isLoading) return;
    await _loadFullTeam(initial: false);
  }

  TeamPurchase _mergeKeepingKnownComplete(TeamPurchase? previous, TeamPurchase incoming) {
    if (previous == null) return incoming;
    final hasIncomingParticipants = _responseHadParticipants(incoming);
    final keepParticipants = !hasIncomingParticipants && previous.participants.isNotEmpty;
    final keepCount = !hasIncomingParticipants && previous.participants.isNotEmpty
        ? previous.participantsCount
        : incoming.participantsCount;
    final keepCode = (incoming.invitationCode == null || incoming.invitationCode!.trim().isEmpty) &&
            previous.invitationCode != null &&
            previous.invitationCode!.trim().isNotEmpty
        ? previous.invitationCode
        : incoming.invitationCode;

    return TeamPurchase(
      teamId: incoming.teamId != 0 ? incoming.teamId : previous.teamId,
      promotionId: incoming.promotionId ?? previous.promotionId,
      creatorId: incoming.creatorId ?? previous.creatorId,
      beneficiaryId: incoming.beneficiaryId ?? previous.beneficiaryId,
      targetAmount: incoming.targetAmount,
      collectedAmount: incoming.collectedAmount,
      remainingAmount: incoming.remainingAmount,
      participants: keepParticipants ? previous.participants : incoming.participants,
      participantsCount: keepCount,
      invitationCode: keepCode,
      createdAt: incoming.createdAt ?? previous.createdAt,
      expiresAt: incoming.expiresAt ?? previous.expiresAt,
      status: incoming.status ?? previous.status,
      finalOrderId: incoming.finalOrderId ?? previous.finalOrderId,
      isComplete: incoming.isComplete,
      maxParticipants: incoming.maxParticipants ?? previous.maxParticipants,
    );
  }

  bool _responseHadParticipants(TeamPurchase incoming) {
    // getTeam (/api/teams/:id) returns full view including participants; status may be partial.
    // Our TeamPurchase.fromJson defaults participants to []. When full response gives participants,
    // list may be non-empty or empty-but-present is indistinguishable here; we treat non-empty as present.
    // Full endpoint always includes participants key; safest: preserve previous only when incoming
    // looks like status-only (no invitation code and no participants) AND previous had data.
    return incoming.participants.isNotEmpty || (incoming.invitationCode != null && incoming.invitationCode!.isNotEmpty);
  }

  Future<void> _joinTeam() async {
    final team = _team;
    if (team == null || _isJoining) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isJoining = true);
    try {
      final response = await ApiService.instance.joinTeam(widget.teamId);
      final updated = TeamPurchase.fromApiResponse(response.data);
      if (!mounted) return;
      setState(() {
        _team = _mergeKeepingKnownComplete(_team, updated.teamId > 0 ? updated : team);
      });
      // Reload complete info
      await _loadFullTeam(initial: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez rejoint l\'équipe.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e, notFoundMessage: 'Équipe introuvable.')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connectez-vous pour rejoindre cette équipe.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Connexion',
          textColor: Colors.white,
          onPressed: () => context.go('/login'),
        ),
      ),
    );
  }

  Future<void> _showContributionDialog() async {
    final team = _team;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (team == null || _isContributing) return;
    if (!auth.isAuthenticated) {
      _showLoginPrompt();
      return;
    }
    if (_isCompleted(team)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objectif atteint / équipe terminée. Les contributions ne sont plus possibles.')),
      );
      return;
    }
    if (_isExpired(team) || !_isActiveOpen(team)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette équipe n\'accepte plus de contributions.')),
      );
      return;
    }
    final userId = auth.user?.id;
    final isParticipant = userId != null && team.participants.any((p) => p.userId == userId);
    if (!isParticipant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez d\'abord rejoindre l\'équipe avant de contribuer.')),
      );
      return;
    }

    final controller = TextEditingController();
    final remaining = team.remainingAmount > 0 ? team.remainingAmount : 0.0;
    final suggestions = <int>[500, 1000, 2000, 5000]
        .where((s) => s <= remaining.ceil() || remaining <= 0)
        .toList();

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          String? errorText;
          void submit() {
            final raw = controller.text.trim().replaceAll(' ', '').replaceAll(',', '.');
            if (raw.isEmpty) {
              setDialogState(() => errorText = 'Montant obligatoire.');
              return;
            }
            final parsed = double.tryParse(raw);
            if (parsed == null || !parsed.isFinite) {
              setDialogState(() => errorText = 'Montant numérique invalide.');
              return;
            }
            if (parsed <= 0) {
              setDialogState(() => errorText = 'Le montant doit être strictement supérieur à zéro.');
              return;
            }
            if (remaining > 0 && parsed > remaining) {
              setDialogState(() => errorText = 'Le montant dépasse le montant restant affiché (${_formatPrice(remaining)}). Le backend reste l\'autorité finale.');
              return;
            }
            Navigator.of(dialogContext).pop(parsed);
          }

          return AlertDialog(
            title: const Text('Contribuer à l\'équipe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant restant affiché : ${_formatPrice(remaining)}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Les montants proposés sont des suggestions. Le backend vérifie le montant disponible final.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions
                          .map((s) => ActionChip(
                                label: Text(_formatPrice(s.toDouble())),
                                onPressed: () {
                                  controller.text = s.toString();
                                  setDialogState(() => errorText = null);
                                },
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      hintText: 'Ex. 1000',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() => errorText = null),
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
              ElevatedButton(onPressed: submit, child: const Text('Continuer')),
            ],
          );
        },
      ),
    );

    controller.dispose();
    if (amount == null || !mounted) return;
    await _confirmBeneficiaryAndPay(amount);
  }

  Future<void> _confirmBeneficiaryAndPay(double amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Information importante'),
        content: Text(
          'Votre contribution de ${_formatPrice(amount)} participe au financement de l\'achat de cette promotion. Le bénéficiaire final du produit est le créateur de l\'équipe. Votre contribution ne vous donne pas de droit de propriété individuel sur le produit.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('J\'ai compris, payer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _initAndOpenContribution(amount);
  }

  Future<void> _initAndOpenContribution(double amount) async {
    if (_isContributing) return;
    setState(() {
      _isContributing = true;
      _paymentStatusMessage = null;
    });
    try {
      final response = await ApiService.instance.initTeamContribution(widget.teamId, amount);
      final data = response.data;
      if (data is! Map) {
        throw Exception('Réponse du serveur invalide.');
      }
      final map = Map<String, dynamic>.from(data);
      final success = map['success'] == true;
      final checkoutUrlRaw = map['checkout_url'];
      final checkoutUrl = checkoutUrlRaw is String ? checkoutUrlRaw.trim() : '';
      final returnedTeamId = map['teamId'];
      final returnedAmount = map['amount'];

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
      if (returnedTeamId != null && returnedTeamId.toString() != widget.teamId.toString()) {
        throw Exception('Réponse de paiement incohérente (équipe).');
      }
      if (returnedAmount != null) {
        final ra = returnedAmount is num ? returnedAmount.toDouble() : double.tryParse(returnedAmount.toString());
        if (ra != null && (ra - amount).abs() > 0.01) {
          throw Exception('Le montant retourné par le serveur est incohérent.');
        }
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
        await _loadFullTeam(initial: false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _paymentStatusMessage = 'Paiement en attente de confirmation. Actualisez le statut pour voir le montant confirmé par le backend.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page de paiement ouverte. La confirmation dépend du webhook backend.')),
      );
      await _loadFullTeam(initial: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_contributionErrorMessage(e)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isContributing = false);
    }
  }

  String _contributionErrorMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String? backendMessage;
      if (data is Map) {
        final raw = data['error'] ?? data['message'];
        if (raw is String && raw.trim().isNotEmpty) backendMessage = raw.trim();
      }
      final lower = (backendMessage ?? '').toLowerCase();
      if (status == 401) return 'Session expirée ou non autorisée. Veuillez vous reconnecter.';
      if (status == 403) return 'Vous devez être membre de l\'équipe pour contribuer.';
      if (status == 404) return 'Équipe introuvable.';
      if (status == 400) {
        if (lower.contains('montant') && (lower.contains('rest') || lower.contains('sup') || lower.contains('dispon') || lower.contains('réserv'))) {
          return backendMessage ?? 'Montant supérieur au montant disponible (contributions en attente prises en compte).';
        }
        if (lower.contains('expir')) return 'Cette équipe a expiré.';
        if (lower.contains('termin') || lower.contains('complét') || lower.contains('atteint')) return 'Cette équipe est terminée ou son objectif est atteint.';
        return backendMessage ?? 'Contribution refusée. Vérifiez le montant et l\'état de l\'équipe.';
      }
      if (status == 409) return backendMessage ?? 'Conflit lors de l\'initialisation. Actualisez et réessayez.';
      if (status == 500) return backendMessage ?? 'Erreur serveur lors de l\'initialisation du paiement.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
      }
      return backendMessage ?? 'Initialisation de la contribution échouée.';
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '').trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Erreur inattendue lors de la contribution.';
  }

  Future<void> _copyInvitationCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code d\'invitation copié')),
    );
  }

  String _friendlyError(Object error, {String notFoundMessage = 'Équipe introuvable.'}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String? backendMessage;
      if (data is Map) {
        final raw = data['error'] ?? data['message'];
        if (raw is String && raw.trim().isNotEmpty) backendMessage = raw.trim();
      }
      if (status == 401) {
        return 'Session expirée ou non autorisée. Veuillez vous reconnecter.';
      }
      if (status == 404) return notFoundMessage;
      if (status == 409) {
        return 'Vous participez déjà à cette équipe.';
      }
      if (status == 400) {
        final lower = (backendMessage ?? '').toLowerCase();
        if (lower.contains('expir')) return 'Cette équipe a expiré.';
        if (lower.contains('compl')) return 'Cette équipe est complète.';
        if (lower.contains('dispon') || lower.contains('non disponible')) {
          return backendMessage ?? 'Cette équipe n\'est plus disponible.';
        }
        return backendMessage ?? 'Action impossible pour cette équipe.';
      }
      if (status == 500) {
        return backendMessage ?? 'Erreur serveur. Réessayez plus tard.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
      }
      return backendMessage ?? 'Erreur lors de la communication avec le serveur.';
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
    if (iso == null || iso.trim().isEmpty) return 'Indisponible';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  String _timeRemaining(String? expiresAt) {
    if (expiresAt == null || expiresAt.trim().isEmpty) return 'Indisponible';
    final dt = DateTime.tryParse(expiresAt);
    if (dt == null) return 'Indisponible';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Équipe expirée';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '$days j $hours h';
    if (hours > 0) return '$hours h $minutes min';
    return '$minutes min';
  }

  String _statusLabel(TeamPurchase team) {
    final status = (team.status ?? '').toLowerCase();
    final expired = _isExpired(team);
    if (status == 'completed') return 'Terminée';
    if (status == 'expired' || expired) return 'Expirée';
    if (status == 'cancelled') return 'Terminée';
    return 'En cours';
  }

  bool _isExpired(TeamPurchase team) {
    final status = (team.status ?? '').toLowerCase();
    if (status == 'expired') return true;
    if (team.expiresAt == null) return false;
    final dt = DateTime.tryParse(team.expiresAt!);
    if (dt == null) return false;
    return !dt.isAfter(DateTime.now());
  }

  bool _isCompleted(TeamPurchase team) {
    final status = (team.status ?? '').toLowerCase();
    return status == 'completed' || status == 'cancelled';
  }

  bool _isActiveOpen(TeamPurchase team) {
    final status = (team.status ?? '').toLowerCase();
    if (_isCompleted(team)) return false;
    if (_isExpired(team)) return false;
    return status == 'open' || status.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final team = _team;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Achat en équipe'),
        actions: [
          IconButton(
            onPressed: (_isLoading || _isRefreshing) ? null : _refresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(auth, team),
    );
  }

  Widget _buildBody(AuthProvider auth, TeamPurchase? team) {
    if (_isLoading && team == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && team == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadFullTeam,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (team == null) {
      return const Center(child: Text('Équipe introuvable.'));
    }
    return RefreshIndicator(
      onRefresh: () => _loadFullTeam(initial: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_paymentStatusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _notice(_paymentStatusMessage!),
            ),
          _sectionTitle('Informations générales'),
          _infoCard([
            _row('Identifiant équipe', '#${team.teamId}'),
            _row(
              'Promotion',
              team.promotionId != null ? 'Promotion #${team.promotionId}' : 'Indisponible',
            ),
            _row(
              'Créateur',
              team.creatorId != null ? 'Utilisateur #${team.creatorId}' : 'Indisponible',
            ),
            _row(
              'Bénéficiaire',
              'Créateur de l\'équipe${team.beneficiaryId != null ? ' (utilisateur #${team.beneficiaryId})' : ''}',
            ),
          ]),
          const SizedBox(height: 12),
          _buildInvitationCode(team),
          const SizedBox(height: 16),
          _sectionTitle('Informations financières'),
          _buildFinancialCard(team),
          const SizedBox(height: 16),
          _sectionTitle('Participants'),
          _buildParticipantsCard(team, auth),
          const SizedBox(height: 16),
          _sectionTitle('Durée'),
          _infoCard([
            _row('Création', _formatDate(team.createdAt)),
            _row('Expiration', _formatDate(team.expiresAt)),
            _row('Temps restant', _timeRemaining(team.expiresAt)),
          ]),
          const SizedBox(height: 16),
          _sectionTitle('Statut'),
          _buildStatusCard(team),
          const SizedBox(height: 20),
          _buildActionArea(team, auth),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _openTeamChat(TeamPurchase team) {
    final completed = _isCompleted(team);
    final expired = _isExpired(team);
    context.push(
      '/team/${team.teamId}/chat',
      extra: {
        'teamTitle': 'Équipe #${team.teamId}',
        'readOnly': completed || expired,
      },
    );
  }

  Widget _teamChatButton(TeamPurchase team) {
    return OutlinedButton.icon(
      onPressed: () => _openTeamChat(team),
      icon: const Icon(Icons.forum_outlined),
      label: const Text('Discuter en équipe'),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
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
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCode(TeamPurchase team) {
    final code = team.invitationCode;
    final hasCode = code != null && code.trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Code d\'invitation', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            if (hasCode) ...[
              SelectableText(
                code,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _copyInvitationCode(code),
                icon: const Icon(Icons.copy),
                label: const Text('Copier le code'),
              ),
            ] else
              const Text('Code d\'invitation indisponible'),
              const SizedBox(height: 6),
              const Text(
                'Partagez ce code pour permettre à un participant de retrouver et rejoindre cette équipe.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(TeamPurchase team) {
    final target = team.targetAmount;
    final collected = team.collectedAmount;
    final remaining = team.remainingAmount;
    final progress = target > 0 ? (collected / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Montant cible', _formatPrice(target)),
            _row('Montant confirmé collecté', _formatPrice(collected)),
            _row('Montant restant', _formatPrice(remaining)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 6),
            Text('Progression : $percent %', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text(
              'Le montant collecté correspond aux contributions confirmées.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(TeamPurchase team, AuthProvider auth) {
    final max = team.maxParticipants ?? _maxParticipants;
    final count = team.participantsCount;
    final participants = team.participants;
    final showList = participants.isNotEmpty || team.invitationCode != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Participants', '$count / $max (créateur compris)'),
            if (count >= max)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('10/10 participants', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            if (!showList && count > 0)
              const Text('Informations des participants indisponibles')
            else if (participants.isEmpty)
              const Text('Aucun participant affichable')
            else
              ...participants.map((p) {
                final isCreator = team.creatorId != null && p.userId == team.creatorId;
                final isMe = auth.user != null && auth.user!.id == p.userId;
                final labels = <String>[
                  if (isCreator) 'Créateur',
                  if (isMe) 'Vous',
                ];
                final paid = p.confirmedAmountPaid;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text('Utilisateur #${p.userId}${labels.isNotEmpty ? ' (${labels.join(', ')})' : ''}'),
                  subtitle: Text(
                    'Montant payé (confirmé) : ${_formatPrice(paid)}'
                    '${p.joinedAt != null ? '\nInscription : ${_formatDate(p.joinedAt)}' : ''}',
                  ),
                  isThreeLine: p.joinedAt != null,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(TeamPurchase team) {
    final label = _statusLabel(team);
    Color color;
    String detail;
    if (label == 'Terminée') {
      color = Colors.green;
      detail = _isCompleted(team) ? 'Équipe terminée / objectif atteint selon le statut du serveur.' : 'Équipe terminée.';
    } else if (label == 'Expirée') {
      color = Colors.red;
      detail = 'Cette équipe a expiré.';
    } else {
      color = Colors.deepOrange;
      detail = 'Équipe en cours.';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(TeamPurchase team, AuthProvider auth) {
    final max = team.maxParticipants ?? _maxParticipants;
    final userId = auth.user?.id;
    final isCreator = userId != null && team.creatorId != null && userId == team.creatorId;
    final isParticipant = userId != null && team.participants.any((p) => p.userId == userId);
    final completed = _isCompleted(team);
    final expired = _isExpired(team);
    final full = team.participantsCount >= max;
    final active = _isActiveOpen(team);

    if (completed) {
      if (isParticipant) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _notice('Objectif atteint ! Le montant cible a été atteint. Les informations restent consultables. Le backend est responsable de la commande finale du créateur.'),
            const SizedBox(height: 10),
            _teamChatButton(team),
          ],
        );
      }
      return _notice('Objectif atteint ! Le montant cible a été atteint. Les informations restent consultables. Le backend est responsable de la commande finale du créateur.');
    }
    if (expired) {
      if (isParticipant) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _notice('Cette équipe a expiré. Il n\'est plus possible de rejoindre ou de cotiser.'),
            const SizedBox(height: 10),
            _teamChatButton(team),
          ],
        );
      }
      return _notice('Cette équipe a expiré. Il n\'est plus possible de rejoindre ou de cotiser.');
    }
    if (!auth.isAuthenticated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _notice('Connectez-vous pour rejoindre cette équipe.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => context.go('/login'), child: const Text('Se connecter')),
        ],
      );
    }
    if (isParticipant) {
      final canContribute = active && !expired && !completed && team.remainingAmount > 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _notice(isCreator
              ? 'Vous êtes le créateur de cette équipe. Vous pouvez aussi contribuer en tant que participant.'
              : 'Vous participez déjà à cette équipe.'),
          const SizedBox(height: 10),
          if (canContribute)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isContributing ? null : _showContributionDialog,
                icon: _isContributing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.volunteer_activism),
                label: Text(_isContributing ? 'Initialisation...' : 'Contribuer à l\'équipe'),
              ),
            )
          else if (team.remainingAmount <= 0)
            _notice('Aucun montant restant à contribuer selon les informations actuelles. Actualisez pour confirmation du backend.')
          else
            _notice('Les contributions ne sont pas disponibles pour cette équipe pour le moment.'),
          const SizedBox(height: 8),
          _teamChatButton(team),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (_isRefreshing || _isLoading) ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser le statut'),
          ),
        ],
      );
    }
    if (full) {
      return _notice('Cette équipe est complète (10/10 participants).');
    }
    if (!active) {
      return _notice('Cette équipe n\'est pas disponible pour l\'inscription.');
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isJoining ? null : _joinTeam,
        icon: _isJoining
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.group_add),
        label: Text(_isJoining ? 'Inscription...' : 'Rejoindre l\'équipe'),
      ),
    );
  }

  Widget _notice(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
