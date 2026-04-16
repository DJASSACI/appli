import 'package:flutter/foundation.dart';
import 'product.dart';

class Order {
  final int id;
  final int utilisateurId;
  final String? seller;  // New: Backend source of truth seller ID
  final List<dynamic> articles; // List of {'product': Product, 'quantite': int} or backend format
  final double total;
  final String date;
  final String statut;
  final String methodePaiement;
  final String numeroPaiement;
  final String nomCompte;
  final String nomLivraison;
  final String telLivraison;
  final String villeCommune;
  final String quartier;
  final String? statutVendeur;
  final double? buyerLat;
  final double? buyerLng;

  const Order({
    required this.id,
    required this.utilisateurId,
    this.seller,
    required this.articles,
    required this.total,
    required this.date,
    required this.statut,
    required this.methodePaiement,
    required this.numeroPaiement,
    required this.nomCompte,
    required this.nomLivraison,
    required this.telLivraison,
    required this.villeCommune,
    required this.quartier,
    this.statutVendeur,
    this.buyerLat,
    this.buyerLng,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      utilisateurId: json['utilisateurId'] ?? 0,
      seller: json['seller']?.toString(),
      articles: List<dynamic>.from(json['articles'] ?? []),
      total: (json['total'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      statut: json['statut'] ?? '',
      methodePaiement: json['methodePaiement'] ?? '',
      numeroPaiement: json['numeroPaiement'] ?? '',
      nomCompte: json['nomCompte'] ?? '',
      nomLivraison: json['nomLivraison'] ?? '',
      telLivraison: json['telLivraison'] ?? '',
      villeCommune: json['villeCommune'] ?? '',
      quartier: json['quartier'] ?? '',
      statutVendeur: json['statutVendeur'],
      buyerLat: json['buyerLat']?.toDouble(),
      buyerLng: json['buyerLng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'utilisateurId': utilisateurId,
    'seller': seller,
    'articles': articles,
    'total': total,
    'date': date,
    'statut': statut,
    'methodePaiement': methodePaiement,
    'numeroPaiement': numeroPaiement,
    'nomCompte': nomCompte,
    'nomLivraison': nomLivraison,
    'telLivraison': telLivraison,
    'villeCommune': villeCommune,
    'quartier': quartier,
    'statutVendeur': statutVendeur,
    'buyerLat': buyerLat,
    'buyerLng': buyerLng,
  };
}


