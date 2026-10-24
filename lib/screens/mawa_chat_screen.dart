import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/mawa_service.dart';
import '../utils/colors.dart';
import 'package:go_router/go_router.dart';

class MawaChatScreen extends StatefulWidget {
  const MawaChatScreen({super.key});

  @override
  State<MawaChatScreen> createState() => _MawaChatScreenState();
}

class _MawaChatScreenState extends State<MawaChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  bool _firstMessage = true;
  String _userName = '';
  String? _currentRequestId;
  bool _notificationRequested = false;
  final MawaService _mawaService = MawaService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
    _loadHistory();
    _markRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_loading && !_notificationRequested) {
        _notificationRequested = true;
        _currentRequestId ??= DateTime.now().millisecondsSinceEpoch.toString();
        ApiService().registerMawaNotificationRequest(_currentRequestId!).catchError((_) {});
      }
    } else if (state == AppLifecycleState.resumed) {
      _notificationRequested = false;
    }
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_data');
      if (raw != null) {
        final data = jsonDecode(raw);
        final nom = data['nom'] ?? '';
        final prenom = data['prenom'] ?? '';
        final full = ('$prenom $nom').trim();
        if (full.isNotEmpty && mounted) setState(() => _userName = full);
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    final history = await _mawaService.loadHistory();
    if (mounted && history.isNotEmpty) {
      setState(() {
        _messages.addAll(history.map((m) => {'role': m['role'] ?? '', 'text': m['text'] ?? ''}));
        _firstMessage = false;
      });
    }
  }

  Future<void> _markRead() async {
    await _mawaService.markAllRead();
  }

  Future<void> _saveMessage(String role, String text) async {
    await _mawaService.addMessage(role, text);
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (_loading) return;
    _currentRequestId = DateTime.now().millisecondsSinceEpoch.toString();
    _notificationRequested = false;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _loading = true;
    });
    await _saveMessage('user', text);
    final isFirst = _firstMessage;
    _firstMessage = false;
    final lower = text.toLowerCase();
    final isGreeting = lower == 'bonjour' || lower == 'salut' || lower == 'hello' || lower == 'bonsoir';
    if (isFirst && isGreeting) {
      const reply = 'Bonjour ! Je suis MAWA, l’assistant de DJASSACI. Comment puis-je vous aider aujourd’hui ?';
      setState(() {
        _messages.add({'role': 'mawa', 'text': reply});
        _loading = false;
      });
      await _saveMessage('mawa', reply);
      return;
    }
    try {
      final reply = await ApiService().sendMawaMessage(text, requestId: _currentRequestId);
      if (!mounted) return;
      setState(() => _messages.add({'role': 'mawa', 'text': reply}));
      await _saveMessage('mawa', reply);
      await _mawaService.setUnread(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add({'role': 'mawa', 'text': 'Erreur réseau ou serveur. Réessayez.'}));
      await _saveMessage('mawa', 'Erreur réseau ou serveur. Réessayez.');
     } finally {
        if (mounted) setState(() => _loading = false);
        _notificationRequested = false;
      }
  }

  Widget _bubble(Map<String, String> m) {
    final isUser = m['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: CircleAvatar(radius: 14, child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                m['text']!,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final welcomeName = _userName.isEmpty ? '' : ' $_userName';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(radius: 16, child: Text('🤖', style: TextStyle(fontSize: 16))),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('MAWA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Votre assistant DJASSACI', style: TextStyle(fontSize: 11)),
              ],
            ),
            const Spacer(),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _loading ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Bonjour$welcomeName ! Je suis MAWA, l’assistant de DJASSACI. 😊',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Comment puis-je vous aider aujourd’hui ?'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '🛍️ Comment acheter un produit ?',
                      '📦 Comment suivre ma commande ?',
                      '🏪 Comment publier un produit ?',
                      '✅ Comment fonctionne la certification vendeur ?',
                    ].map((s) => ActionChip(label: Text(s), onPressed: () => _send(s))).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _bubble(_messages[i]),
            ),
          ),
          if (_loading && _notificationRequested)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Réponse MAWA en attente', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('MAWA réfléchit…'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : () => _send(),
                  icon: const Icon(Icons.send),
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
