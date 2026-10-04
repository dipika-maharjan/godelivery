import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A home-screen quick action the user tapped, queued until the customer
/// shell (`HomeShell`) is mounted and can act on it — which may be a moment
/// later if the app launched cold and still needs to resolve auth first.
enum QuickAction { track, shipments, newShipment }

final pendingQuickActionProvider = StateProvider<QuickAction?>((ref) => null);
