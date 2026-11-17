import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/back_arrow.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const int _pageSize = 20;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<AppNotification> _notifications = [];
  int _total = 0;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _notifications.length < _total) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _offset = 0;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.instance.getNotifications(
        limit: _pageSize,
        offset: 0,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = NotificationsResponse.fromJson(data);
        if (!mounted) return;
        setState(() {
          _notifications = parsed.notifications;
          _total = parsed.total;
          _offset = parsed.notifications.length;
          _isLoading = false;
        });
        await NotificationService.syncPersistentUnreadCount();
      } else {
        throw Exception('Format de réponse invalide');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || _notifications.length >= _total) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await ApiService.instance.getNotifications(
        limit: _pageSize,
        offset: _offset,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = NotificationsResponse.fromJson(data);
        if (!mounted) return;
        setState(() {
          _notifications.addAll(parsed.notifications);
          _offset = _notifications.length;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;

    try {
      await ApiService.instance.markNotificationRead(notification.id);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            read: true,
            createdAt: notification.createdAt,
            sourceEventId: notification.sourceEventId,
          );
        }
      });
      NotificationService.decrementPersistentUnread();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
      await NotificationService.syncPersistentUnreadCount();
    }
  }

  Future<void> _markAllAsRead() async {
    final previousNotifications = List<AppNotification>.from(_notifications);
    try {
      await ApiService.instance.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => AppNotification(
                  id: n.id,
                  userId: n.userId,
                  type: n.type,
                  title: n.title,
                  message: n.message,
                  data: n.data,
                  read: true,
                  createdAt: n.createdAt,
                  sourceEventId: n.sourceEventId,
                ))
            .toList();
      });
      NotificationService.resetPersistentUnreadLocal();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = previousNotifications;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
      await NotificationService.syncPersistentUnreadCount();
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final wasUnread = !notification.read;
    final previousNotifications = List<AppNotification>.from(_notifications);
    final previousTotal = _total;
    try {
      await ApiService.instance.deleteNotification(notification.id);
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
        _total = _total > 0 ? _total - 1 : 0;
      });
      if (wasUnread) {
        NotificationService.decrementPersistentUnread();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = previousNotifications;
        _total = previousTotal;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
      await NotificationService.syncPersistentUnreadCount();
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Marquer comme lue si non lue
    if (!notification.read) {
      _markAsRead(notification);
    }

    // Navigation si route disponible
    final route = notification.routeForData;
    if (route != null) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = _notifications.any((n) => !n.read);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrow(),
        title: const Text('Mes notifications'),
        actions: [
          if (hasUnread)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tout lire'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 200),
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Erreur: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => _loadNotifications(refresh: true),
                child: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Aucune notification')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = _notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onMarkRead: () => _markAsRead(notification),
            onDelete: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 2 : 1,
      color: isUnread ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? theme.colorScheme.primary.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur lu/non lu
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4, right: 10),
                decoration: BoxDecoration(
                  color: isUnread ? theme.colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isUnread
                      ? null
                      : Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          notification.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnread
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                            : Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.data.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _buildDataChips(context),
                      ),
                    ],
                  ],
                ),
              ),
              // Menu actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) {
                  if (value == 'read' && !notification.read) {
                    onMarkRead();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.read)
                    const PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Marquer comme lue'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDataChips(BuildContext context) {
    final chips = <Widget>[];
    final data = notification.data;

    if (data['teamId'] != null) {
      chips.add(_DataChip(
        label: 'Équipe #${data['teamId']}',
        icon: Icons.groups,
        color: Colors.indigo,
      ));
    }
    if (data['planId'] != null) {
      chips.add(_DataChip(
        label: 'Épargne #${data['planId']}',
        icon: Icons.savings,
        color: Colors.teal,
      ));
    }
    if (data['orderId'] != null) {
      chips.add(_DataChip(
        label: 'Commande #${data['orderId']}',
        icon: Icons.receipt,
        color: Colors.orange,
      ));
    }
    if (data['amount'] != null) {
      chips.add(_DataChip(
        label: '${data['amount']} FCFA',
        icon: Icons.attach_money,
        color: Colors.green,
      ));
    }

    return chips;
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _DataChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}