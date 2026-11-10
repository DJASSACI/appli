class PromotionSavingsContribution {
  final int paymentId;
  final int? planId;
  final double amount;
  final String paymentStatus;
  final String? transactionReference;
  final String? createdAt;
  final String? confirmedAt;
  final String? failedAt;

  const PromotionSavingsContribution({
    required this.paymentId,
    this.planId,
    required this.amount,
    required this.paymentStatus,
    this.transactionReference,
    this.createdAt,
    this.confirmedAt,
    this.failedAt,
  });

  factory PromotionSavingsContribution.fromJson(Map<String, dynamic> json) {
    return PromotionSavingsContribution(
      paymentId: _toInt(json['paymentId']) ?? 0,
      planId: _toInt(json['planId']),
      amount: _toDouble(json['amount']) ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'unknown',
      transactionReference: json['transactionReference']?.toString(),
      createdAt: json['createdAt']?.toString(),
      confirmedAt: json['confirmedAt']?.toString(),
      failedAt: json['failedAt']?.toString(),
    );
  }

  bool get isConfirmed => paymentStatus == 'confirmed';
  bool get isPending => paymentStatus == 'pending' || paymentStatus == 'initializing';
  bool get isFailed => paymentStatus == 'failed';

  String get statusLabel {
    switch (paymentStatus) {
      case 'confirmed':
        return 'Confirmée';
      case 'pending':
      case 'initializing':
        return 'En attente';
      case 'failed':
        return 'Échouée';
      default:
        return paymentStatus;
    }
  }
}

class PromotionSavingsPlan {
  final int planId;
  final int? userId;
  final int? promotionId;
  final String? promotionName;
  final double targetAmount;
  final double collectedAmount;
  final double remainingAmount;
  final double progress;
  final bool isComplete;
  final String status;
  final int? finalOrderId;
  final String? createdAt;
  final String? updatedAt;
  final String? completedAt;
  final List<PromotionSavingsContribution> contributions;

  const PromotionSavingsPlan({
    required this.planId,
    this.userId,
    this.promotionId,
    this.promotionName,
    required this.targetAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.progress,
    required this.isComplete,
    required this.status,
    this.finalOrderId,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.contributions = const [],
  });

  /// Parse plan from backend responses:
  /// - POST /api/promotions/:id/savings -> { success, created, plan: {...} }
  /// - GET /api/savings/:id -> { success, plan: {...} }
  /// Also accepts a bare plan map.
  factory PromotionSavingsPlan.fromApiResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final wrapped = responseData['plan'];
      if (wrapped is Map<String, dynamic>) {
        return PromotionSavingsPlan.fromJson(wrapped);
      }
      if (wrapped is Map) {
        return PromotionSavingsPlan.fromJson(Map<String, dynamic>.from(wrapped));
      }
      return PromotionSavingsPlan.fromJson(responseData);
    }
    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      final wrapped = map['plan'];
      if (wrapped is Map<String, dynamic>) {
        return PromotionSavingsPlan.fromJson(wrapped);
      }
      if (wrapped is Map) {
        return PromotionSavingsPlan.fromJson(Map<String, dynamic>.from(wrapped));
      }
      return PromotionSavingsPlan.fromJson(map);
    }
    return const PromotionSavingsPlan(
      planId: 0,
      targetAmount: 0,
      collectedAmount: 0,
      remainingAmount: 0,
      progress: 0,
      isComplete: false,
      status: 'unknown',
    );
  }

  factory PromotionSavingsPlan.fromJson(Map<String, dynamic> json) {
    final contributions = _parseContributions(json['contributions']);
    final targetAmount = _toDouble(json['targetAmount']) ?? 0;
    final collectedAmount = _toDouble(json['collectedAmount']) ?? 0;
    final remainingAmount =
        _toDouble(json['remainingAmount']) ?? _remaining(targetAmount, collectedAmount);
    final rawProgress = _toDouble(json['progress']);
    final progress = rawProgress != null
        ? rawProgress.clamp(0.0, 1.0)
        : (targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0);
    final isComplete =
        _toBool(json['isComplete']) ?? (targetAmount > 0 && collectedAmount >= targetAmount);

    return PromotionSavingsPlan(
      planId: _toInt(json['planId']) ?? 0,
      userId: _toInt(json['userId']),
      promotionId: _toInt(json['promotionId']),
      promotionName: json['promotionName']?.toString(),
      targetAmount: targetAmount,
      collectedAmount: collectedAmount,
      remainingAmount: remainingAmount,
      progress: progress,
      isComplete: isComplete,
      status: json['status']?.toString() ?? (isComplete ? 'completed' : 'active'),
      finalOrderId: _toInt(json['finalOrderId']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      contributions: contributions,
    );
  }

  bool get isCompleted => isComplete || status == 'completed' || finalOrderId != null;

  static List<PromotionSavingsContribution> _parseContributions(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => PromotionSavingsContribution.fromJson(Map<String, dynamic>.from(e)))
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
