// lib/screens/team_chat_screen.dart
// F6-E: Team chat screen (additive). Independent from 1-to-1 ChatScreen.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/team_message.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/team_chat_service.dart';
import '../widgets/back_arrow.dart';

class TeamChatScreen extends StatefulWidget {
  final int teamId;
  final String? teamTitle;
  final bool readOnlyHint; // optional hint; server enforces on POST

  const TeamChatScreen({
    super.key,
    required this.teamId,
    this.teamTitle,
    this.readOnlyHint = false,
  });

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  // Orange Premium palette (visual only)
  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TeamChatService _socketService = TeamChatService();

  final List<TeamMessage> _messages = [];
  final Set<int> _seenIds = <int>{};
  bool _isLoading = true;
  bool _isSending = false;
  bool _joined = false;
  bool _readOnly = false;
  String? _error;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _readOnly = widget.readOnlyHint;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; _error = 'Authentification requise.'; });
      return;
    }
    _currentUserId = user.id;
    await _loadHistory();
    await _connectSocket();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiService.instance.getTeamMessages(widget.teamId);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = response.data;
        final list = (data is Map && data['messages'] is List) ? data['messages'] as List : const [];
        final msgs = <TeamMessage>[];
        for (final item in list) {
          if (item is Map) {
            final m = TeamMessage.fromJson(Map<String, dynamic>.from(item));
            if (_seenIds.add(m.id)) msgs.add(m);
          }
        }
        msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        setState(() { _messages..clear()..addAll(msgs); _isLoading = false; _error = null; });
        _scrollToBottom();
      } else {
        setState(() { _isLoading = false; _error = 'Impossible de charger les messages.'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = _friendlyError(e); });
    }
  }

  Future<void> _connectSocket() async {
    _socketService.onMessage = (msg) {
      if (!mounted) return;
      if (msg.teamId != 0 && msg.teamId != widget.teamId) return;
      if (_seenIds.add(msg.id)) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    };
    _socketService.onJoined = (id) {
      if (!mounted) return;
      if (id == widget.teamId) setState(() { _joined = true; _error = null; });
    };
    _socketService.onJoinError = (code, message) {
      if (!mounted) return;
      setState(() { _joined = false; _error = message.isNotEmpty ? message : 'Accès au chat refusé.'; });
    };
    _socketService.onLeaveError = (_, _) {};
    _socketService.onDisconnected = () {
      if (!mounted) return;
      setState(() => _joined = false);
    };
    _socketService.onConnected = () {};

    final ok = await _socketService.joinTeam(widget.teamId);
    if (!ok && mounted) {
      setState(() => _error = _error ?? 'Connexion au chat indisponible. Vérifiez votre session.');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(pos, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _sendMessage() async {
    if (_readOnly || _isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_currentUserId == null) {
      _showSnack('Authentification requise.', isError: true);
      return;
    }
    setState(() => _isSending = true);
    try {
      final response = await ApiService.instance.sendTeamMessage(widget.teamId, text);
      if (!mounted) return;
      if (response.statusCode == 201) {
        final data = response.data;
        final raw = (data is Map && data['data'] is Map) ? data['data'] as Map : null;
        if (raw != null) {
          final msg = TeamMessage.fromJson(Map<String, dynamic>.from(raw));
          if (_seenIds.add(msg.id)) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        }
        _controller.clear();
        // If server rejected later as read-only is handled by status codes below
      } else {
        _showSnack('Échec de l\'envoi du message.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      final handled = _handleSendError(e);
      if (!handled) _showSnack(_friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _handleSendError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map ? (data['error'] ?? data['message']) : null)?.toString() ?? '';
      if (status == 403) {
        final lower = msg.toLowerCase();
        if (lower.contains('lecture seule') || lower.contains('read')) {
          setState(() => _readOnly = true);
          _showSnack(msg.isNotEmpty ? msg : 'Le chat est en lecture seule pour cette équipe.', isError: false);
          return true;
        }
        _showSnack(msg.isNotEmpty ? msg : 'Accès refusé.', isError: true);
        return true;
      }
      if (status == 401) { _showSnack('Session expirée. Veuillez vous reconnecter.', isError: true); return true; }
      if (status == 400 && msg.isNotEmpty) { _showSnack(msg, isError: true); return true; }
    }
    return false;
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final backend = (data is Map ? (data['error'] ?? data['message']) : null)?.toString();
      if (status == 401) return 'Session expirée ou non autorisée. Veuillez vous reconnecter.';
      if (status == 403) return backend?.isNotEmpty == true ? backend! : 'Accès refusé à cette équipe.';
      if (status == 404) return 'Équipe introuvable.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Erreur réseau. Vérifiez votre connexion Internet.';
      }
      return backend?.isNotEmpty == true ? backend! : 'Erreur lors de la communication avec le serveur.';
    }
    return 'Erreur inattendue.';
  }

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: isError ? Colors.red : null),
    );
  }

  String _formatTime(DateTime dt) {
    try { return DateFormat('HH:mm').format(dt.toLocal()); } catch (_) { return ''; }
  }

  @override
  void dispose() {
    _socketService.disposeForScreen();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.teamTitle?.trim().isNotEmpty == true ? widget.teamTitle! : 'Discussion équipe #${widget.teamId}';
    final statusText = _readOnly ? 'Lecture seule' : (_joined ? 'Connecté' : 'Connexion...');
    final statusColor = _readOnly ? _textMuted : (_joined ? Colors.green : _orangePrimary);
    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: _textDark, fontWeight: FontWeight.w700),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _textDark),
            onPressed: _loadHistory,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _orangePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orangePrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _orangePrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: _textDark, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (_readOnly)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.lock_outline, size: 18, color: _textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette équipe est terminée/expirée : l\'historique est consultable, l\'envoi est désactivé.',
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _orangePrimary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.chat_bubble_outline, size: 52, color: _textMuted),
                            SizedBox(height: 10),
                            Text(
                              'Aucun message pour le moment.',
                              style: TextStyle(color: _textMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final me = _currentUserId != null && m.isSentBy(_currentUserId!);
                          final bubbleColor = me ? _orangePrimary : _white;
                          final bubbleBorder = me ? Colors.transparent : _borderSoft;
                          return Align(
                            alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: bubbleBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!me)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: _orangePrimary.withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.person, size: 12, color: _orangePrimary),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Membre #${m.senderId}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    m.message,
                                    style: TextStyle(
                                      color: me ? _white : _textDark,
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(m.createdAt),
                                    style: TextStyle(
                                      color: me ? _white.withValues(alpha: 0.8) : _textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: _white,
                border: Border(top: BorderSide(color: _borderSoft)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_readOnly,
                      decoration: InputDecoration(
                        hintText: _readOnly ? 'Chat en lecture seule' : 'Tapez votre message...',
                        hintStyle: const TextStyle(color: _textMuted),
                        filled: true,
                        fillColor: _readOnly ? _borderSoft.withValues(alpha: 0.5) : _offWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _borderSoft),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _borderSoft),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _borderSoft),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _orangePrimary, width: 1.5),
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: (_readOnly || _isSending) ? _borderSoft : _orangePrimary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: (_readOnly || _isSending) ? null : _sendMessage,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _white),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: (_readOnly || _isSending) ? _textMuted : _white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
