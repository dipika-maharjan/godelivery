import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../providers/quick_action_provider.dart';

final quickActionsServiceProvider = Provider<QuickActionsService>((ref) {
  return QuickActionsService(ref);
});

/// Registers the home-screen long-press shortcuts (iOS Quick Actions /
/// Android App Shortcuts) and, when one is tapped, queues it on
/// [pendingQuickActionProvider] for the customer shell to act on once it's
/// mounted.
class QuickActionsService {
  QuickActionsService(this._ref);

  final Ref _ref;
  final _quickActions = const QuickActions();

  Future<void> initialize() async {
    _quickActions.initialize((type) {
      final action = _actionFromType(type);
      if (action != null) {
        _ref.read(pendingQuickActionProvider.notifier).state = action;
      }
    });
    await _quickActions.setShortcutItems(const [
      ShortcutItem(
        type: 'track',
        localizedTitle: 'Track a shipment',
        icon: 'ic_quick_track',
      ),
      ShortcutItem(
        type: 'shipments',
        localizedTitle: 'Shipments',
        icon: 'ic_quick_shipments',
      ),
      ShortcutItem(
        type: 'new_shipment',
        localizedTitle: 'New shipment',
        icon: 'ic_quick_new_shipment',
      ),
    ]);
  }

  QuickAction? _actionFromType(String type) => switch (type) {
    'track' => QuickAction.track,
    'shipments' => QuickAction.shipments,
    'new_shipment' => QuickAction.newShipment,
    _ => null,
  };
}
