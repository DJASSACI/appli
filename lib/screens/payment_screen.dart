import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String phone;
  final String orderId;
  final String name;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.phone,
    required this.orderId,
    required this.name,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  IO.Socket? socket;
  String status = "en_attente";
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _paymentInitiated = false;

  @override
  void initState() {
    super.initState();

    // Option A: lancer automatiquement le paiement dès l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startPayment();
    });

    socket = IO.io(
      "https://djassa-backend-imxo.onrender.com",
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setTimeout(20000)
          .build(),
    );

    socket!.onConnect((_) {
      print("Socket connecté");
    });

    socket!.onConnectError((data) {
      print("Connect error: $data");
    });

    socket!.onError((data) {
      print("Socket error: $data");
    });

    socket!.onDisconnect((_) {
      print("Socket déconnecté");
    });

    socket!.on("payment_update", (data) {
      if (data["orderId"] == widget.orderId) {
        final newStatus = data["status"];
        setState(() {
          status = newStatus;
        });
        // Arrêter le polling si Socket.IO reçoit une confirmation
        if (newStatus == "confirmed" || newStatus == "failed") {
          _stopPolling();
        }
      }
    });
  }

  Future<void> startPayment() async {
    try {
      // Debug minimal: afficher les paramètres envoyés au backend
      print('GeniusPay init payload => amount=${widget.amount}, phone=${widget.phone}, orderId=${widget.orderId}, name=${widget.name}');

      // Garantir que le token est présent (sinon authenticateToken côté backend renverra une erreur)
      // On ne casse pas le flow : juste un log clair.
      final tokenIsEmpty = (ApiService.instance.toString());
      print('GeniusPay: ApiService token status (check) => $tokenIsEmpty');

      final url = await ApiService.instance.initGeniusPayCheckoutUrl(
        amount: widget.amount,
        phone: widget.phone,
        orderId: widget.orderId,
        name: widget.name,
      );

      if (url.isNotEmpty) {
        _paymentInitiated = true;
        _startPolling();
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      // Ne casse pas l'app : on log l'erreur et on garde le même flow
      print('GeniusPay init failed: $e');

      // Si Dio a une réponse (400), log son body pour savoir la vraie raison côté backend
      // ignore: avoid_print
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        print('GeniusPay init dio status=$status body=$data');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur paiement (400): $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startPolling() {
    if (_pollingTimer != null) return;
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkOrderStatus();
    });
    
    // Vérification immédiate au démarrage
    _checkOrderStatus();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkOrderStatus() async {
    // Éviter les requêtes simultanées
    if (_isPolling) return;
    if (!_paymentInitiated) return;
    if (!mounted) return;

    // Arrêter si déjà confirmé ou échoué
    if (status == "confirmed" || status == "failed") {
      _stopPolling();
      return;
    }

    _isPolling = true;
    try {
      final response = await ApiService.instance.get('/api/orders/${widget.orderId}');
      
      if (!mounted) return;
      
      final order = response.data;
      if (order is Map<String, dynamic> && order.containsKey('status')) {
        final newStatus = order['status'] as String;
        
        if (newStatus != status) {
          setState(() {
            status = newStatus;
          });
          
          // Arrêter le polling si le paiement est confirmé ou définitivement échoué
          if (newStatus == "confirmed" || newStatus == "failed") {
            _stopPolling();
          }
        }
      }
    } catch (e) {
      // Erreur réseau temporaire : ne pas faire planter l'écran, ne pas afficher d'erreur utilisateur
      // Le polling continuera à la prochaine itération
      print('Polling order status failed: $e');
    } finally {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Statut : $status"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _paymentInitiated ? null : startPayment,
            child: Text(_paymentInitiated ? "Paiement en cours..." : "Payer avec GeniusPay"),
          ),
        ],
      ),
    );
  }
}