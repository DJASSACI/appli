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
  // Raccourcis personnalisés (compte courant uniquement)
  int? _shortcutsUserId;
  bool _loadingShortcuts = false;
  bool _hasMyTeams = false;
  bool _hasMySavings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_triedRestoreOnce) return;
      _triedRestoreOnce = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await _loadFollowCounts(authProvider.user!.id);
        _loadMyShortcuts(authProvider.user!.id);
        return;
      }
      await authProvider.loadCurrentUser();
      if (authProvider.user != null) {
        await _loadFollowCounts(authProvider.user!.id);
        _loadMyShortcuts(authProvider.user!.id);
      }
    });
  }

  void _resetShortcuts() {
    _shortcutsUserId = null;
    _hasMyTeams = false;
    _hasMySavings = false;
    _loadingShortcuts = false;
  }

  Future<void> _loadMyShortcuts(int userId) async {
    if (!mounted) return;
    setState(() {
      _shortcutsUserId = userId;
      _loadingShortcuts = true;
      _hasMyTeams = false;
      _hasMySavings = false;
    });
    try {
      final results = await Future.wait([
        ApiService.instance.getMyTeamPurchases(),
        ApiService.instance.getMySavingsPlans(),
      ]);
      if (!mounted) return;
      final currentId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (currentId != userId) return; // compte changé pendant le chargement
      bool hasItems(dynamic data) {
        if (data is Map) {
          final items = data['items'];
          if (items is List) return items.isNotEmpty;
          final count = data['count'];
          if (count is num) return count > 0;
        }
        if (data is List) return data.isNotEmpty;
        return false;
      }
      setState(() {
        _hasMyTeams = hasItems(results[0].data);
        _hasMySavings = hasItems(results[1].data);
        _loadingShortcuts = false;
      });
    } catch (_) {
      if (!mounted) return;
      final currentId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (currentId != userId) return;
      setState(() => _loadingShortcuts = false);
    }
  }

  Future<void> _loadFollowCounts(int userId) async {
    try {
      final followersResponse = await ApiService.instance.get('/api/users/$userId/followers');
      final followingResponse = await ApiService.instance.get('/api/users/$userId/following');
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

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _shortcutCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMyActivities(User user) {
    // (scénario 7) si compte changé ou pas encore chargé pour cet user, relancer sans bloquer le profil
    if (_shortcutsUserId != user.id && !_loadingShortcuts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Provider.of<AuthProvider>(context, listen: false).user?.id == user.id) {
          _loadMyShortcuts(user.id);
        }
      });
    }
    final forCurrent = _shortcutsUserId == user.id;
    if (!forCurrent || _loadingShortcuts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final cards = <Widget>[];
    if (_hasMyTeams) {
      cards.add(_shortcutCard(
        icon: Icons.groups,
        color: Colors.indigo,
        title: 'Mes achats en équipe',
        subtitle: 'Retrouvez les équipes auxquelles vous participez',
        onTap: () => context.push('/my-team-purchases'),
      ));
    }
    if (_hasMySavings) {
      cards.add(_shortcutCard(
        icon: Icons.savings,
        color: Colors.teal,
        title: 'Mes achats petit à petit',
        subtitle: 'Suivez votre progression et vos économies',
        onTap: () => context.push('/my-savings-plans'),
      ));
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionTitle('Mes activités'), ...cards]);
  }

  Widget _buildFollowSection() {
    Widget stat(String label, int value) => Expanded(
          child: InkWell(
            onTap: label == 'Abonnés' ? _openFollowers : _openFollowing,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _isLoadingCounts
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            ),
          ),
        );
    return Row(children: [stat('Abonnés', _followersCount), const SizedBox(width: 12), stat('Abonnements', _followingCount)]);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (pickedFile == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final cloudinaryService = CloudinaryStorageService();
      final avatarUrl = await cloudinaryService.uploadAvatar(File(pickedFile.path));
      final response = await ApiService.instance.put('/api/users/profile/avatar', data: {'avatarUrl': avatarUrl});
      if (!mounted) return;
      if (response.statusCode == 200) {
        await authProvider.refreshUserInBackground();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil mise à jour')));
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final response = await ApiService.instance.put('/api/users/profile/avatar', data: {'avatarUrl': null});
      if (!mounted) return;
      if (response.statusCode == 200) {
        await authProvider.refreshUserInBackground();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil supprimée')));
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choisir dans la galerie'), onTap: () { Navigator.of(context).pop(); _pickAndUploadAvatar(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Prendre une photo'), onTap: () { Navigator.of(context).pop(); _pickAndUploadAvatar(ImageSource.camera); }),
            if (hasAvatar)
              ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)), onTap: () { Navigator.of(context).pop(); _deleteAvatar(); }),
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
                        : Text(user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: Colors.white)),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap, Color? iconColor, Color? textColor, Widget? trailing}) {
    return Card(
      elevation: 0.3,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.grey[800]),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
        onTap: onTap,
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
              _resetShortcuts();
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
            _resetShortcuts();
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(authProvider.isLoading ? 'Chargement...' : 'Session indisponible. Rechargez la page.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () async { await authProvider.loadCurrentUser(); }, child: const Text('Réessayer')),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // En-tête moderne
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Center(child: _buildAvatar(user)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text('${user.prenom} ${user.nom}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                        if (user.sellerVerified == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Certifié', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user.numero, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildFollowSection(),
              CertificationBanner(
                sellerVerifiedUntil: user.sellerVerifiedUntil,
                sellerVerified: user.sellerVerified,
                sellerName: user.nom,
                onRenew: () => authProvider.refreshUserInBackground(),
              ),
              const SizedBox(height: 8),
              _buildMyActivities(user),

              _sectionTitle('Mon compte'),
              _actionTile(icon: Icons.phone_outlined, title: 'Téléphone', subtitle: user.numero),
              _actionTile(icon: Icons.location_on_outlined, title: 'Adresse', subtitle: user.address),
              _actionTile(icon: Icons.lock_outline, iconColor: Colors.orange, title: 'Modifier le mot de passe', onTap: () => context.go('/change-password')),

              _sectionTitle('Raccourcis'),
              Card(
                elevation: 0.3,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Accueil'), trailing: const Icon(Icons.chevron_right, size: 20), onTap: () => context.go('/home')),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Mes produits'), trailing: const Icon(Icons.chevron_right, size: 20), onTap: () => context.go('/my-products')),
                  ],
                ),
              ),

              _sectionTitle('Actions importantes'),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Demande de suppression de mon compte'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Demande de suppression de compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Text.rich(TextSpan(
                            text: 'Vous serez redirigé vers WhatsApp pour envoyer votre demande de suppression. ',
                            style: const TextStyle(fontSize: 14),
                            children: [
                              TextSpan(text: 'Vos informations seront examinées afin de traiter votre demande.', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          )),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            final numeroCompte = user.numero.trim();
                            final nomCompte = user.nom.trim();
                            final message = 'Bonjour DJASSA CI, je souhaite demander la suppression de mon compte lié au $numeroCompte et $nomCompte ';
                            const phone = '+2250715926401';
                            final url = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
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
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Devenir boutique certifiée'),
                      content: const Text('Vous allez être redirigé vers WhatsApp pour demander la certification de votre boutique. Certaines informations et justificatifs pourront vous être demandés afin de vérifier votre identité et les informations de votre boutique.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            try {
                              await ApiService.instance.post('/api/users/refresh-seller-verified', data: {});
                            } catch (_) {}
                            final nomVendeur = user.nom.trim();
                            final message = 'Bonjour l\'équipe Djassa-ci, je souhaite certifier ma boutique. Voici mon nom de vendeur : $nomVendeur';
                            const adminPhone = '+2250715926401';
                            final url = Uri.parse('whatsapp://send?phone=$adminPhone&text=${Uri.encodeComponent(message)}');
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
              if (user.role == 'admin') ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin-dashboard'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
              const SizedBox(height: 8),
              _actionTile(icon: Icons.lock, iconColor: Colors.orange, title: 'Politique de confidentialité', onTap: () => context.go('/privacy-policy')),
              _actionTile(icon: Icons.support_agent, iconColor: Colors.orange, title: 'Support / Contact', subtitle: '0715926401', trailing: const Icon(Icons.phone), onTap: () => launchUrl(Uri.parse('tel:0715926401'))),
            ],
          );
        },
      ),
    );
  }
}
