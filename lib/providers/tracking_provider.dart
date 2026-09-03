import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/tracking.dart';

final trackingProvider = FutureProvider.family<PublicTracking, String>((
  ref,
  trackingNumber,
) {
  return ref.read(orderRepositoryProvider).track(trackingNumber);
});
