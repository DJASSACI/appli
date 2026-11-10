class TeamParticipant {
  final int userId;
  final String? joinedAt;
  final double confirmedAmountPaid;

  const TeamParticipant({
    required this.userId,
    this.joinedAt,
    this.confirmedAmountPaid = 0,
  });

  factory TeamParticipant.fromJson(Map<String, dynamic> json) {
    return TeamParticipant(
      userId: _toInt(json['userId']) ?? 0,
      joinedAt: json['joinedAt']?.toString(),
      confirmedAmountPaid: _toDouble(json['confirmedAmountPaid']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        if (joinedAt != null) 'joinedAt': joinedAt,
        'confirmedAmountPaid': confirmedAmountPaid,
      };
}

class TeamPurchase {
  final int teamId;
  final int? promotionId;
  final int? creatorId;
  final int? beneficiaryId;
  final double targetAmount;
  final double collectedAmount;
  final double remainingAmount;
  final List<TeamParticipant> participants;
  final int participantsCount;
  final String? invitationCode;
  final String? createdAt;
  final String? expiresAt;
  final String? status;
  final int? finalOrderId;
  final bool isComplete;
  final int? maxParticipants;

  const TeamPurchase({
    required this.teamId,
    this.promotionId,
    this.creatorId,
    this.beneficiaryId,
    required this.targetAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    this.participants = const [],
    required this.participantsCount,
    this.invitationCode,
    this.createdAt,
    this.expiresAt,
    this.status,
    this.finalOrderId,
    required this.isComplete,
    this.maxParticipants,
  });

  /// Parse team data from either:
  /// - GET /api/teams/:id (wrapper: { team: {...} })
  /// - POST /api/teams (wrapper: { message, team: {...} })
  /// - POST /api/teams/:id/join (wrapper: { message, team: {...} })
  /// - GET /api/teams/:id/status (flat status object)
  factory TeamPurchase.fromApiResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final wrappedTeam = responseData['team'];
      if (wrappedTeam is Map<String, dynamic>) {
        return TeamPurchase.fromJson(wrappedTeam);
      }
      return TeamPurchase.fromJson(responseData);
    }
    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      final wrappedTeam = map['team'];
      if (wrappedTeam is Map<String, dynamic>) {
        return TeamPurchase.fromJson(wrappedTeam);
      }
      if (wrappedTeam is Map) {
        return TeamPurchase.fromJson(Map<String, dynamic>.from(wrappedTeam));
      }
      return TeamPurchase.fromJson(map);
    }
    return const TeamPurchase(
      teamId: 0,
      targetAmount: 0,
      collectedAmount: 0,
      remainingAmount: 0,
      participantsCount: 0,
      isComplete: false,
    );
  }

  factory TeamPurchase.fromJson(Map<String, dynamic> json) {
    final participants = _parseParticipants(json['participants']);
    final targetAmount = _toDouble(json['targetAmount']) ?? 0;
    final collectedAmount = _toDouble(json['collectedAmount']) ?? 0;
    final remainingAmount =
        _toDouble(json['remainingAmount']) ?? _remaining(targetAmount, collectedAmount);
    final participantsCount =
        _toInt(json['participantsCount']) ?? participants.length;
    final isComplete =
        _toBool(json['isComplete']) ?? (targetAmount > 0 && collectedAmount >= targetAmount);

    return TeamPurchase(
      teamId: _toInt(json['teamId']) ?? 0,
      promotionId: _toInt(json['promotionId']),
      creatorId: _toInt(json['creatorId']),
      beneficiaryId: _toInt(json['beneficiaryId']),
      targetAmount: targetAmount,
      collectedAmount: collectedAmount,
      remainingAmount: remainingAmount,
      participants: participants,
      participantsCount: participantsCount,
      invitationCode: json['invitationCode']?.toString(),
      createdAt: json['createdAt']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      status: json['status']?.toString(),
      finalOrderId: _toInt(json['finalOrderId']),
      isComplete: isComplete,
      maxParticipants: _toInt(json['maxParticipants']),
    );
  }

  static List<TeamParticipant> _parseParticipants(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => TeamParticipant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static double _remaining(double target, double collected) {
    final remaining = target - collected;
    return remaining > 0 ? remaining : 0;
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}
