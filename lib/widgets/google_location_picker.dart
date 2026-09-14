import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/config/app_config.dart';

bool _isKathmanduLocation(LatLng location) {
  return location.latitude >= 27.55 &&
      location.latitude <= 27.85 &&
      location.longitude >= 85.15 &&
      location.longitude <= 85.55;
}

class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
}

class GoogleLocationPreview extends StatelessWidget {
  const GoogleLocationPreview({required this.location, super.key});

  final PickedLocation location;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(location.latitude, location.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 150,
        child: IgnorePointer(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: 15),
            markers: {
              Marker(
                markerId: const MarkerId('selected-location-preview'),
                position: position,
              ),
            },
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),
        ),
      ),
    );
  }
}

class GoogleLocationPicker {
  GoogleLocationPicker._();

  static Future<PickedLocation?> pickLocation(
    BuildContext context, {
    PickedLocation? initialLocation,
  }) {
    return Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => _GoogleLocationPickerPage(
          initialLocation: initialLocation,
        ),
      ),
    );
  }
}

class _GoogleLocationPickerPage extends StatefulWidget {
  const _GoogleLocationPickerPage({this.initialLocation});

  final PickedLocation? initialLocation;

  @override
  State<_GoogleLocationPickerPage> createState() =>
      _GoogleLocationPickerPageState();
}

class _GoogleLocationPickerPageState extends State<_GoogleLocationPickerPage> {
  static const _defaultCenter = LatLng(27.7172, 85.3240);
  static const _kathmanduBounds = '27.55,85.15|27.85,85.55';
  static final _kathmanduValleyBounds = LatLngBounds(
    southwest: const LatLng(27.55, 85.15),
    northeast: const LatLng(27.85, 85.55),
  );
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  late LatLng _selected;
  String? _address;
  bool _searching = false;
  bool _locating = false;
  List<(LatLng, String)> _suggestions = const [];
  Timer? _suggestionDebounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    final initialPosition = initial == null
      ? null
      : LatLng(initial.latitude, initial.longitude);
    final validInitial = initialPosition != null &&
      _isKathmanduLocation(initialPosition);
    _selected = validInitial ? initialPosition : _defaultCenter;
    _address = validInitial ? initial?.address ?? initial?.name : null;
    if (!validInitial) {
      unawaited(_useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() => _searching = true);
    try {
      final googleResult = await _searchGoogle(query);
      if (googleResult != null) {
        await _select(googleResult.$1, googleResult.$2);
      } else {
        final photonResults = await _searchPhoton(query);
        if (photonResults.isEmpty) throw const FormatException();
        await _select(photonResults.first.$1, photonResults.first.$2);
      }
      if (mounted) setState(() => _suggestions = const []);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found. Try a larger area or city name.')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      if (!_isKathmanduLocation(location)) return;
      await _select(location);
    } catch (_) {
      // Kathmandu remains the fallback when GPS is unavailable.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<(LatLng, String)?> _searchGoogle(String query) async {
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': '$query, Nepal',
          'components': 'country:NP',
          'bounds': _kathmanduBounds,
          'region': 'np',
          'key': AppConfig.googleMapsApiKey,
        },
      );
      final data = response.data;
      final results = data?['results'];
      if (data?['status'] != 'OK' || results is! List || results.isEmpty) {
        return null;
      }
      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['location'] as Map<String, dynamic>;
      return (
        LatLng(
          (coordinates['lat'] as num).toDouble(),
          (coordinates['lng'] as num).toDouble(),
        ),
        (first['formatted_address'] as String?) ?? query,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<(LatLng, String)>> _searchPhoton(String query) async {
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://photon.komoot.io/api/',
        queryParameters: {
          'q': '$query, Kathmandu, Nepal',
          'limit': 6,
          'lat': _defaultCenter.latitude,
          'lon': _defaultCenter.longitude,
        },
        options: Options(headers: {'User-Agent': 'GoDelivery/1.0'}),
      );
      final features = response.data?['features'];
      if (features is! List || features.isEmpty) return const [];
      return features.whereType<Map<String, dynamic>>().map((feature) {
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        final properties =
            feature['properties'] as Map<String, dynamic>? ?? {};
        final name = (properties['name'] ?? properties['street'] ?? query)
            .toString();
        final area =
            (properties['city'] ?? properties['district'] ?? 'Nepal')
                .toString();
        return (
          LatLng(
            (coordinates[1] as num).toDouble(),
            (coordinates[0] as num).toDouble(),
          ),
          '$name, $area',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  void _onSearchChanged(String value) {
    _suggestionDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _suggestionDebounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await _searchPhoton(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _suggestions = results);
    });
  }

  Future<void> _chooseSuggestion((LatLng, String) suggestion) async {
    FocusScope.of(context).unfocus();
    _searchController.text = suggestion.$2;
    setState(() => _suggestions = const []);
    await _select(suggestion.$1, suggestion.$2);
  }

  Future<void> _select(LatLng location, [String? resolvedAddress]) async {
    setState(() {
      _selected = location;
      _address = resolvedAddress;
    });
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
    try {
      final places = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted || places.isEmpty) return;
      final place = places.first;
      final parts = [
        place.name,
        place.street,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).toSet();
      setState(() => _address = parts.join(', '));
    } catch (_) {
      // Coordinates remain selectable even when reverse geocoding is unavailable.
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(
        latitude: _selected.latitude,
        longitude: _selected.longitude,
        name: _address,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose location'),
        actions: [
          IconButton(
            tooltip: 'Use my location',
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.locateFixed, size: 19),
          ),
          TextButton(onPressed: _confirm, child: const Text('OK')),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selected, zoom: 15),
            cameraTargetBounds: CameraTargetBounds(_kathmanduValleyBounds),
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(_selected, 16),
              );
            },
            onTap: _select,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('selected-location'),
                position: _selected,
              ),
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search in Kathmandu, Nepal',
                      prefixIcon: const Icon(LucideIcons.search, size: 19),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              onPressed: _search,
                              icon: const Icon(LucideIcons.arrowRight, size: 19),
                            ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: const Icon(LucideIcons.mapPin, size: 18),
                              title: Text(
                                suggestion.$2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _chooseSuggestion(suggestion),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_address != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery location',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _confirm,
                          child: const Text('Confirm location'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
