class AppNotification {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool read;
  final String createdAt;
  final String? sourceEventId;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.read,
    required this.createdAt,
    this.sourceEventId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _toInt(json['id']) ?? 0,
      userId: _toInt(json['userId']) ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
      read: json['read'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      sourceEventId: json['sourceEventId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'read': read,
        'createdAt': createdAt,
        if (sourceEventId != null) 'sourceEventId': sourceEventId,
      };

  DateTime? get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }

  String get formattedDate {
    final dt = createdAtDateTime;
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String? get teamId {
    final v = data['teamId'];
    if (v == null) return null;
    return v.toString();
  }

  String? get planId {
    final v = data['planId'];
    if (v == null) return null;
    return v.toString();
  }

  String? get orderId {
    final v = data['orderId'];
    if (v == null) return null;
    return v.toString();
  }

  String? get routeForData {
    if (teamId != null) return '/team/$teamId';
    if (planId != null) return '/savings/$planId';
    if (orderId != null) return null;
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class NotificationsResponse {
  final List<AppNotification> notifications;
  final int total;
  final int limit;
  final int offset;

  const NotificationsResponse({
    required this.notifications,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List? ?? [];
    return NotificationsResponse(
      notifications: list
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: _toInt(json['total']) ?? 0,
      limit: _toInt(json['limit']) ?? 20,
      offset: _toInt(json['offset']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class UnreadCountResponse {
  final int unreadCount;

  const UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: _toInt(json['unreadCount']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}