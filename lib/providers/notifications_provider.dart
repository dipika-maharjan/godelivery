import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import '../models/notification.dart';

final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.read(notificationRepositoryProvider).unreadCount();
});

final notificationsListProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final page = await ref
        .read(notificationRepositoryProvider)
        .list(page: 1, pageSize: 50);
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markRead(String id) async {
    final updated = await ref.read(notificationRepositoryProvider).markRead(id);
    state = AsyncData([
      for (final n in state.value ?? const [])
        if (n.id == updated.id) updated else n,
    ]);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    await refresh();
  }
}
