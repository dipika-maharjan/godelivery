import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/riders_repository.dart';
import 'auth_provider.dart';

/// Order ids the signed-in rider is currently sharing their live location
/// for. Lives above any one screen so sharing keeps going after the rider
/// leaves the delivery page or backgrounds the app (Android runs it as a
/// foreground service with an ongoing notification; iOS uses background
/// location updates).
final liveLocationSharingProvider =
    NotifierProvider<LiveLocationSharingController, Set<String>>(
      LiveLocationSharingController.new,
    );

class LiveLocationSharingController extends Notifier<Set<String>> {
  // Customers' maps poll every 5s and animate between points, so this is
  // as often as a ping is useful.
  static const _minPingInterval = Duration(seconds: 5);
  // distanceFilter means a parked rider produces no positions; re-send the
  // last fix so their marker stays "live" instead of going stale.
  static const _heartbeatInterval = Duration(seconds: 30);

  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeat;
  Position? _lastPosition;
  DateTime _lastPostAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Set<String> build() {
    ref.listen(authControllerProvider, (_, next) {
      if (!next.isAuthenticated) stopAll();
    });
    ref.onDispose(_stopStream);
    return const {};
  }

  /// Starts sharing for [orderId]. Returns an error message to show the
  /// rider if location isn't available, or null once sharing is on.
  Future<String?> start(String orderId) async {
    final error = await _ensurePermission();
    if (error != null) return error;
    state = {...state, orderId};
    _startStream();
    return null;
  }

  void stop(String orderId) {
    if (!state.contains(orderId)) return;
    state = {...state}..remove(orderId);
    if (state.isEmpty) _stopStream();
  }

  void stopAll() {
    if (state.isEmpty) return;
    state = const {};
    _stopStream();
  }

  Future<String?> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on location services to share your location.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Location permission is needed to share your location.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is blocked — enable it in Settings.';
    }
    return null;
  }

  void _startStream() {
    if (_positionSub != null) return;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen(_onPosition, onError: (_) {});
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      final last = _lastPosition;
      if (last != null &&
          DateTime.now().difference(_lastPostAt) >= _heartbeatInterval) {
        _post(last);
      }
    });
  }

  void _stopStream() {
    _positionSub?.cancel();
    _positionSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastPosition = null;
  }

  void _onPosition(Position position) {
    _lastPosition = position;
    if (DateTime.now().difference(_lastPostAt) < _minPingInterval) return;
    _post(position);
  }

  Future<void> _post(Position position) async {
    _lastPostAt = DateTime.now();
    final repo = ref.read(ridersRepositoryProvider);
    // One ping per shared order: the live-location endpoint keys on the
    // order id, so a rider carrying several parcels shows up on each.
    for (final orderId in state) {
      try {
        await repo.submitLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          speedKmh: position.speed >= 0 ? position.speed * 3.6 : null,
          heading: position.heading >= 0 ? position.heading : null,
          orderId: orderId,
        );
      } catch (_) {
        // A missed ping isn't worth interrupting the rider over — the next
        // position or heartbeat will try again.
      }
    }
  }

  LocationSettings _locationSettings() {
    const distanceFilter = 10;
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          intervalDuration: _minPingInterval,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Sharing your live location',
            notificationText:
                'Customers can see where you are until you stop sharing.',
            notificationChannelName: 'Live location sharing',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: distanceFilter,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
    }
  }
}
