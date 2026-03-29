import 'package:flutter/foundation.dart';
import 'product.dart';

class Order {
  final int id;
  final int utilisateurId;
  final List<dynamic> articles; // List of {'product': Product, 'quantite': int} or backend format
  final double total;
  final String date;
  final String statut;
  final String methodePaiement;
  final String numeroPaiement;
  final String nomCompte;

  const Order({
    required this.id,
    required this.utilisateurId,
    required this.articles,
    required this.total,
    required this.date,
    required this.statut,
    required this.methodePaiement,
    required this.numeroPaiement,
    required this.nomCompte,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      utilisateurId: json['utilisateurId'] ?? 0,
      articles: List<dynamic>.from(json['articles'] ?? []),
      total: (json['total'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      statut: json['statut'] ?? '',
      methodePaiement: json['methodePaiement'] ?? '',
      numeroPaiement: json['numeroPaiement'] ?? '',
      nomCompte: json['nomCompte'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'utilisateurId': utilisateurId,
    'articles': articles,
    'total': total,
    'date': date,
    'statut': statut,
    'methodePaiement': methodePaiement,
    'numeroPaiement': numeroPaiement,
    'nomCompte': nomCompte,
  };
}

