import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cloudinary_storage_service.dart';
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
  List<File> _imageFiles = [];
  List<String> _imageUrls = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final _apiService = ApiService();

  final _vendeurCompteController = TextEditingController();
  final _paymentAccountController = TextEditingController();

  final List<String> _categories = [
    'Téléphones',
    'Ordinateurs',
    'Tablettes',
    'Audio',
    'TV',
    'Électroménager',
    'Accessoires',
    'Montres',
    'Vêtements',
    'Chaussures',
    'Sacs',
    'Beauté & Cosmétiques',
    'Bijoux',
    'Maison & Décoration',
    'Meubles',
    'Cuisine',
    'Jardin & Extérieur',
    'Sports & Loisirs',
    'Jeux & Jouets',
    'Livres & Fournitures',
    'Bébé & Enfant',
    'Auto & Moto',
    'Immobilier',
    'Services',
    'Alimentation',
    'Animaux',
    'Instruments de musique',
    'Matériel professionnel',
    'Électronique',
    'Autre'
  ];


Future<void> _pickImages() async {
  final List<XFile> images = await _picker.pickMultiImage();

  if (images.isEmpty) return;
  if (!mounted) return;

  final newFiles = images.map((xfile) => File(xfile.path)).toList();
  setState(() {
    _imageFiles.addAll(newFiles);
    // Reset URLs: upload will happen when clicking "Publier produit".
    _imageUrls = [];
  });
}

void _removeImage(int index) {
  setState(() {
    _imageFiles.removeAt(index);
    if (index < _imageUrls.length) {
      _imageUrls.removeAt(index);
    }
  });
}

Future<void> _createProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null && _selectedPaymentMethod != null) {
      if (_imageFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Au moins une image requise'), backgroundColor: Colors.red),
        );
        return;
      }
      try {
        debugPrint('🔥 [SELL_SCREEN] DÉBUT CREATE PRODUCT - Images: ${_imageFiles.length}');

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

        setState(() {
          _isUploading = true;
        });

        final productName = _nameController.text.replaceAll(RegExp(r'[^\w\s-]'), '');

        final imageUrls = await CloudinaryStorageService()
            .uploadProductImages(_imageFiles, productName);

        if (!mounted) return;
        setState(() {
          _imageUrls = imageUrls;
          _isUploading = false;
        });

        debugPrint('📤 [SELL_SCREEN] Using Cloudinary URLs: $imageUrls');

        final mainImage = imageUrls.isNotEmpty ? imageUrls.first : '';

        final response = await _apiService.post('/api/products', data: {
          'name': _nameController.text,
          'price': _priceController.text,
          'description': _descriptionController.text,
          'categorie': _selectedCategory!,
          'vendeurCompte': _vendeurCompteController.text,
          'vendeurLocalisation': user.address,
          'paymentMethod': _selectedPaymentMethod,
          'paymentAccount': _paymentAccountController.text,
          'image': mainImage,
          'images': imageUrls,
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
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
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
                // Section images
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Photos du produit (${_imageFiles.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        if (_imageFiles.isNotEmpty)
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickImages,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Ajouter'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_imageFiles.isEmpty)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 2, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Appuyez pour sélectionner des photos", style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 4),
                              Text("Sélection multiple autorisée", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Image principale (grande)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _imageUrls.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            _imageUrls.first,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(child: CircularProgressIndicator()),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(_imageFiles.first, fit: BoxFit.cover),
                                              );
                                            },
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(_imageFiles.first, fit: BoxFit.cover),
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
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Principale', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Miniatures
                          if (_imageFiles.length > 1)
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _imageFiles.length,
                                itemBuilder: (context, index) {
                                  final isMain = index == 0;
                                  return Container(
                                    width: 70,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // Déplacer l'image sélectionnée en première position (principale)
                                            setState(() {
                                              final file = _imageFiles.removeAt(index);
                                              _imageFiles.insert(0, file);
                                              if (index < _imageUrls.length) {
                                                final url = _imageUrls.removeAt(index);
                                                _imageUrls.insert(0, url);
                                              }
                                            });
                                          },
                                          child: Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isMain ? Colors.blue : Colors.transparent,
                                                width: 3,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: _imageUrls.length > index
                                                  ? Image.network(_imageUrls[index], fit: BoxFit.cover, width: 70, height: 70)
                                                  : Image.file(_imageFiles[index], fit: BoxFit.cover, width: 70, height: 70),
                                            ),
                                          ),
                                        ),
                                        if (!isMain)
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_imageFiles.isNotEmpty)
                            TextButton.icon(
                              onPressed: _isUploading ? null : _pickImages,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Ajouter d\'autres photos'),
                            ),
                        ],
                      ),
                  ],
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
                  onPressed: (_isUploading || _imageFiles.isEmpty) ? null : _createProduct,
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

