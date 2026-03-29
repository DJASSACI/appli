import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String nom;
  final String prenom;
  final String numero;
  final String address;
  final String role;
  final String dateInscription;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.numero,
    required this.address,
    required this.role,
    required this.dateInscription,
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
  };
}

