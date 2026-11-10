// lib/models/team_message.dart
// F6-E: Team chat message (backend F6-C). Do NOT reuse 1-to-1 Message model.
class TeamMessage {
  final int id;
  final int teamId;
  final int senderId;
  final String message;
  final DateTime createdAt;

  const TeamMessage({
    required this.id,
    required this.teamId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime _asDateTime(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v.toLocal();
    if (v is int) {
      // heuristic: seconds vs milliseconds
      final ms = v < 1000000000000 ? v * 1000 : v;
      return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    final s = v.toString();
    final parsed = DateTime.tryParse(s);
    return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal();
  }

  factory TeamMessage.fromJson(Map<String, dynamic> json) {
    return TeamMessage(
      id: _asInt(json['id']),
      teamId: _asInt(json['teamId']),
      senderId: _asInt(json['senderId']),
      message: (json['message'] ?? '').toString(),
      createdAt: _asDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'senderId': senderId,
      'message': message,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  bool isSentBy(int currentUserId) => senderId == currentUserId;
}
