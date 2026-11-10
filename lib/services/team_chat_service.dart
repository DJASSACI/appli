// lib/services/team_chat_service.dart
// F6-E: Independent team chat Socket.IO service (additive).
// MUST NOT touch/replace 1-to-1 ChatService/ChatProvider/ChatScreen.
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/team_message.dart';

typedef TeamChatMessageHandler = void Function(TeamMessage message);
typedef TeamChatJoinedHandler = void Function(int teamId);
typedef TeamChatErrorHandler = void Function(String code, String message);

class TeamChatService {
  static const String _backendUrl = 'https://djassa-backend-imxo.onrender.com';
  static const _storage = FlutterSecureStorage();

  IO.Socket? _socket;
  String? _jwt;
  int? _activeTeamId;
  bool _disposed = false;

  TeamChatMessageHandler? onMessage;
  TeamChatJoinedHandler? onJoined;
  TeamChatJoinedHandler? onLeft;
  TeamChatErrorHandler? onJoinError;
  TeamChatErrorHandler? onLeaveError;
  void Function()? onDisconnected;
  void Function()? onConnected;

  bool get isConnected => _socket?.connected == true;
  int? get activeTeamId => _activeTeamId;

  Future<String?> _readJwt() async {
    if (_jwt != null && _jwt!.trim().isNotEmpty) return _jwt;
    try {
      final t = await _storage.read(key: 'token');
      if (t != null && t.trim().isNotEmpty) {
        _jwt = t.trim();
        return _jwt;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> connect({String? token}) async {
    if (_disposed) return false;
    if (token != null && token.trim().isNotEmpty) _jwt = token.trim();
    final jwt = await _readJwt();
    if (jwt == null || jwt.isEmpty) return false;

    // Reuse existing live socket but ensure auth is current for future ops.
    if (_socket != null) {
      try {
        _socket!.auth = {'token': jwt};
      } catch (_) {}
      if (_socket!.connected == true) return true;
      try {
        _socket!.connect();
      } catch (_) {}
      return true; // connection in progress; handlers already bound
    }

    _socket = IO.io(
      _backendUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': jwt}) // F6-D: handshake.auth.token (never send userId)
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1500)
          .build(),
    );

    _bindEvents();
    _socket!.connect();
    return true;
  }

  void _bindEvents() {
    final s = _socket;
    if (s == null) return;
    // Avoid duplicate handlers
    s.off('connect');
    s.off('disconnect');
    s.off('team_message');
    s.off('team_joined');
    s.off('team_left');
    s.off('team_join_error');
    s.off('team_leave_error');

    s.onConnect((_) async {
      if (_disposed) return;
      onConnected?.call();
      // Rejoin active room after reconnect
      final teamId = _activeTeamId;
      final jwt = await _readJwt();
      if (teamId != null && jwt != null && jwt.isNotEmpty) {
        try {
          s.auth = {'token': jwt};
        } catch (_) {}
        s.emit('join_team', {'teamId': teamId});
      }
    });

    s.onDisconnect((_) {
      if (_disposed) return;
      onDisconnected?.call();
    });

    s.on('team_message', (data) {
      if (_disposed) return;
      try {
        if (data is Map) {
          final msg = TeamMessage.fromJson(Map<String, dynamic>.from(data));
          if (msg.id > 0 || msg.message.isNotEmpty) {
            onMessage?.call(msg);
          }
        }
      } catch (_) {}
    });

    s.on('team_joined', (data) {
      if (_disposed) return;
      try {
        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        final id = _asInt(map['teamId']) ?? _activeTeamId;
        if (id != null && id > 0) onJoined?.call(id);
      } catch (_) {}
    });

    s.on('team_left', (data) {
      if (_disposed) return;
      try {
        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        final id = _asInt(map['teamId']) ?? _activeTeamId;
        if (id != null && id > 0) onLeft?.call(id);
      } catch (_) {}
    });

    s.on('team_join_error', (data) => _handleError(data, onJoinError));
    s.on('team_leave_error', (data) => _handleError(data, onLeaveError));
  }

  void _handleError(dynamic data, TeamChatErrorHandler? cb) {
    if (_disposed) return;
    try {
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final code = (map['error'] ?? 'error').toString();
      final message = (map['message'] ?? 'Erreur de chat équipe').toString();
      cb?.call(code, message);
    } catch (_) {
      cb?.call('error', 'Erreur de chat équipe');
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Future<bool> joinTeam(int teamId) async {
    if (_disposed) return false;
    final ok = await connect();
    if (!ok) return false;
    final prev = _activeTeamId;
    if (prev != null && prev != teamId) {
      leaveTeam(prev);
    }
    _activeTeamId = teamId;
    final s = _socket;
    if (s == null) return false;
    if (s.connected == true) {
      s.emit('join_team', {'teamId': teamId});
    }
    // if not yet connected, onConnect will rejoin _activeTeamId
    return true;
  }

  void leaveTeam([int? teamId]) {
    final id = teamId ?? _activeTeamId;
    final s = _socket;
    if (id != null && s != null && s.connected == true) {
      try {
        s.emit('leave_team', {'teamId': id});
      } catch (_) {}
    }
    if (teamId == null || teamId == _activeTeamId) {
      _activeTeamId = null;
    }
  }

  /// Call when leaving the team chat screen. Does NOT touch 1-to-1 ChatService.
  void disposeForScreen() {
    leaveTeam();
    onMessage = null;
    onJoined = null;
    onLeft = null;
    onJoinError = null;
    onLeaveError = null;
    onDisconnected = null;
    onConnected = null;
  }

  /// Full disconnect (optional). Keep separate from 1-to-1 singleton.
  void disconnect() {
    _disposed = true;
    leaveTeam();
    try {
      final s = _socket;
      if (s != null) {
        s.off('connect');
        s.off('disconnect');
        s.off('team_message');
        s.off('team_joined');
        s.off('team_left');
        s.off('team_join_error');
        s.off('team_leave_error');
        s.disconnect();
        s.dispose();
      }
    } catch (_) {}
    _socket = null;
    _activeTeamId = null;
  }
}
