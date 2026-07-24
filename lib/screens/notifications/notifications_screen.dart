import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_notification.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch notifications on mount
    Future.microtask(() {
      ref.read(notificationsListProvider.notifier).fetchNotifications(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsListProvider.notifier).fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.notifications.any((n) => !n.read))
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                ref.read(notificationsListProvider.notifier).markAllAsRead();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(notificationsListProvider.notifier)
            .fetchNotifications(refresh: true),
        child: _buildContent(state),
      ),
    );
  }

  Widget _buildContent(NotificationsListState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 16),
              Text(
                'Failed to load notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref
                    .read(notificationsListProvider.notifier)
                    .fetchNotifications(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 40,
                color: AppTheme.textDisabled,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'You are all caught up!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.horizontalPad,
        vertical: 16,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.notifications.length + 1,
      itemBuilder: (context, index) {
        if (index == state.notifications.length) {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox(height: 40); // extra spacing at bottom
        }

        final item = state.notifications[index];
        return _buildNotificationCard(item, state.acknowledgedAlertIds);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification item, Set<String> acknowledgedAlertIds) {
    Color typeColor;
    IconData icon;

    switch (item.type.toLowerCase()) {
      case 'alert':
        typeColor = AppTheme.danger;
        icon = Icons.warning_amber_rounded;
        break;
      case 'mention':
        typeColor = AppTheme.primary;
        icon = Icons.alternate_email;
        break;
      case 'share':
        typeColor = AppTheme.success;
        icon = Icons.reply;
        break;
      case 'assignment':
        typeColor = AppTheme.warning;
        icon = Icons.assignment_outlined;
        break;
      default:
        typeColor = AppTheme.info;
        icon = Icons.notifications_outlined;
    }

    final String timeAgo = _formatTime(item.creation);

    return Opacity(
      opacity: item.read ? 0.7 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: BorderSide(
            color: item.read ? AppTheme.bgBorder.withValues(alpha: 0.5) : AppTheme.bgBorder,
            width: item.read ? 1.0 : 1.5,
          ),
        ),
        color: item.read ? Colors.white.withValues(alpha: 0.9) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          onTap: () {
            if (!item.read) {
              ref.read(notificationsListProvider.notifier).markAsRead(item.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: item.read ? FontWeight.normal : FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (item.content != null && item.content!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.content!.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (item.documentType == 'PDT Alert' &&
                          item.documentName != null &&
                          !acknowledgedAlertIds.contains(item.documentName)) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              foregroundColor: AppTheme.primary,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(notificationsListProvider.notifier)
                                    .acknowledgeAlert(item);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to acknowledge — try again'),
                                      backgroundColor: AppTheme.danger,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Acknowledge'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Unread dot
                if (!item.read) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final difference = DateTime.now().difference(localTime);

    if (difference.inDays > 7) {
      return '${localTime.day}/${localTime.month}/${localTime.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
