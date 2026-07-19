// lib/services/chat_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _apiService = ApiService.instance;
  IO.Socket? _socket;
  int? _currentUserId;

  Future<void> init(int currentUserId) async {
    _currentUserId = currentUserId;
    await connectSocket();
  }

  Future<void> connectSocket() async {
    if (_socket != null) return;

_socket = IO.io('https://djassa-backend-imxo.onrender.com', IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Socket connected');
      _socket!.emit('join', _currentUserId);
    });

    _socket!.on('newMessage', (data) {
      print('📨 New message received: $data');
      // Notify via provider or stream
    });

    _socket!.onDisconnect((_) => print('❌ Socket disconnected'));
  }

  Future<List<Message>> getConversation(int otherUserId) async {
    final response = await _apiService.get('/messages/$_currentUserId/$otherUserId');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Message.fromJson(json)).toList();
    }
    throw Exception('Failed to load conversation');
  }

  Future<Message> sendMessage(int receiverId, String text) async {
    final data = {'receiverId': receiverId, 'text': text};
    final response = await _apiService.post('/messages', data: data);
    
    if (response.statusCode == 201) {
      final messageData = response.data['data'];
      final message = Message.fromJson(messageData);
      
      // Emit via socket for real-time
      _socket?.emit('sendMessage', messageData);
      
      return message;
    }
    throw Exception('Failed to send message');
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
  }
}

