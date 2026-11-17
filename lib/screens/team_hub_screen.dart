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
  // Orange Premium palette (visual only)
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

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
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: const Text(
          'Achat en équipe',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildPromotionCard(),
          const SizedBox(height: 20),
          _buildSectionHeader(
            icon: Icons.group_add_outlined,
            title: 'Créer une équipe',
            subtitle: 'Lancez une nouvelle équipe pour cette promotion.',
          ),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conditions de participation',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
                ),
                const SizedBox(height: 8),
                _buildBullet('Maximum 10 participants par équipe.'),
                _buildBullet('Durée de 15 jours.'),
                _buildBullet('Le bénéficiaire est le créateur de l\'équipe.'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingTeam ? null : _createTeam,
                    icon: _isCreatingTeam
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _white),
                          )
                        : const Icon(Icons.group_add),
                    label: Text(_isCreatingTeam ? 'Création de l\'équipe...' : 'Créer une équipe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orangePrimary,
                      foregroundColor: _white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildSectionHeader(
            icon: Icons.groups_outlined,
            title: 'Rejoindre une équipe',
            subtitle: 'Saisissez le code d\'invitation pour contribuer à une équipe existante.',
          ),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pour contribuer à une équipe existante, saisissez le code d\'invitation :',
                  style: TextStyle(color: _textDark, height: 1.35),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Code d\'invitation',
                    hintText: 'Ex. TEAM-ABC123',
                    errorText: _codeError,
                    labelStyle: const TextStyle(color: _textMuted),
                    hintStyle: const TextStyle(color: _textMuted),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: _textMuted),
                    filled: true,
                    fillColor: _offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _orangePrimary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  onChanged: (_) {
                    if (_codeError != null) setState(() => _codeError = null);
                  },
                  onSubmitted: (_) => _joinByCode(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: (_isCreatingTeam || _isJoiningByCode) ? null : _joinByCode,
                    icon: _isJoiningByCode
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _orangePrimary),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isJoiningByCode ? 'Recherche...' : 'Rejoindre l\'équipe'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orangePrimary,
                      side: const BorderSide(color: _orangePrimary, width: 1.4),
                      backgroundColor: _white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isCreatingTeam || _isJoiningByCode) ? null : _joinByCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orangePrimary,
                      foregroundColor: _white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    child: const Text('Rejoindre l\'équipe'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _orangePrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_offer_outlined, color: _orangePrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Promotion concernée',
                  style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.promotion.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _orangePrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _orangePrimary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: _textMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: _orangePrimary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: _textMuted, height: 1.35))),
        ],
      ),
    );
  }
}
