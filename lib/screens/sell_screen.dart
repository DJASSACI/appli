import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/product.dart';

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
  final ImagePicker _picker = ImagePicker();
  final _apiService = ApiService();
  final _vendeurCompteController = TextEditingController();
  final _paymentAccountController = TextEditingController();

  final List<String> _categories = [
    'Téléphones', 'Ordinateors', 'Audio', 'Accessoires', 'Tablettes', 'Montres', 'TV', 'Électroménager', 'Autre'
  ];


  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _createProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null && _selectedPaymentMethod != null) {
      try {
        String imageData = 'https://via.placeholder.com/400x400?text=Product';
        if (_imageFile != null) {
          final bytes = await _imageFile!.readAsBytes();
          imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }

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

        final response = await _apiService.post('/api/products', data: {
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'image': imageData,
          'description': _descriptionController.text,
          'categorie': _selectedCategory!,
          'vendeur': user.id,
          'vendeurNom': '${user.nom} ${user.prenom}',
          'vendeurCompte': _vendeurCompteController.text,
          'vendeurLocalisation': user.address,
          'paymentMethod': _selectedPaymentMethod,
          'paymentAccount': _paymentAccountController.text,
        });

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produit publié !'), backgroundColor: Colors.green),
            );
            await Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
            context.go('/my-products');
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
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Mes commandes',
            onPressed: () => context.go('/my-seller-orders'),
          ),
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
                    child: _imageFile == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Choisir photo galerie'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
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
                  value: _selectedCategory,
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
                  onPressed: _createProduct,
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

