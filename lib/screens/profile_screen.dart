import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/back_arrow.dart';
import '../widgets/certification_banner.dart';
import '../services/api_service.dart';
import '../services/cloudinary_storage_service.dart';
import '../screens/followers_screen.dart';
import '../screens/following_screen.dart';
import 'payment_screen.dart';




class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _triedRestoreOnce = false;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoadingCounts = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_triedRestoreOnce) return;
      _triedRestoreOnce = true;

      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) {
        await _loadFollowCounts(authProvider.user!.id);
        return;
      }

      await authProvider.loadCurrentUser();
      if (authProvider.user != null) {
        await _loadFollowCounts(authProvider.user!.id);
      }
    });
  }

  Future<void> _loadFollowCounts(int userId) async {
    try {
      final followersResponse = await ApiService.instance.get(
        '/api/users/$userId/followers',
      );
      final followingResponse = await ApiService.instance.get(
        '/api/users/$userId/following',
      );
      if (!mounted) return;
      final followersData = followersResponse.data;
      final followingData = followingResponse.data;
      if (followersData is List && followingData is List) {
        setState(() {
          _followersCount = followersData.length;
          _followingCount = followingData.length;
          _isLoadingCounts = false;
        });
      } else {
        setState(() => _isLoadingCounts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  void _openFollowers() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      context.go('/followers/${user.id}', extra: {'userName': '${user.prenom} ${user.nom}'});
    }
  }

  void _openFollowing() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      context.go('/following/${user.id}', extra: {'userName': '${user.prenom} ${user.nom}'});
    }
  }

  Widget _buildFollowSection() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _openFollowers,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'Abonnés',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingCounts
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '$_followersCount',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _openFollowing,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'Abonnements',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingCounts
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '$_followingCount',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final cloudinaryService = CloudinaryStorageService();
      final avatarUrl = await cloudinaryService.uploadAvatar(File(pickedFile.path));

      final response = await ApiService.instance.put(
        '/api/users/profile/avatar',
        data: {'avatarUrl': avatarUrl},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await authProvider.refreshUserInBackground();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _deleteAvatar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || user.avatarUrl == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo de profil'),
        content: const Text('Voulez-vous vraiment supprimer votre photo de profil ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final response = await ApiService.instance.put(
        '/api/users/profile/avatar',
        data: {'avatarUrl': null},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await authProvider.refreshUserInBackground();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil supprimée')),
        );
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User user) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _isUploadingAvatar ? null : _showAvatarOptions,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
            child: (!hasAvatar || _isUploadingAvatar)
                ? Center(
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator()
                        : Text(
                            user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final user = authProvider.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.isLoading
                        ? 'Chargement...'
                        : 'Session indisponible. Rechargez la page.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.loadCurrentUser();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: _buildAvatar(user)),
              const SizedBox(height: 20),
              Text(
                '${user.prenom} ${user.nom}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                user.numero,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildFollowSection(),
              // Bannière d'avertissement d'expiration de certification vendeur
              CertificationBanner(
                sellerVerifiedUntil: user.sellerVerifiedUntil,
                sellerVerified: user.sellerVerified,
                sellerName: user.nom,
                onRenew: () => authProvider.refreshUserInBackground(),
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Téléphone'),
                  subtitle: Text(user.numero),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Adresse'),
                  subtitle: Text(user.address),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text('Accueil'),
              ),
              /*
              ElevatedButton.icon(
                onPressed: () => context.go('/my-orders'),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Mes commandes'),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/my-seller-orders'),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Mes commandes vendeur'),
              ),
              */
              ElevatedButton.icon(
                onPressed: () => context.go('/my-products'),
                icon: const Icon(Icons.inventory_2),
                label: const Text('Mes produits'),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text(
                        'Demande de suppression de mon compte',
                      ),
                      content: const Text(
                        'Vous allez être redirigé vers WhatsApp pour envoyer votre demande de suppression. Vos informations seront examinées afin de traiter votre demande.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();

                            final numeroCompte = user.numero.trim();
                            final nomCompte = user.nom.trim();
                            final message =
                                'Bonjour DJASSA CI, je souhaite demander la suppression de mon compte lié au $numeroCompte et $nomCompte ';

                            const phone = '+2250715926401';
                            final url = Uri.parse(
                              'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}',
                            );

                            await launchUrl(url);
                          },
                          child: const Text('Continuer'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Demander la suppression de mon compte'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),

              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Devenir boutique certifiée'),
                      content: const Text(
                        'Vous allez être redirigé vers WhatsApp pour demander la certification de votre boutique. Certaines informations et justificatifs pourront vous être demandés afin de vérifier votre identité et les informations de votre boutique.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();

                            // Refresh seller status before requesting a new certification window
                            try {
                              await ApiService.instance.post('/api/users/refresh-seller-verified', data: {});
                            } catch (_) {}

                            // Redirection directe WhatsApp (sans formulaire)
                            final nomVendeur = user.nom.trim();
                            final message =
                                'Bonjour l\'équipe Djassa-ci, je souhaite certifier ma boutique. Voici mon nom de vendeur : $nomVendeur';

                            const adminPhone = '+2250715926401';
                            final url = Uri.parse(
                              'whatsapp://send?phone=$adminPhone&text=${Uri.encodeComponent(message)}',
                            );

                            await launchUrl(url);
                          },
                          child: const Text('Continuer'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('Devenir boutique certifiée'),
              ),
              
              if (user.role == 'admin')
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin-dashboard'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              Card(

                child: ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text('Politique de confidentialité'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/privacy-policy'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.orange),
                  title: const Text('Support / Contact'),
                  subtitle: const Text('0715926401'),
                  trailing: const Icon(Icons.phone),
                  onTap: () => launchUrl(Uri.parse('tel:0715926401')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

