// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // currentUserId managed privately in ChatService

  Future<void> initChat(int currentUserId) async {
    await _chatService.init(currentUserId);
  }

  Future<void> loadConversation(int otherUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _chatService.getConversation(otherUserId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int receiverId, String text) async {
    try {
      final message = await _chatService.sendMessage(receiverId, text);
      _messages.add(message);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void addIncomingMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}

