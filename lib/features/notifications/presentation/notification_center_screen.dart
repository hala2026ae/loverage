import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/loverage_repository.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _isLoading = false;
  List<InAppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _repository.notifications();
      if (!mounted) return;
      setState(() {
        _notifications = rows.map(_notificationFromRow).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load notifications: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await _repository.markAllNotificationsRead();
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  Future<void> _onNotificationTap(InAppNotification notification) async {
    if (!notification.isRead) {
      await _repository.markNotificationRead(notification.id);
      setState(() => notification.isRead = true);
    }
    context.go(notification.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBurgundy,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.primaryBurgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primaryBurgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBurgundy,
              ),
            )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.borderLight, height: 1.0),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
    );
  }

  Widget _buildNotificationTile(InAppNotification item) {
    IconData icon;
    Color iconColor;
    switch (item.type) {
      case 'knock_received':
        icon = Icons.favorite_rounded;
        iconColor = AppColors.verificationBadge;
        break;
      case 'verification_approved':
        icon = Icons.verified_rounded;
        iconColor = Colors.blue;
        break;
      case 'chat_request_received':
        icon = Icons.chat_bubble_rounded;
        iconColor = AppColors.primaryBurgundy;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppColors.textSecondary;
    }

    return ListTile(
      onTap: () => _onNotificationTap(item),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20.0),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14.0,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4.0),
          Text(
            item.body,
            style: TextStyle(
              fontSize: 13.0,
              color: item.isRead
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            item.timeAgo,
            style: const TextStyle(fontSize: 11.0, color: AppColors.textMuted),
          ),
        ],
      ),
      trailing: !item.isRead
          ? const CircleAvatar(
              radius: 4.0,
              backgroundColor: AppColors.primaryBurgundy,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64.0,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16.0),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16.0,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

InAppNotification _notificationFromRow(Map<String, dynamic> row) {
  return InAppNotification(
    id: row['id'].toString(),
    type: (row['type'] as String?) ?? 'notification',
    title: (row['title'] as String?) ?? 'Loverage',
    body: (row['body'] as String?) ?? '',
    timeAgo: _timeAgo(DateTime.tryParse((row['created_at'] ?? '').toString())),
    isRead: row['read_at'] != null,
    routePath: (row['route_path'] as String?) ?? '/home',
  );
}

String _timeAgo(DateTime? value) {
  if (value == null) return 'Recently';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  return '${diff.inDays} days ago';
}

class InAppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String timeAgo;
  bool isRead;
  final String routePath;

  InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.isRead,
    required this.routePath,
  });
}
