import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/nepal_geo.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/locations_repository.dart';
import '../../models/saved_location.dart';
import '../../providers/saved_locations_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/city_province_fields.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/primary_button.dart';

/// Add or edit a saved pickup address (`POST`/`PATCH /locations`).
class SavedAddressFormPage extends ConsumerStatefulWidget {
  const SavedAddressFormPage({super.key, this.existing});

  final SavedLocation? existing;

  @override
  ConsumerState<SavedAddressFormPage> createState() =>
      _SavedAddressFormPageState();
}

class _SavedAddressFormPageState extends ConsumerState<SavedAddressFormPage> {
  late final _labelController = TextEditingController(
    text: widget.existing?.label,
  );
  late final _landmarkController = TextEditingController(
    text: widget.existing?.landmark,
  );

  PickedLocation? _pickedLocation;
  String _city = NepalGeo.defaultCity;
  String _province = NepalGeo.defaultProvince;
  bool _isDefault = false;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _pickedLocation = PickedLocation(
        latitude: existing.latitude,
        longitude: existing.longitude,
        address: existing.addressLine,
      );
      _city = existing.city ?? NepalGeo.defaultCity;
      _province = existing.state ?? NepalGeo.defaultProvince;
      _isDefault = existing.isDefault;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  bool get _isValid => _pickedLocation != null;

  Future<void> _pickLocation() async {
    final picked = await LocationPicker.pickLocation(
      context,
      initialLocation: _pickedLocation,
    );
    if (picked != null) {
      setState(() => _pickedLocation = picked);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final location = _pickedLocation!;
    final label = _labelController.text.trim();
    final landmark = _landmarkController.text.trim();
    try {
      final repo = ref.read(locationsRepositoryProvider);
      if (_isEditing) {
        await repo.update(
          widget.existing!.id,
          label: label.isEmpty ? null : label,
          addressLine: location.address ?? location.name ?? 'Pickup location',
          landmark: landmark.isEmpty ? null : landmark,
          city: _city,
          state: _province,
          country: 'Nepal',
          latitude: location.latitude,
          longitude: location.longitude,
          isDefault: _isDefault,
        );
      } else {
        await repo.create(
          label: label.isEmpty ? null : label,
          addressLine: location.address ?? location.name ?? 'Pickup location',
          landmark: landmark.isEmpty ? null : landmark,
          city: _city,
          state: _province,
          country: 'Nepal',
          latitude: location.latitude,
          longitude: location.longitude,
          isDefault: _isDefault,
        );
      }
      await ref.read(savedLocationsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not save the address. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit address' : 'Add address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _labelController,
              label: 'Label (optional)',
              hint: 'e.g. Main shop, Warehouse',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              'Location',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickLocation,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: _pickedLocation != null
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 18, color: context.colors.text),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedLocation?.address ??
                            _pickedLocation?.name ??
                            'Pick this address on the map',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _pickedLocation != null
                              ? context.colors.text
                              : context.colors.textMuted,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: context.colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _landmarkController,
              label: 'Landmark (optional)',
              hint: 'e.g. Near City Hospital',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            CityProvinceFields(
              city: _city,
              province: _province,
              onCityChanged: (value) => setState(() => _city = value),
              onProvinceChanged: (value) => setState(() => _province = value),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                title: const Text(
                  'Default pickup address',
                  style: TextStyle(fontSize: 13.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Save address',
              enabled: _isValid,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
