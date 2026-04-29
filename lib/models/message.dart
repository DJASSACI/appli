// lib/models/message.dart
class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String text;
  final String createdAt;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      text: json['text'],
      createdAt: json['createdAt'],
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt,
      'read': read,
    };
  }

  bool get isSentByMe => senderId == receiverId; // Wait for currentUserId in service
}
