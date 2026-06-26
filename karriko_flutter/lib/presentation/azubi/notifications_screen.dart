import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/appwrite_service.dart';
import '../../providers/auth_provider.dart';

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String type;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  factory _NotificationItem.fromDoc(Map<String, dynamic> data, String docId, String createdAt) =>
      _NotificationItem(
        id: docId,
        title: data['title'] as String,
        body: data['body'] as String,
        isRead: data['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(createdAt),
        type: data['type'] as String? ?? 'info',
      );
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<_NotificationItem> _notifications = [];
  bool _isLoading = true;
  RealtimeSubscription? _subscription;

  Databases get _db => Databases(AppwriteService.client);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      final result = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'notifications',
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );
      if (mounted) {
        setState(() {
          _notifications = result.documents
              .map((d) => _NotificationItem.fromDoc(d.data, d.$id, d.$createdAt))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    final realtime = Realtime(AppwriteService.client);
    _subscription = realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.notifications.documents',
    ]);
    _subscription!.stream.listen((event) {
      if (mounted) _loadNotifications();
    });
  }

  Future<void> _markAllRead() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    final unread = _notifications.where((n) => !n.isRead).toList();
    await Future.wait(
      unread.map((n) => _db.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: 'notifications',
            documentId: n.id,
            data: {'is_read': true},
          )),
    );
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Benachrichtigungen'),
            if (unread > 0)
              Text('$unread ungelesene',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Alle lesen', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Keine Benachrichtigungen',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _notifications.length,
                  itemBuilder: (_, i) {
                    final n = _notifications[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.surface : AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: n.isRead ? AppColors.border : AppColors.primaryLight),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _iconForType(n.type),
                          color: n.isRead ? AppColors.textMuted : AppColors.primary,
                        ),
                        title: Text(n.title,
                            style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.body, style: Theme.of(context).textTheme.bodySmall),
                            Text(DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        trailing: !n.isRead
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'review_reply' => Icons.reply_outlined,
      'review_approved' => Icons.check_circle_outline,
      'review_rejected' => Icons.cancel_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
