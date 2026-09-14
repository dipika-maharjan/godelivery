import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/warehouses_repository.dart';
import '../../../models/location.dart';
import '../../../models/warehouse.dart';
import '../../../providers/warehouses_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/location_picker.dart';
import '../../../widgets/primary_button.dart';

/// Create or edit a warehouse (`POST`/`PATCH /warehouses`).
class WarehouseFormPage extends ConsumerStatefulWidget {
  const WarehouseFormPage({super.key, this.existing});

  final Warehouse? existing;

  @override
  ConsumerState<WarehouseFormPage> createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends ConsumerState<WarehouseFormPage> {
  late final _nameController = TextEditingController(text: widget.existing?.name);

  PickedLocation? _pickedLocation;
  bool _isActive = true;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _pickedLocation = PickedLocation(
        latitude: existing.location.latitude,
        longitude: existing.location.longitude,
        address: existing.location.addressLine,
      );
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _pickedLocation != null;

  Future<void> _pickLocation() async {
    final picked = await LocationPicker.pickLocation(
      context,
      initialLocation: _pickedLocation,
    );
    if (picked != null) setState(() => _pickedLocation = picked);
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final location = _pickedLocation!;
    final locationInput = LocationInput(
      addressLine: location.address ?? location.name ?? 'Warehouse location',
      latitude: location.latitude,
      longitude: location.longitude,
    );
    try {
      final repo = ref.read(warehousesRepositoryProvider);
      if (_isEditing) {
        await repo.update(
          widget.existing!.id,
          name: _nameController.text.trim(),
          location: locationInput,
          isActive: _isActive,
        );
      } else {
        await repo.create(name: _nameController.text.trim(), location: locationInput);
      }
      await ref.read(warehousesProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not save the warehouse. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit warehouse' : 'New warehouse'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Kathmandu sorting hub',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
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
                            'Pick the warehouse location on the map',
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
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.colors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Active', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text(
                    'Inactive warehouses are skipped for new order routing',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Create warehouse',
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
