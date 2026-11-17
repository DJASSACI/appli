import 'dart:io';
import 'package:dio/dio.dart';
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

  static const Color _orangePrimary = Color(0xFFF47721);
  static const Color _textDark = Color(0xFF171717);
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF777777);
  static const Color _borderSoft = Color(0xFFEAE6E1);

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

        // Upload des images avec gestion d'erreur spécifique
        List<String> imageUrls;
        try {
          imageUrls = await CloudinaryStorageService()
              .uploadProductImages(_imageFiles, productName);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec du téléchargement des images. Vérifiez votre connexion Internet et réessayez.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isUploading = false);
          return;
        }

        if (!mounted) return;
        setState(() {
          _imageUrls = imageUrls;
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
        } else {
          if (!mounted) return;
          final backendMessage = response.data?['error'];
          if (backendMessage is String && backendMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(backendMessage), backgroundColor: Colors.red),
            );
          } else if ((response.statusCode ?? 0) >= 500) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants.'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Une erreur inattendue est survenue lors de la publication de votre produit. Réessayez. Si le problème persiste, contactez le support DJASSACI.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } on DioException catch (e) {
        if (!mounted) return;
        setState(() => _isUploading = false);

        String errorMessage;
        if (e.response != null) {
          final backendMessage = e.response?.data?['error'];
          if (backendMessage is String && backendMessage.isNotEmpty) {
            errorMessage = backendMessage;
          } else if (e.response!.statusCode! >= 500) {
            errorMessage = 'Le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants.';
          } else {
            errorMessage = 'Une erreur inattendue est survenue lors de la publication de votre produit. Réessayez. Si le problème persiste, contactez le support DJASSACI.';
          }
        } else {
          errorMessage = 'Impossible de publier votre produit pour le moment. Vérifiez votre connexion Internet et réessayez.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur inattendue est survenue lors de la publication de votre produit. Réessayez. Si le problème persiste, contactez le support DJASSACI.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _textMuted),
      prefixIcon: Icon(icon, color: _orangePrimary),
      filled: true,
      fillColor: _white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _orangePrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _orangePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _orangePrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: _white,
        leading: const BackArrow(),
        title: const Text(
          'Vendre un produit',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: _textDark),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: _textDark),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderSoft),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'Photos',
                icon: Icons.photo_library_outlined,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photos du produit (${_imageFiles.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      if (_imageFiles.isNotEmpty)
                        TextButton.icon(
                          onPressed: _isUploading ? null : _pickImages,
                          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: const Text('Ajouter'),
                          style: TextButton.styleFrom(
                            foregroundColor: _orangePrimary,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_imageFiles.isEmpty)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: _borderSoft, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                          color: _offWhite,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _orangePrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_outlined, size: 28, color: _orangePrimary),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Appuyez pour sélectionner des photos",
                              style: TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Sélection multiple autorisée",
                              style: TextStyle(color: _textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 210,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: _borderSoft),
                              borderRadius: BorderRadius.circular(16),
                              color: _offWhite,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _imageUrls.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          _imageUrls.first,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: _offWhite,
                                              child: const Center(
                                                child: CircularProgressIndicator(color: _orangePrimary),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.file(_imageFiles.first, fit: BoxFit.cover),
                                            );
                                          },
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(_imageFiles.first, fit: BoxFit.cover),
                                      ),
                                if (_isUploading)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _textDark.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Upload...',
                                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _orangePrimary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Principale',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_imageFiles.length > 1)
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imageFiles.length,
                              itemBuilder: (context, index) {
                                final isMain = index == 0;
                                return Container(
                                  width: 74,
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
                                          width: 74,
                                          height: 74,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isMain ? _orangePrimary : _borderSoft,
                                              width: isMain ? 2.5 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            color: _offWhite,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: _imageUrls.length > index
                                                ? Image.network(_imageUrls[index], fit: BoxFit.cover, width: 74, height: 74)
                                                : Image.file(_imageFiles[index], fit: BoxFit.cover, width: 74, height: 74),
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
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE53935),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        if (_imageFiles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickImages,
                            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                            label: const Text('Ajouter d\'autres photos'),
                            style: TextButton.styleFrom(
                              foregroundColor: _orangePrimary,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              _buildSectionCard(
                title: 'Informations produit',
                icon: Icons.inventory_2_outlined,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(labelText: 'Nom produit *', icon: Icons.inventory_outlined),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration(labelText: 'Prix FCFA *', icon: Icons.attach_money_rounded),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration(labelText: 'Catégorie *', icon: Icons.category_outlined),
                    dropdownColor: _white,
                    iconEnabledColor: _orangePrimary,
                    items: _categories.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                    validator: (value) => value == null ? 'Choisir catégorie' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration(labelText: 'Description *', icon: Icons.description_outlined),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Coordonnées & paiement',
                icon: Icons.payments_outlined,
                children: [
                  TextFormField(
                    controller: _vendeurCompteController,
                    decoration: _inputDecoration(
                      labelText: 'Numéro téléphone/WhatsApp vendeur *',
                      icon: Icons.phone_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty || !RegExp(r'^\+?[\d\s-()]+$').hasMatch(value) ? 'Numéro valide requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _paymentAccountController,
                    decoration: _inputDecoration(
                      labelText: 'Numéro compte paiement vendeur (Mobile Money) *',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'Requis pour paiements' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: _inputDecoration(labelText: 'Moyen paiement vendeur *', icon: Icons.payment_outlined),
                    dropdownColor: _white,
                    iconEnabledColor: _orangePrimary,
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
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_isUploading || _imageFiles.isEmpty) ? null : _createProduct,
                  // Numéro compte paiement vendeur: $_paymentAccountController
                  // Moyen paiement vendeur: $_selectedPaymentMethod
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text(
                    'Publier produit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orangePrimary,
                    foregroundColor: _white,
                    disabledBackgroundColor: _borderSoft,
                    disabledForegroundColor: _textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
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

