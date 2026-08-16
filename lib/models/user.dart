import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String nom;
  final String prenom;
  final String numero;
  final String address;
  final String role;
  final String dateInscription;
  final String? fcmToken;
  final bool? sellerVerified;
  final String? sellerVerifiedAt;
  final String? sellerVerifiedUntil;


  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.numero,
    required this.address,
    required this.role,
    required this.dateInscription,
    this.fcmToken,
    this.sellerVerified,
    this.sellerVerifiedAt,
    this.sellerVerifiedUntil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      numero: json['numero'] ?? '',
      address: json['address'] ?? '',
      role: json['role'] ?? 'user',
      dateInscription: json['dateInscription'] ?? '',
      fcmToken: json['fcmToken'],
      sellerVerified: (json['sellerVerified'] ?? json['seller_verified']),
      sellerVerifiedAt: (json['sellerVerifiedAt'] ?? json['seller_verified_at']),
      sellerVerifiedUntil: (json['sellerVerifiedUntil'] ?? json['seller_verified_until']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'numero': numero,
    'address': address,
    'role': role,
    'dateInscription': dateInscription,
    if (fcmToken != null) 'fcmToken': fcmToken,
  };
}

