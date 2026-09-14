import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/locations_repository.dart';
import '../models/saved_location.dart';

final savedLocationsProvider =
    AsyncNotifierProvider<SavedLocationsNotifier, List<SavedLocation>>(
      SavedLocationsNotifier.new,
    );

class SavedLocationsNotifier extends AsyncNotifier<List<SavedLocation>> {
  @override
  Future<List<SavedLocation>> build() {
    return ref.read(locationsRepositoryProvider).list();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
