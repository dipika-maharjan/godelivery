import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_repository.dart';
import '../models/receiver_lookup.dart';

final receiverLookupProvider =
    FutureProvider.family<ReceiverLookupResult, String>((ref, phoneNumber) {
      return ref.read(userRepositoryProvider).lookup(phoneNumber);
    });
