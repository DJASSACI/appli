import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cloudinary_storage_service.dart';
import '../services/api_service.dart';
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
  String? _statusMessage;
  Map<String, dynamic>? _existingCertification;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryStorageService _cloudinary = CloudinaryStorageService();

  @override
  void initState() {
    super.initState();
    _loadExistingCertification();
  }

  Future<void> _loadExistingCertification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.instance.getUserCertificationInfo();
      if (!mounted) return;
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _existingCertification = data;
          _boutiqueNomController.text = data['boutiqueNom'] ?? '';
          _telephoneController.text = data['telephone'] ?? '';
          _lieuController.text = data['lieu'] ?? '';
          _statusMessage = _getStatusMessage(data['status'] ?? 'pending');
        });
      }
    } catch (e) {
      if (!mounted) return;
      // 404 = no existing request, that's fine
      if (e.toString().contains('404')) {
        setState(() {
          _statusMessage = null;
        });
      } else {
        setState(() => _errorMessage = 'Erreur lors du chargement: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Votre demande est en attente de traitement par l\'équipe DJASSACI.';
      case 'approved':
        return 'Votre demande a été approuvée ! Votre boutique est certifiée.';
      case 'rejected':
        return 'Votre demande a été refusée. Vous pouvez la modifier et la renvoyer.';
      default:
        return 'Statut: $status';
    }
  }

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

    // Prevent modifying an already approved request
    if (_existingCertification != null && _existingCertification!['status'] == 'approved') {
      setState(() => _errorMessage = 'Cette demande a déjà été approuvée et ne peut plus être modifiée');
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

      final response = await ApiService.instance.saveUserCertificationInfo(
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

        // Open WhatsApp with pre-filled message
        await _openWhatsApp();
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

  Future<void> _openWhatsApp() async {
    const message = '''Bonjour l'équipe DJASSACI 👋

Je viens de remplir et d'enregistrer mes informations pour ma demande de certification vendeur.

Je suis disponible pour répondre aux questions et effectuer les autres étapes nécessaires afin d'obtenir la certification de ma boutique.

Merci de m'accompagner dans cette démarche. 😊''';

    final phone = '2250715926401';
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande enregistrée. Impossible d\'ouvrir WhatsApp. Contactez le $phone'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande enregistrée. Erreur WhatsApp: $e. Contactez le $phone'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildImagePicker(String label, File? image, VoidCallback? onTap, {String? existingUrl}) {
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
                : (existingUrl != null && existingUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          existingUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Image non disponible',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            onTap != null ? 'Appuyez pour ajouter une image' : 'Image enregistrée',
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
    final isApproved = _existingCertification != null && _existingCertification!['status'] == 'approved';
    final hasExisting = _existingCertification != null;

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
                    if (_statusMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isApproved ? Colors.green.shade50 : Colors.blue.shade50,
                          border: Border.all(color: isApproved ? Colors.green.shade200 : Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isApproved ? Icons.verified : Icons.hourglass_empty,
                              color: isApproved ? Colors.green.shade700 : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: isApproved ? Colors.green.shade700 : Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasExisting && !isApproved)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous avez déjà une demande en cours. Vous pouvez la modifier ci-dessous.',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isApproved)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Votre boutique est certifiée. Aucune modification n\'est possible.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextFormField(
                      controller: _boutiqueNomController,
                      enabled: !isApproved,
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
                      enabled: !isApproved,
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
                      enabled: !isApproved,
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
                      isApproved ? null : () => _showImageSourceDialog((img) => setState(() => _rectoCiImage = img)),
                      existingUrl: hasExisting ? _existingCertification!['rectoCiUrl'] : null,
                    ),
                    _buildImagePicker(
                      'Verso de la pièce d\'identité *',
                      _versoCiImage,
                      isApproved ? null : () => _showImageSourceDialog((img) => setState(() => _versoCiImage = img)),
                      existingUrl: hasExisting ? _existingCertification!['versoCiUrl'] : null,
                    ),
                    _buildImagePicker(
                      'Photo du vendeur *',
                      _photoVendeurImage,
                      isApproved ? null : () => _showImageSourceDialog((img) => setState(() => _photoVendeurImage = img)),
                      existingUrl: hasExisting ? _existingCertification!['photoVendeurUrl'] : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (isApproved || _isLoading || _isUploading) ? null : _saveCertificationInfo,
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
                                  : isApproved
                                      ? 'Certifiée - Non modifiable'
                                      : 'Enregistrer les informations',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApproved ? Colors.grey : Colors.orange,
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