import 'dart:async';

// baato_maps re-exports maplibre_gl (LatLng, LatLngBounds, CameraTargetBounds,
// ...) unprefixed; flutter_map has its own distinct LatLngBounds, so that one
// name is hidden here and pulled back in with a prefix just for the OSM path.
import 'package:baato_maps/baato_maps.dart' hide LatLngBounds;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:galli_maps_package/galli_maps_package.dart' as galli;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as mlg show LatLngBounds;

import '../core/constants/nepal_geo.dart';
import '../core/maps/map_provider_resolver.dart';
import '../core/maps/photon_search.dart';
import '../core/theme/app_theme.dart';

/// A location picked by the user, independent of which map provider
/// produced it.
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

const _outOfAreaMessage =
    'GoDelivery only serves the Kathmandu valley right now. Please pick a '
    'location within Kathmandu, Lalitpur, or Bhaktapur.';

/// Full-screen picker: routes to Baato, Galli, or OpenStreetMap depending on
/// which provider's monthly quota (see `AppConfig`) is still available.
class LocationPicker {
  LocationPicker._();

  static Future<PickedLocation?> pickLocation(
    BuildContext context, {
    PickedLocation? initialLocation,
  }) async {
    final provider = await MapProviderResolver.resolveActiveProvider();
    await MapProviderResolver.recordUse(provider);
    if (!context.mounted) return null;
    switch (provider) {
      case MapProviderKind.baato:
        return Navigator.of(context).push<PickedLocation>(
          MaterialPageRoute(
            builder: (_) => _BaatoLocationPickerPage(
              initialLocation: initialLocation,
            ),
          ),
        );
      case MapProviderKind.galli:
        return _pickWithGalli(context, initialLocation);
      case MapProviderKind.osm:
        return Navigator.of(context).push<PickedLocation>(
          MaterialPageRoute(
            builder: (_) => _OsmLocationPickerPage(
              initialLocation: initialLocation,
            ),
          ),
        );
    }
  }
}

/// Small (~150px) static, non-interactive preview of a picked location, used
/// on review/summary screens. Doesn't count against any provider's monthly
/// quota — only the interactive picker does.
class LocationPreview extends StatelessWidget {
  const LocationPreview({required this.location, super.key});

  final PickedLocation location;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 150,
        child: FutureBuilder<MapProviderKind>(
          future: MapProviderResolver.resolveActiveProvider(),
          builder: (context, snapshot) {
            final provider = snapshot.data;
            if (provider == null) {
              return ColoredBox(color: context.colors.cardAlt);
            }
            switch (provider) {
              case MapProviderKind.baato:
                return _BaatoStaticPreview(location: location);
              case MapProviderKind.galli:
                return galli.GalliLocationViewScreen(
                  locations: [
                    galli.GalliMapLocation(
                      latitude: location.latitude,
                      longitude: location.longitude,
                      name: location.name,
                      address: location.address,
                    ),
                  ],
                  showBackButton: false,
                );
              case MapProviderKind.osm:
                return _OsmStaticPreview(location: location);
            }
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Baato
// ---------------------------------------------------------------------------

class _BaatoStaticPreview extends StatelessWidget {
  const _BaatoStaticPreview({required this.location});

  final PickedLocation location;

  @override
  Widget build(BuildContext context) {
    final position = BaatoCoordinate(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return IgnorePointer(
      child: BaatoMap(
        initialPosition: position,
        initialZoom: 15,
        zoomGesturesEnabled: false,
        scrollGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        compassEnabled: false,
        onMapCreated: (controller) {
          controller.markerManager.addMarker(
            BaatoSymbolOption(geometry: position),
          );
        },
      ),
    );
  }
}

class _BaatoLocationPickerPage extends StatefulWidget {
  const _BaatoLocationPickerPage({this.initialLocation});

  final PickedLocation? initialLocation;

  @override
  State<_BaatoLocationPickerPage> createState() =>
      _BaatoLocationPickerPageState();
}

class _BaatoLocationPickerPageState extends State<_BaatoLocationPickerPage> {
  static final _bounds = mlg.LatLngBounds(
    southwest: LatLng(NepalGeo.minLatitude, NepalGeo.minLongitude),
    northeast: LatLng(NepalGeo.maxLatitude, NepalGeo.maxLongitude),
  );

  BaatoMapController? _mapController;
  late BaatoCoordinate _selected;
  String? _address;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    final validInitial = initial != null &&
        NepalGeo.isWithinKathmanduValley(initial.latitude, initial.longitude);
    _selected = validInitial
        ? BaatoCoordinate(latitude: initial.latitude, longitude: initial.longitude)
        : BaatoCoordinate(
            latitude: NepalGeo.defaultMapCenter.$1,
            longitude: NepalGeo.defaultMapCenter.$2,
          );
    _address = validInitial ? initial.address ?? initial.name : null;
    if (!validInitial) {
      unawaited(_useCurrentLocation());
    }
  }

  Future<void> _placeMarker() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.markerManager.clearMarkers();
    await controller.markerManager.addMarker(
      BaatoSymbolOption(geometry: _selected),
    );
  }

  Future<void> _select(BaatoCoordinate location, {String? resolvedAddress}) async {
    if (!NepalGeo.isWithinKathmanduValley(location.latitude, location.longitude)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_outOfAreaMessage)));
      }
      return;
    }
    setState(() {
      _selected = location;
      _address = resolvedAddress;
    });
    await _placeMarker();
    await _mapController?.cameraManager?.moveTo(location, zoom: 16);
    if (resolvedAddress != null) return;
    try {
      final response = await Baato.api.place.reverseGeocode(location);
      final data = response.data;
      final place = (data != null && data.isNotEmpty) ? data.first : null;
      if (place != null && mounted) {
        setState(() => _address = place.address.isNotEmpty ? place.address : place.name);
        return;
      }
    } catch (_) {
      // Fall through to the device geocoder below.
    }
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
      if (parts.isNotEmpty) setState(() => _address = parts.join(', '));
    } catch (_) {
      // Coordinates remain selectable even when reverse geocoding fails.
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
      final location = BaatoCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!NepalGeo.isWithinKathmanduValley(location.latitude, location.longitude)) {
        return;
      }
      await _select(location);
    } catch (_) {
      // Kathmandu remains the fallback when GPS is unavailable.
    } finally {
      if (mounted) setState(() => _locating = false);
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
          BaatoMap(
            initialPosition: _selected,
            initialZoom: 15,
            cameraTargetBounds: CameraTargetBounds(_bounds),
            myLocationEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _placeMarker();
            },
            onMapClick: (_, coordinate) => _select(
              BaatoCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: BaatoPlaceAutoSuggestion(
                hintText: 'Search in Kathmandu, Nepal',
                currentCoordinate: _selected,
                onPlaceSelected: (_) {},
                onPlaceDetailsRetrieved: (place) {
                  _select(
                    place.centroid,
                    resolvedAddress:
                        place.address.isNotEmpty ? place.address : place.name,
                  );
                },
                inputDecoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (_address != null)
            _ConfirmCard(address: _address!, onConfirm: _confirm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Galli
// ---------------------------------------------------------------------------

Future<PickedLocation?> _pickWithGalli(
  BuildContext context,
  PickedLocation? initialLocation,
) async {
  final initial = initialLocation != null &&
          NepalGeo.isWithinKathmanduValley(
            initialLocation.latitude,
            initialLocation.longitude,
          )
      ? LatLng(initialLocation.latitude, initialLocation.longitude)
      : LatLng(NepalGeo.defaultMapCenter.$1, NepalGeo.defaultMapCenter.$2);

  while (true) {
    if (!context.mounted) return null;
    final picked = await galli.GalliLocationPicker.pickLocation(
      context,
      initialCoordinates: initial,
      useGalliBrand: false,
    );
    if (picked == null) return null;
    if (NepalGeo.isWithinKathmanduValley(picked.latitude, picked.longitude)) {
      return PickedLocation(
        latitude: picked.latitude,
        longitude: picked.longitude,
        name: picked.name,
        address: picked.address,
      );
    }
    if (!context.mounted) return null;
    final tryAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Outside the delivery area'),
        content: const Text(_outOfAreaMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
    if (tryAgain != true) return null;
  }
}

// ---------------------------------------------------------------------------
// OpenStreetMap (last-resort, uncapped fallback)
// ---------------------------------------------------------------------------

// The standard OSM tile server is meant for low-volume use; it's only ever
// reached here once both paid providers' monthly quotas are exhausted.
const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class _OsmStaticPreview extends StatelessWidget {
  const _OsmStaticPreview({required this.location});

  final PickedLocation location;

  @override
  Widget build(BuildContext context) {
    final point = ll.LatLng(location.latitude, location.longitude);
    return IgnorePointer(
      child: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: 15),
        children: [
          TileLayer(urlTemplate: _osmTileUrl, userAgentPackageName: 'com.godokan.godelivery'),
          MarkerLayer(markers: [
            Marker(
              point: point,
              width: 32,
              height: 32,
              child: Icon(LucideIcons.mapPin, color: AppColors.primary, size: 32),
            ),
          ]),
        ],
      ),
    );
  }
}

class _OsmLocationPickerPage extends StatefulWidget {
  const _OsmLocationPickerPage({this.initialLocation});

  final PickedLocation? initialLocation;

  @override
  State<_OsmLocationPickerPage> createState() => _OsmLocationPickerPageState();
}

class _OsmLocationPickerPageState extends State<_OsmLocationPickerPage> {
  static final _bounds = LatLngBounds(
    ll.LatLng(NepalGeo.minLatitude, NepalGeo.minLongitude),
    ll.LatLng(NepalGeo.maxLatitude, NepalGeo.maxLongitude),
  );

  final _mapController = MapController();
  final _searchController = TextEditingController();
  late ll.LatLng _selected;
  String? _address;
  bool _searching = false;
  bool _locating = false;
  List<PhotonResult> _suggestions = const [];
  Timer? _suggestionDebounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    final validInitial = initial != null &&
        NepalGeo.isWithinKathmanduValley(initial.latitude, initial.longitude);
    _selected = validInitial
        ? ll.LatLng(initial.latitude, initial.longitude)
        : ll.LatLng(NepalGeo.defaultMapCenter.$1, NepalGeo.defaultMapCenter.$2);
    _address = validInitial ? initial.address ?? initial.name : null;
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

  Future<void> _select(ll.LatLng location, [String? resolvedAddress]) async {
    if (!NepalGeo.isWithinKathmanduValley(location.latitude, location.longitude)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_outOfAreaMessage)));
      }
      return;
    }
    setState(() {
      _selected = location;
      _address = resolvedAddress;
    });
    _mapController.move(location, 16);
    if (resolvedAddress != null) return;
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
      if (parts.isNotEmpty) setState(() => _address = parts.join(', '));
    } catch (_) {
      // Coordinates remain selectable even when reverse geocoding fails.
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
      final location = ll.LatLng(position.latitude, position.longitude);
      if (!NepalGeo.isWithinKathmanduValley(location.latitude, location.longitude)) {
        return;
      }
      await _select(location);
    } catch (_) {
      // Kathmandu remains the fallback when GPS is unavailable.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() => _searching = true);
    try {
      final results = await PhotonSearch.search(query);
      if (results.isEmpty) throw const FormatException();
      final first = results.first;
      await _select(ll.LatLng(first.latitude, first.longitude), first.label);
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

  void _onSearchChanged(String value) {
    _suggestionDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _suggestionDebounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await PhotonSearch.search(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _suggestions = results);
    });
  }

  Future<void> _chooseSuggestion(PhotonResult suggestion) async {
    FocusScope.of(context).unfocus();
    _searchController.text = suggestion.label;
    setState(() => _suggestions = const []);
    await _select(ll.LatLng(suggestion.latitude, suggestion.longitude), suggestion.label);
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 15,
              cameraConstraint: CameraConstraint.containCenter(bounds: _bounds),
              onTap: (_, point) => _select(point),
            ),
            children: [
              TileLayer(
                urlTemplate: _osmTileUrl,
                userAgentPackageName: 'com.godokan.godelivery',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _selected,
                  width: 36,
                  height: 36,
                  child: Icon(LucideIcons.mapPin, color: AppColors.primary, size: 36),
                ),
              ]),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
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
                                suggestion.label,
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
            _ConfirmCard(address: _address!, onConfirm: _confirm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared confirm card
// ---------------------------------------------------------------------------

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({required this.address, required this.onConfirm});

  final String address;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              Text(address, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Confirm location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
