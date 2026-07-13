import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../Controllers/notification_controller.dart';
import '../../Models/notification_model.dart';
import '../../Utils/app_theme.dart';
import '../../Widgets/shimmer_widgets.dart';
import '../Orders/order_tracking_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, _) {
              if (controller.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: controller.markAllAsRead,
                child: const Text('Mark all read',
                    style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const ShimmerList();
          }
          if (controller.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Order updates and offers will show up here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = controller.notifications[index];
              return _NotificationTile(notification: n, controller: controller)
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationController controller;

  const _NotificationTile({required this.notification, required this.controller});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.general:
        return Icons.info_outline;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.order:
        return AppTheme.primaryColor;
      case NotificationType.promo:
        return AppTheme.warningColor;
      case NotificationType.general:
        return AppTheme.infoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? null : _color.withValues(alpha: 0.06),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.15),
          child: Icon(_icon, color: _color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.body),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
              ),
        onTap: () {
          if (!notification.isRead) {
            controller.markAsRead(notification.notificationId);
          }
          if (notification.orderId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: notification.orderId!),
              ),
            );
          }
        },
      ),
    );
  }
}
