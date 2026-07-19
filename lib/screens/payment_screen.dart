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
        setState(() {
          status = data["status"];
        });
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
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      // Ne casse pas l’app : on log l’erreur et on garde le même flow
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

  @override
  void dispose() {
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
            onPressed: startPayment,
            child: const Text("Payer avec GeniusPay"),
          ),
        ],
      ),
    );
  }
}