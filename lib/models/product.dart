import 'package:flutter/foundation.dart';

class Product {
  final int id;
  final String name;
  final double price;
  final String image;
  final String description;
  final String categorie;
  final dynamic vendeur;
  final String vendeurNom;
  final String vendeurCompte;
  final String vendeurLocalisation;
  final String datePublication;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.categorie,
    required this.vendeur,
    required this.vendeurNom,
    required this.vendeurCompte,
    required this.vendeurLocalisation,
    required this.datePublication,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      vendeur: json['vendeur'],
  vendeurNom: json['vendeurNom'] ?? '',
  vendeurCompte: json['vendeurCompte'] ?? '',
  vendeurLocalisation: json['vendeurLocalisation'] ?? '',
      datePublication: json['datePublication'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'image': image,
    'description': description,
    'categorie': categorie,
    'vendeur': vendeur,
    'vendeurCompte': vendeurCompte,
    'vendeurLocalisation': vendeurLocalisation,
    'isActive': isActive,
  };
}

