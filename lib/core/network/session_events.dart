import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tiny out-of-band hook so the network layer can tell the auth layer
/// "the session is dead" without importing it directly (avoids a
/// dio_client <-> auth_provider circular provider dependency).
class SessionEvents {
  VoidCallback? onSessionExpired;
}

final sessionEventsProvider = Provider<SessionEvents>((ref) => SessionEvents());
