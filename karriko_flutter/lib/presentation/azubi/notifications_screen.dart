import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';

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

  factory _NotificationItem.fromJson(Map<String, dynamic> json) => _NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        type: json['type'] as String? ?? 'info',
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

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeRealtime();
  }

  Future<void> _loadNotifications() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      final data = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _notifications = (data as List).map((e) => _NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
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
    SupabaseService.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (mounted) {
            setState(() {
              _notifications = data.map((e) => _NotificationItem.fromJson(e)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            });
          }
        });
  }

  Future<void> _markAllRead() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
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
              Text('$unread ungelesene', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
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
                      Text('Keine Benachrichtigungen', style: Theme.of(context).textTheme.headlineSmall),
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
                        border: Border.all(color: n.isRead ? AppColors.border : AppColors.primaryLight),
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
