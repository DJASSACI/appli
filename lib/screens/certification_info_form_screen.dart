import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_storage_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/back_arrow.dart';

class CertificationInfoFormScreen extends StatefulWidget {
  const CertificationInfoFormScreen({super.key});

  @override
  State<CertificationInfoFormScreen> createState() => _CertificationInfoFormScreenState();
}

class _CertificationInfoFormScreenState extends State<CertificationInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _boutiqueNomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _lieuController = TextEditingController();

  File? _rectoCiImage;
  File? _versoCiImage;
  File? _photoVendeurImage;

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryStorageService _cloudinary = CloudinaryStorageService();

  Future<void> _pickImage(ImageSource source, Function(File) onImageSelected) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        onImageSelected(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceDialog(Function(File) onImageSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, onImageSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCertificationInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rectoCiImage == null || _versoCiImage == null || _photoVendeurImage == null) {
      setState(() => _errorMessage = 'Les 3 images sont obligatoires');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      String? rectoUrl;
      String? versoUrl;
      String? photoVendeurUrl;

      rectoUrl = await _cloudinary.uploadCertificationImage(_rectoCiImage!);
      if (!mounted) return;

      versoUrl = await _cloudinary.uploadCertificationImage(_versoCiImage!);
      if (!mounted) return;

      photoVendeurUrl = await _cloudinary.uploadCertificationImage(_photoVendeurImage!);
      if (!mounted) return;

      setState(() => _isUploading = false);

      final response = await ApiService.instance.saveCertificationInfo(
        boutiqueNom: _boutiqueNomController.text.trim(),
        rectoCiUrl: rectoUrl,
        versoCiUrl: versoUrl,
        lieu: _lieuController.text.trim(),
        photoVendeurUrl: photoVendeurUrl,
        telephone: _telephoneController.text.trim(),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations de certification enregistrées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        context.pop();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  void _clearForm() {
    _boutiqueNomController.clear();
    _telephoneController.clear();
    _lieuController.clear();
    _rectoCiImage = null;
    _versoCiImage = null;
    _photoVendeurImage = null;
  }

  Widget _buildImagePicker(String label, File? image, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(image, fit: BoxFit.cover, width: double.infinity),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez pour ajouter une image',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _boutiqueNomController.dispose();
    _telephoneController.dispose();
    _lieuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Enregistrer une certification'),
      ),
      body: _isLoading && !_isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    TextFormField(
                      controller: _boutiqueNomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la boutique *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Champ obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone joignable *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Champ obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lieuController,
                      decoration: const InputDecoration(
                        labelText: 'Lieu du vendeur *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Champ obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Documents (obligatoires)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildImagePicker(
                      'Recto de la pièce d\'identité *',
                      _rectoCiImage,
                      () => _showImageSourceDialog((img) => setState(() => _rectoCiImage = img)),
                    ),
                    _buildImagePicker(
                      'Verso de la pièce d\'identité *',
                      _versoCiImage,
                      () => _showImageSourceDialog((img) => setState(() => _versoCiImage = img)),
                    ),
                    _buildImagePicker(
                      'Photo du vendeur *',
                      _photoVendeurImage,
                      () => _showImageSourceDialog((img) => setState(() => _photoVendeurImage = img)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _isUploading) ? null : _saveCertificationInfo,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save),
                        label: Text(
                          _isUploading
                              ? 'Téléversement des images...'
                              : _isLoading
                                  ? 'Enregistrement...'
                                  : 'Enregistrer les informations',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}