import 'package:flutter/foundation.dart';

class Promotion {
  final int id;
  final String name;
  final double price;
  final String image;
  final String description;
  final String categorie;
  final int discountPercent;
  final double discountedPrice;
  final String datePublication;
  final bool isActive;

  const Promotion({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.categorie,
    required this.discountPercent,
    required this.discountedPrice,
    required this.datePublication,
    required this.isActive,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] ?? 0).toDouble();
    final discount = (json['discountPercent'] ?? 0).toInt();
    final discountedPrice = price * (1 - discount / 100);

    return Promotion(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: price,
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      discountPercent: discount,
      discountedPrice: discountedPrice,
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
    'discountPercent': discountPercent,
    'discountedPrice': discountedPrice,
    'datePublication': datePublication,
    'isActive': isActive,
  };
}