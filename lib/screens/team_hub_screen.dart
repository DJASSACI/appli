import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/promotion.dart';
import '../models/team_purchase.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/back_arrow.dart';

class TeamHubScreen extends StatefulWidget {
  final Promotion promotion;

  const TeamHubScreen({super.key, required this.promotion});

  @override
  State<TeamHubScreen> createState() => _TeamHubScreenState();
}

class _TeamHubScreenState extends State<TeamHubScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCreatingTeam = false;
  bool _isJoiningByCode = false;
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (_isCreatingTeam) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showLoginPrompt();
      return;
    }
    setState(() => _isCreatingTeam = true);
    try {
      final response = await ApiService.instance.createTeam(widget.promotion.id);
      final team = TeamPurchase.fromApiResponse(response.data);
      if (team.teamId <= 0) {
        throw Exception('Réponse du serveur invalide (équipe non créée).');
      }
      if (!mounted) return;
      context.push('/team/${team.teamId}', extra: team);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_teamCreateErrorMessage(e)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCreatingTeam = false);
    }
  }

  Future<void> _joinByCode() async {
    if (_isJoiningByCode) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showLoginPrompt();
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Veuillez saisir un code d\'invitation.');
      return;
    }
    setState(() {
      _isJoiningByCode = true;
      _codeError = null;
    });
    try {
      final response = await ApiService.instance.joinTeamByCode(code);
      final team = TeamPurchase.fromApiResponse(response.data);
      if (team.teamId <= 0) {
        throw Exception('Réponse du serveur invalide.');
      }
      if (!mounted) return;
      _codeController.clear();
      context.push('/team/${team.teamId}', extra: team);
    } catch (e) {
      if (!mounted) return;
      setState(() => _codeError = _joinByCodeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isJoiningByCode = false);
    }
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connectez-vous pour continuer.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Connexion',
          textColor: Colors.white,
          onPressed: () => context.go('/login'),
        ),
      ),
    );
  }

  String _teamCreateErrorMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String? backendMessage;
      if (data is Map) {
        final raw = data['error'] ?? data['message'];
        if (raw is String && raw.trim().isNotEmpty) backendMessage = raw.trim();
      }
      if (status == 401) return 'Session expirée ou non autorisée. Veuillez vous reconnecter.';
      if (status == 404) return 'Promotion introuvable.';
      if (status == 400) return backendMessage ?? 'Impossible de créer l\'équipe (promotion invalide ou indisponible).';
      if (status == 500) return backendMessage ?? 'Erreur serveur. Réessayez plus tard.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
      }
      return backendMessage ?? 'Création de l\'équipe échouée.';
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '').trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Erreur inattendue lors de la création de l\'équipe.';
  }

  String _joinByCodeErrorMessage(Object error) {
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
      if (status == 404) return 'Code invalide ou équipe introuvable. Vérifiez le code d\'invitation.';
      if (status == 400) {
        if (lower.contains('compl')) return 'Cette équipe est complète (10/10 participants).';
        if (lower.contains('expir')) return 'Cette équipe a expiré.';
        if (lower.contains('termin') || lower.contains('ferm')) return 'Cette équipe est terminée ou fermée.';
        if (lower.contains('dispon')) return backendMessage ?? 'Cette équipe n\'est plus disponible.';
        if (lower.contains('code')) return backendMessage ?? 'Code d\'invitation invalide.';
        return backendMessage ?? 'Impossible de rejoindre cette équipe.';
      }
      if (status == 409) return 'Vous participez déjà à cette équipe.';
      if (status == 500) return backendMessage ?? 'Erreur serveur. Réessayez plus tard.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Erreur réseau. Vérifiez votre connexion Internet et réessayez.';
      }
      return backendMessage ?? 'Impossible de rejoindre l\'équipe avec ce code.';
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '').trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Erreur inattendue.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Achat en équipe'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.promotion.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isCreatingTeam ? null : _createTeam,
              icon: _isCreatingTeam
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.group_add),
              label: Text(_isCreatingTeam ? 'Création de l\'équipe...' : 'Créer une équipe'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: (_isCreatingTeam || _isJoiningByCode) ? null : _joinByCode,
              icon: _isJoiningByCode
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.groups),
              label: Text(_isJoiningByCode ? 'Recherche...' : 'Contribuer à une équipe'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pour contribuer à une équipe existante, saisissez le code d\'invitation :',
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Code d\'invitation',
              hintText: 'Ex. TEAM-ABC123',
              border: const OutlineInputBorder(),
              errorText: _codeError,
            ),
            onChanged: (_) {
              if (_codeError != null) setState(() => _codeError = null);
            },
            onSubmitted: (_) => _joinByCode(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_isCreatingTeam || _isJoiningByCode) ? null : _joinByCode,
              child: const Text('Rejoindre l\'équipe'),
            ),
          ),
        ],
      ),
    );
  }
}
