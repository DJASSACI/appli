import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _init();
  }

  late final Dio _dio;
  String? _token;

  void _init() {
_dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Content-Type': 'application/json'},
    ));


    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Debug full target URL (helps diagnose 404 from wrong baseUrl / wrong backend instance)
        print('🚀 REQUEST: ${options.method} ${options.uri}');
        print('   Authorization header set? ${_token != null && _token!.isNotEmpty}');
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
        // Dio fournit souvent requestOptions.uri pour savoir exactement quel endpoint a échoué.
        final uri = error.requestOptions.uri;
        print('❌ ERROR: ${error.message} | status=$status');
        print('   FAILED URI: $uri');
        handler.next(error);
      },
    ));
  }

  static ApiService get instance => _instance;

  void setToken(String token) {
    _token = token;
  }

  /// Indique si un JWT est présent (utilisé pour gating FCM, sans exposer le token).
  bool hasToken() => _token != null && _token!.isNotEmpty;
  static bool instanceHasToken() => instance.hasToken();

  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String endpoint, {dynamic data, FormData? formData}) async {
    try {
      return await _dio.post(endpoint, data: data ?? formData);
    } catch (e) {
      rethrow;
    }
  }


  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> sendMawaMessage(String message, {String? requestId}) async {
    final response = await _dio.post('/api/mawa/chat', data: {'message': message, if (requestId != null) 'requestId': requestId});
    return response.data['reply'] as String;
  }

  Future<void> registerMawaNotificationRequest(String requestId) async {
    await _dio.post('/api/mawa/notification-request', data: {'requestId': requestId});
  }

static Future<Response> createOrder(Map<String, dynamic> data) async {
    data['notify_url'] = "https://djassa-backend-imxo.onrender.com/api/payment/geniuspay/webhook";
    data['transactionId'] = DateTime.now().millisecondsSinceEpoch.toString();
    return await instance.post(endpointOrders, data: data);
  }

/// Retourne directement l'URL checkout (champ checkout_url) du backend GeniusPay.
  ///
  /// Exemple: https://...
  Future<String> initGeniusPayCheckoutUrl({
    required int amount,
    required String phone,
    required String orderId,
    required String name,
  }) async {
    final response = await _dio.post(
      '/api/payment/geniuspay/init',
      data: {
        "amount": amount,
        "phone": phone,
        "orderId": orderId,
        "name": name,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final url = data['checkout_url'];
      if (url is String && url.isNotEmpty) return url;
    }

    // Si checkout_url est absent, retourner vide pour garder un flux "une seule réponse".
    return '';
  }

  Future<Response> saveCertificationInfo({
    required String boutiqueNom,
    required String rectoCiUrl,
    required String versoCiUrl,
    required String lieu,
    required String photoVendeurUrl,
    required String telephone,
  }) async {
    try {
      return await _dio.post(
        '/api/admin/certification-info',
        data: {
          'boutiqueNom': boutiqueNom,
          'rectoCiUrl': rectoCiUrl,
          'versoCiUrl': versoCiUrl,
          'lieu': lieu,
          'photoVendeurUrl': photoVendeurUrl,
          'telephone': telephone,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // ===== Team purchase (achat en equipe) =====
  // Backend derives creatorId/participantId from JWT; do not send them.

  Future<Response> createTeam(int promotionId) async {
    return await _dio.post(
      '/api/teams',
      data: {
        'promotionId': promotionId,
      },
    );
  }

  Future<Response> getTeam(dynamic teamId) async {
    return await _dio.get('/api/teams/$teamId');
  }

  Future<Response> getTeamStatus(dynamic teamId) async {
    return await _dio.get('/api/teams/$teamId/status');
  }

  Future<Response> joinTeam(dynamic teamId) async {
    return await _dio.post('/api/teams/$teamId/join');
  }

  Future<Response> joinTeamByCode(String invitationCode) async {
    return await _dio.post(
      '/api/teams/join-by-code',
      data: {'invitationCode': invitationCode},
    );
  }

  Future<Response> initTeamContribution(dynamic teamId, num amount) async {
    return await _dio.post(
      '/api/teams/$teamId/contributions/init',
      data: {
        'amount': amount,
      },
    );
  }

  // ===== Team chat (F6-C, additive) — JWT ajouté par l'intercepteur Dio =====
  // Ne jamais envoyer senderId/userId ; identité dérivée du JWT côté serveur.

  Future<Response> getTeamMessages(dynamic teamId) async {
    return await _dio.get('/api/teams/$teamId/messages');
  }

  Future<Response> sendTeamMessage(dynamic teamId, String message) async {
    return await _dio.post(
      '/api/teams/$teamId/messages',
      data: {'message': message},
    );
  }

  // ===== "Acheter petit a petit" (promotion savings, additif) =====
  // JWT ajoute par l'intercepteur Dio. Ne jamais envoyer userId; cible/montants viennent du backend.

  Future<Response> createPromotionSavingsPlan(int promotionId) async {
    return await _dio.post('/api/promotions/$promotionId/savings');
  }

  Future<Response> getPromotionSavingsPlan(dynamic planId) async {
    return await _dio.get('/api/savings/$planId');
  }

  Future<Response> initSavingsContribution(dynamic planId, num amount) async {
    return await _dio.post(
      '/api/savings/$planId/contributions/init',
      data: {'amount': amount},
    );
  }

  // ===== Admin (lecture seule) =====
  Future<Response> getAdminTeamPurchases() async {
    return await _dio.get('/api/admin/teams');
  }

  Future<Response> getAdminSavingsPlans() async {
    return await _dio.get('/api/admin/savings');
  }

  // ===== Utilisateur connecté (lecture seule, filtré par req.user.id backend) =====
  Future<Response> getMyTeamPurchases() async {
    return await _dio.get('/api/my/teams');
  }

  Future<Response> getMySavingsPlans() async {
    return await _dio.get('/api/my/savings');
  }
}
