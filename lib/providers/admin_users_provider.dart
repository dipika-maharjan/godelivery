import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_users_repository.dart';
import '../data/api_keys_repository.dart';
import '../models/admin_user.dart';
import '../models/api_key.dart';
import '../models/user.dart';

class AdminUsersFilter {
  const AdminUsersFilter({this.role, this.search});

  final UserRole? role;
  final String? search;
}

final adminUsersFilterProvider = StateProvider<AdminUsersFilter>(
  (ref) => const AdminUsersFilter(),
);

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUserSummary>>(
      AdminUsersNotifier.new,
    );

class AdminUsersNotifier extends AsyncNotifier<List<AdminUserSummary>> {
  @override
  Future<List<AdminUserSummary>> build() async {
    final filter = ref.watch(adminUsersFilterProvider);
    final page = await ref
        .read(adminUsersRepositoryProvider)
        .listAll(role: filter.role, search: filter.search);
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final adminUserDetailProvider = FutureProvider.family<AdminUserDetail, String>(
  (ref, id) => ref.read(adminUsersRepositoryProvider).getOne(id),
);

final apiKeysProvider = AsyncNotifierProvider<ApiKeysNotifier, List<ApiKeyListItem>>(
  ApiKeysNotifier.new,
);

class ApiKeysNotifier extends AsyncNotifier<List<ApiKeyListItem>> {
  @override
  Future<List<ApiKeyListItem>> build() {
    return ref.read(apiKeysRepositoryProvider).list();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
