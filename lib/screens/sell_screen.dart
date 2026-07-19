 import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
// import 'package:form_data/form_data.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cloudinary_storage_service.dart';

import 'package:provider/provider.dart';


import '../utils/constants.dart';
import '../models/product.dart';
import '../widgets/back_arrow.dart';

class SellScreen extends StatefulWidget {

  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
String? _selectedPaymentMethod;
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final _apiService = ApiService();
  final CloudinaryStorageService _storageService = CloudinaryStorageService();

  final _vendeurCompteController = TextEditingController();
  final _paymentAccountController = TextEditingController();

  final List<String> _categories = [
    'Téléphones', 'Ordinateors', 'Audio', 'Accessoires', 'Tablettes', 'Montres', 'TV', 'Électroménager', 'Autre'
  ];




Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;
  if (!mounted) return;

  setState(() {
    _imageFile = File(image.path);
    // Reset URL: l’upload ne se fera qu’au moment du clic sur “Publier produit”.
    _imageUrl = null;
  });
}



  Future<void> _createProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null && _selectedPaymentMethod != null) {
      try {
        debugPrint('🔥 [SELL_SCREEN] DÉBUT CREATE PRODUCT - Image: ${_imageFile?.path ?? "NULL"}');

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilisateur non connecté'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        if (_imageFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: Image requise'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() {
          _isUploading = true;
        });

final productName = _nameController.text.replaceAll(RegExp(r'[^\w\s-]'), '');

final imageUrl = await CloudinaryStorageService()
            .uploadProductImage(_imageFile!, productName);


        if (!mounted) return;
        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });

        debugPrint('📤 [SELL_SCREEN] Using Firebase URL: $imageUrl');

        final response = await _apiService.post('/api/products', data: {
          'name': _nameController.text,
          'price': _priceController.text,
          'description': _descriptionController.text,
          'categorie': _selectedCategory!,
          'vendeurCompte': _vendeurCompteController.text,
          'vendeurLocalisation': user.address,
          'paymentMethod': _selectedPaymentMethod,
          'paymentAccount': _paymentAccountController.text,
          'image': imageUrl,
        });



        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produit publié !'), backgroundColor: Colors.green),
            );
            await Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Vendre un produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Mes produits',
            onPressed: () => context.go('/my-products'),
          ),
          /*
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Mes commandes',
            onPressed: () => context.go('/my-seller-orders'),
          ),
          */
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _imageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                                      )
                                    : Container(color: Colors.grey[300]);
                              },
                            ),
                          )
                        else if (_imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        else
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Aucune image sélectionnée"),
                            ],
                          ),
                        if (_isUploading)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Upload...', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom produit *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Prix FCFA *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? 'Choisir catégorie' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vendeurCompteController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro téléphone/WhatsApp vendeur *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty || !RegExp(r'^\+?[\d\s-()]+$').hasMatch(value) ? 'Numéro valide requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentAccountController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro compte paiement vendeur (Mobile Money) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Requis pour paiements' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Moyen paiement vendeur *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                    DropdownMenuItem(value: 'mtn_money', child: Text('MTN Money')),
                    DropdownMenuItem(value: 'moov_money', child: Text('Moov Money')),
                    DropdownMenuItem(value: 'wave', child: Text('Wave')),
                    DropdownMenuItem(value: 'espece', child: Text('Espèce')),
                  ],
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                  validator: (value) => value == null ? 'Choisir moyen' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: (_isUploading || _imageFile == null) ? null : _createProduct,
                  // Numéro compte paiement vendeur: $_paymentAccountController
                  // Moyen paiement vendeur: $_selectedPaymentMethod
                  icon: const Icon(Icons.sell),
                  label: const Text('Publier produit'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _vendeurCompteController.dispose();
    _paymentAccountController.dispose();
    super.dispose();
  }
}

