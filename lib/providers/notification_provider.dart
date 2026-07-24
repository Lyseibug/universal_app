import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/app_notification.dart';
import '../features/notifications/notification_repository.dart';
import 'auth_provider.dart';

// ─── Unread Count State Notifier ──────────────────────────────────────────────

class UnreadNotificationCountNotifier extends StateNotifier<int> {
  final NotificationRepository _repo;
  final Ref _ref;
  Timer? _timer;

  UnreadNotificationCountNotifier(this._repo, this._ref) : super(0) {
    _init();
  }

  void _init() {
    // Watch authentication status
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (next.isAuthenticated) {
          startPolling();
        } else {
          stopPolling();
        }
      },
      fireImmediately: true,
    );
  }

  void startPolling() {
    _timer?.cancel();
    fetchCount();
    // Poll count every 10 seconds for near-real-time notification updates
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchCount());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    state = 0;
  }

  Future<void> fetchCount() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    try {
      final count = await _repo.getUnreadCount();
      if (mounted) {
        final previousCount = state;
        state = count;
        // If count increased, refresh the notifications list so new items appear
        if (count > previousCount) {
          _ref.read(notificationsListProvider.notifier).fetchNotifications(refresh: true);
        }
      }
    } catch (e) {
      // Fail silently for background polling
    }
  }

  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void increment() {
    state = state + 1;
  }

  void reset() {
    state = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadNotificationCountProvider =
    StateNotifierProvider<UnreadNotificationCountNotifier, int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return UnreadNotificationCountNotifier(repo, ref);
});

// ─── Notification List State ───────────────────────────────────────────────

class NotificationsListState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  // document_name of PDT Alerts acknowledged this session -- tracked locally
  // so the "Acknowledge" button disappears immediately without a refetch.
  final Set<String> acknowledgedAlertIds;

  const NotificationsListState({
    required this.notifications,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.error,
    this.acknowledgedAlertIds = const {},
  });

  const NotificationsListState.initial()
      : notifications = const [],
        isLoading = false,
        isLoadingMore = false,
        hasMore = true,
        error = null,
        acknowledgedAlertIds = const {};

  NotificationsListState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    Set<String>? acknowledgedAlertIds,
  }) {
    return NotificationsListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      acknowledgedAlertIds: acknowledgedAlertIds ?? this.acknowledgedAlertIds,
    );
  }
}

// ─── Notification List Notifier ────────────────────────────────────────────

class NotificationsListNotifier extends StateNotifier<NotificationsListState> {
  final NotificationRepository _repo;
  final Ref _ref;

  NotificationsListNotifier(this._repo, this._ref)
      : super(const NotificationsListState.initial());

  /// Sorts notifications with unread items first, then by creation date (newest first).
  List<AppNotification> _sorted(List<AppNotification> list) {
    final sorted = List<AppNotification>.from(list);
    sorted.sort((a, b) {
      // Unread first (read=false before read=true)
      if (a.read != b.read) return a.read ? 1 : -1;
      // Then newest first
      return b.creation.compareTo(a.creation);
    });
    return sorted;
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, clearError: true, hasMore: true);
    } else {
      if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final start = refresh ? 0 : state.notifications.length;
      final list = await _repo.getNotifications(limit: 20, start: start);

      if (mounted) {
        final combined = refresh ? list : [...state.notifications, ...list];
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          notifications: _sorted(combined),
          hasMore: list.length >= 20,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> markAsRead(String id) async {
    // Check if it's already read to avoid redundant call/updates
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index == -1 || state.notifications[index].read) return;

    // Optimistic UI update
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(read: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: _sorted(updated));

    try {
      await _repo.markRead(id: id);
      _ref.read(unreadNotificationCountProvider.notifier).decrement();
    } catch (e) {
      // Revert if it fails on server
      if (mounted) {
        final reverted = state.notifications.map((n) {
          if (n.id == id) {
            return n.copyWith(read: false);
          }
          return n;
        }).toList();
        state = state.copyWith(notifications: _sorted(reverted));
      }
    }
  }

  Future<void> markAllAsRead() async {
    final hasUnread = state.notifications.any((n) => !n.read);
    if (!hasUnread) return;

    // Optimistic UI update
    final updated = state.notifications.map((n) => n.copyWith(read: true)).toList();
    state = state.copyWith(notifications: updated);

    try {
      await _repo.markRead(markAll: true);
      _ref.read(unreadNotificationCountProvider.notifier).reset();
    } catch (e) {
      // Revert if fail
      fetchNotifications(refresh: true);
    }
  }

  Future<void> acknowledgeAlert(AppNotification item) async {
    if (item.documentType != 'PDT Alert' || item.documentName == null) return;
    if (state.acknowledgedAlertIds.contains(item.documentName)) return;

    // Optimistic: hide the button immediately.
    state = state.copyWith(
      acknowledgedAlertIds: {...state.acknowledgedAlertIds, item.documentName!},
    );
    try {
      await _repo.acknowledgeAlert(item.documentName!);
      if (!item.read) await markAsRead(item.id);
    } catch (e) {
      if (mounted) {
        final reverted = Set<String>.from(state.acknowledgedAlertIds)
          ..remove(item.documentName);
        state = state.copyWith(acknowledgedAlertIds: reverted);
      }
      rethrow;
    }
  }

  void insertNotification(AppNotification notification) {
    final index = state.notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) return;
    state = state.copyWith(
      notifications: _sorted([notification, ...state.notifications]),
    );
  }
}

final notificationsListProvider =
    StateNotifierProvider<NotificationsListNotifier, NotificationsListState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationsListNotifier(repo, ref);
});
