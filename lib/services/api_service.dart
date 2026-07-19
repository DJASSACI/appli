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


}
