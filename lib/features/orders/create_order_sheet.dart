import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/payment_display.dart';
import '../../core/utils/validators.dart';
import '../../data/media_repository.dart';
import '../../data/order_repository.dart';
import '../../data/pricing_repository.dart';
import '../../data/user_repository.dart';
import '../../models/location.dart';
import '../../models/order.dart';
import '../../models/pricing.dart';
import '../../models/saved_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/saved_locations_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/sheet_header.dart';
import '../home/saved_addresses_page.dart';

class CreateOrderSheet extends ConsumerStatefulWidget {
  const CreateOrderSheet({super.key});

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _PackageImageDraft {
  _PackageImageDraft({required this.bytes});

  final Uint8List bytes;
  String? assetId;
  bool uploading = true;
}

class _PackageDraftControllers {
  _PackageDraftControllers()
    : nameController = TextEditingController(),
      weightController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController weightController;
  final List<_PackageImageDraft> images = [];
  bool isDangerous = false;
  bool isFragile = true;
  bool isFlammable = true;
  bool needsToBeDry = true;
  bool moreInfoExpanded = false;

  void dispose() {
    nameController.dispose();
    weightController.dispose();
  }
}

enum _PickupMode { shopDefault, saved, custom }

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pickupContactNameController = TextEditingController();
  final _pickupContactPhoneController = TextEditingController();
  final List<_PackageDraftControllers> _packages = [_PackageDraftControllers()];

  PickedLocation? _deliveryLocation;
  _PickupMode _pickupMode = _PickupMode.shopDefault;
  SavedLocation? _selectedSavedLocation;
  PickedLocation? _customPickupLocation;
  DateTime? _scheduledPickupDate;
  Timer? _lookupDebounce;
  Timer? _estimateDebounce;
  bool _looking = false;
  EstimateResult? _estimate;
  bool _estimating = false;
  bool _submitting = false;
  OrderPayer _payer = OrderPayer.sender;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _pickupContactNameController.dispose();
    _pickupContactPhoneController.dispose();
    for (final p in _packages) {
      p.dispose();
    }
    _lookupDebounce?.cancel();
    _estimateDebounce?.cancel();
    super.dispose();
  }

  /// Coordinates of the currently selected pickup point, for the price
  /// estimate — null while that selection isn't resolved yet.
  (double, double)? get _pickupCoordinates {
    switch (_pickupMode) {
      case _PickupMode.shopDefault:
        final shop = ref.read(authControllerProvider).user?.shopLocation;
        return shop == null ? null : (shop.latitude, shop.longitude);
      case _PickupMode.saved:
        final saved = _selectedSavedLocation;
        return saved == null ? null : (saved.latitude, saved.longitude);
      case _PickupMode.custom:
        final custom = _customPickupLocation;
        return custom == null ? null : (custom.latitude, custom.longitude);
    }
  }

  String get _pickupSummary {
    switch (_pickupMode) {
      case _PickupMode.shopDefault:
        final shop = ref.read(authControllerProvider).user?.shopLocation;
        return shop?.addressLine ?? 'Your shop location';
      case _PickupMode.saved:
        final saved = _selectedSavedLocation;
        return saved == null
            ? 'Choose pickup location'
            : (saved.label ?? saved.addressLine);
      case _PickupMode.custom:
        final custom = _customPickupLocation;
        return custom == null
            ? 'Choose pickup location'
            : (custom.address ?? custom.name ?? 'Pickup location');
    }
  }

  Future<void> _choosePickupLocation() async {
    final selection = await showModalBottomSheet<_PickupSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PickupLocationSheet(
        currentMode: _pickupMode,
        currentSavedLocation: _selectedSavedLocation,
      ),
    );
    if (selection == null || !mounted) return;
    switch (selection) {
      case _ShopDefaultSelection():
        setState(() {
          _pickupMode = _PickupMode.shopDefault;
          _selectedSavedLocation = null;
        });
      case _SavedLocationSelection(:final location):
        setState(() {
          _pickupMode = _PickupMode.saved;
          _selectedSavedLocation = location;
        });
      case _CustomLocationSelection():
        final picked = await LocationPicker.pickLocation(
          context,
          initialLocation: _customPickupLocation,
        );
        if (picked == null || !mounted) return;
        setState(() {
          _pickupMode = _PickupMode.custom;
          _customPickupLocation = picked;
        });
    }
    _scheduleEstimate();
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledPickupDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _scheduledPickupDate = picked);
    }
  }

  void _onPhoneChanged(String value) {
    _lookupDebounce?.cancel();
    if (!isValidNepaliMobileNumber(value)) return;
    _lookupDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _lookup(value.trim()),
    );
  }

  Future<void> _lookup(String localNumber) async {
    setState(() => _looking = true);
    try {
      final result = await ref.read(userRepositoryProvider).lookup(localNumber);
      if (!mounted) return;
      if (result.exists) {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = result.name ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = result.email ?? '';
          }
        });
      }
    } catch (_) {
      // Lookup is a convenience prefill only — failures are silent.
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _pickDeliveryLocation() async {
    final picked = await LocationPicker.pickLocation(
      context,
      initialLocation: _deliveryLocation,
    );
    if (picked != null) {
      setState(() => _deliveryLocation = picked);
      _scheduleEstimate();
    }
  }

  void _addPackage() {
    setState(() => _packages.add(_PackageDraftControllers()));
  }

  void _removePackage(int index) {
    setState(() {
      _packages[index].dispose();
      _packages.removeAt(index);
    });
    _scheduleEstimate();
  }

  void _scheduleEstimate() {
    _estimateDebounce?.cancel();
    _estimateDebounce = Timer(
      const Duration(milliseconds: 500),
      _computeEstimate,
    );
  }

  double _totalWeightKg() {
    var total = 0.0;
    for (final p in _packages) {
      total += double.tryParse(p.weightController.text.trim()) ?? 0;
    }
    return total;
  }

  Future<void> _computeEstimate() async {
    final pickup = _pickupCoordinates;
    final delivery = _deliveryLocation;
    final totalWeight = _totalWeightKg();
    if (pickup == null || delivery == null || totalWeight <= 0) {
      setState(() => _estimate = null);
      return;
    }
    setState(() => _estimating = true);
    try {
      final result = await ref
          .read(pricingRepositoryProvider)
          .estimate(
            EstimateRequest(
              pickup: Coordinates(latitude: pickup.$1, longitude: pickup.$2),
              delivery: Coordinates(
                latitude: delivery.latitude,
                longitude: delivery.longitude,
              ),
              totalWeightKg: totalWeight,
              hasDangerousGoods: _packages.any((p) => p.isDangerous),
            ),
          );
      if (!mounted) return;
      setState(() => _estimate = result);
    } catch (_) {
      if (mounted) setState(() => _estimate = null);
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  bool get _isValid {
    if (!isValidNepaliMobileNumber(_phoneController.text)) return false;
    if (_nameController.text.trim().isEmpty) return false;
    if (_deliveryLocation == null) return false;
    if (_pickupMode == _PickupMode.saved && _selectedSavedLocation == null) {
      return false;
    }
    if (_pickupMode == _PickupMode.custom && _customPickupLocation == null) {
      return false;
    }
    for (final p in _packages) {
      if (p.nameController.text.trim().isEmpty) return false;
      final weight = double.tryParse(p.weightController.text.trim());
      if (weight == null || weight <= 0) return false;
      if (p.images.any((image) => image.uploading)) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final delivery = _deliveryLocation!;
    try {
      final custom = _customPickupLocation;
      final order = await ref
          .read(orderRepositoryProvider)
          .create(
            pickupLocationId: _pickupMode == _PickupMode.saved
                ? _selectedSavedLocation?.id
                : null,
            pickupLocation: _pickupMode == _PickupMode.custom && custom != null
                ? LocationInput(
                    addressLine:
                        custom.address ?? custom.name ?? 'Pickup location',
                    latitude: custom.latitude,
                    longitude: custom.longitude,
                  )
                : null,
            pickupContactName: _pickupContactNameController.text.trim().isEmpty
                ? null
                : _pickupContactNameController.text.trim(),
            pickupContactPhone:
                _pickupContactPhoneController.text.trim().isEmpty
                ? null
                : _pickupContactPhoneController.text.trim(),
            scheduledPickupDate: _scheduledPickupDate,
            receiverName: _nameController.text.trim(),
            receiverPhoneNumber: _phoneController.text.trim(),
            receiverEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            receiverLocation: LocationInput(
              addressLine:
                  delivery.address ?? delivery.name ?? 'Delivery location',
              latitude: delivery.latitude,
              longitude: delivery.longitude,
            ),
            packages: _packages
                .map(
                  (p) => PackageDraft(
                    name: p.nameController.text.trim(),
                    weightKg: double.parse(p.weightController.text.trim()),
                    isDangerous: p.isDangerous,
                    isFragile: p.isFragile,
                    isFlammable: p.isFlammable,
                    needsToBeDry: p.needsToBeDry,
                    imageAssetIds: p.images
                        .map((image) => image.assetId)
                        .whereType<String>()
                        .toList(),
                  ),
                )
                .toList(),
            payer: _payer,
            paymentMethod: PaymentMethod.cod,
          );
      ref.invalidate(ordersProvider(OrderRoleFilter.sent));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shipment created — tracking number ${order.trackingNumber}',
          ),
        ),
      );
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not create the shipment.';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    children: [
                      SheetHeader(
                        title: 'New shipment',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Receiver',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        hint: '98XXXXXXXX',
                        keyboardType: TextInputType.phone,
                        onChanged: _onPhoneChanged,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        maxLength: 10,
                        helperText: '10 digits, starting with 98, 97, or 96',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Align(
                            widthFactor: 1,
                            child: Text(
                              '+977',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        suffix: _looking
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'Receiver name',
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _emailController,
                        label: 'Email (optional)',
                        hint: 'receiver@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _LocationPickerField(
                        location: _deliveryLocation,
                        onTap: _pickDeliveryLocation,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pickup',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _PickupSummaryField(
                        summary: _pickupSummary,
                        onTap: _choosePickupLocation,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _pickupContactNameController,
                        label: 'Pickup contact (optional)',
                        hint: 'Defaults to you',
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _pickupContactPhoneController,
                        label: 'Pickup contact phone (optional)',
                        hint: '98XXXXXXXX',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        maxLength: 10,
                        helperText: 'Defaults to your number if left blank',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Align(
                            widthFactor: 1,
                            child: Text(
                              '+977',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ScheduledPickupField(
                        date: _scheduledPickupDate,
                        onTap: _pickScheduledDate,
                        onClear: () =>
                            setState(() => _scheduledPickupDate = null),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Packages',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: _addPackage,
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._packages.asMap().entries.map(
                        (entry) => _PackageFormRow(
                          controllers: entry.value,
                          canRemove: _packages.length > 1,
                          onChanged: () {
                            setState(() {});
                            _scheduleEstimate();
                          },
                          onRemove: () => _removePackage(entry.key),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_estimating)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Estimating price…',
                                style: TextStyle(
                                  color: context.colors.textMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_estimate != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.receipt, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Estimated cost: ${_estimate!.amount} ${_estimate!.currency} '
                                  '(${_estimate!.distanceKm.toStringAsFixed(1)} km)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Payment',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _PayerSelector(
                        payer: _payer,
                        onChanged: (payer) => setState(() => _payer = payer),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Create shipment',
                        enabled: _isValid,
                        loading: _submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

sealed class _PickupSelection {
  const _PickupSelection();
}

class _ShopDefaultSelection extends _PickupSelection {
  const _ShopDefaultSelection();
}

class _SavedLocationSelection extends _PickupSelection {
  const _SavedLocationSelection(this.location);

  final SavedLocation location;
}

class _CustomLocationSelection extends _PickupSelection {
  const _CustomLocationSelection();
}

class _PickupSummaryField extends StatelessWidget {
  const _PickupSummaryField({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.cardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.store, size: 18, color: context.colors.text),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
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
    );
  }
}

class _ScheduledPickupField extends StatelessWidget {
  const _ScheduledPickupField({
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.cardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendarClock, size: 18, color: context.colors.text),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date == null
                    ? 'Pickup date: as soon as possible'
                    : 'Pickup date: ${DateFormat('MMM d, y').format(date!)}',
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            if (date != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(LucideIcons.x, size: 16),
                visualDensity: VisualDensity.compact,
              )
            else
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _PickupLocationSheet extends ConsumerWidget {
  const _PickupLocationSheet({
    required this.currentMode,
    required this.currentSavedLocation,
  });

  final _PickupMode currentMode;
  final SavedLocation? currentSavedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopLocation = ref.watch(authControllerProvider).user?.shopLocation;
    final savedLocations = ref.watch(savedLocationsProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Choose pickup location'),
            const SizedBox(height: 12),
            if (shopLocation != null)
              _PickupOptionTile(
                icon: LucideIcons.store,
                title: 'Shop location',
                subtitle: shopLocation.addressLine,
                selected: currentMode == _PickupMode.shopDefault,
                onTap: () => Navigator.of(
                  context,
                ).pop(const _ShopDefaultSelection()),
              ),
            savedLocations.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (locations) => Column(
                children: [
                  for (final location in locations)
                    _PickupOptionTile(
                      icon: LucideIcons.mapPin,
                      title: location.label ?? location.addressLine,
                      subtitle: location.addressLine,
                      selected:
                          currentMode == _PickupMode.saved &&
                          currentSavedLocation?.id == location.id,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_SavedLocationSelection(location)),
                    ),
                ],
              ),
            ),
            _PickupOptionTile(
              icon: LucideIcons.mapPinned,
              title: 'Pick a one-off location',
              subtitle: 'Not saved to your address book',
              selected: currentMode == _PickupMode.custom,
              onTap: () => Navigator.of(
                context,
              ).pop(const _CustomLocationSelection()),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SavedAddressesPage(),
                  ),
                );
              },
              icon: const Icon(LucideIcons.settings2, size: 16),
              label: const Text('Manage saved addresses'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupOptionTile extends StatelessWidget {
  const _PickupOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : context.colors.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.colors.text),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerField extends StatelessWidget {
  const _LocationPickerField({required this.location, required this.onTap});

  final PickedLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery location',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.cardAlt,
              borderRadius: BorderRadius.circular(14),
              border: location != null
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              children: [
                if (location != null) ...[
                  LocationPreview(location: location!),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: context.colors.text,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        location?.address ??
                            location?.name ??
                            'Pick delivery location on the map',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: location != null
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageFormRow extends ConsumerWidget {
  const _PackageFormRow({
    required this.controllers,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _PackageDraftControllers controllers;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.images),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final draft = _PackageImageDraft(bytes: bytes);
    controllers.images.add(draft);
    onChanged();

    final mimeType = picked.mimeType ?? 'image/jpeg';
    try {
      final ticket = await ref
          .read(mediaRepositoryProvider)
          .requestUploadUrl(
            purpose: 'PACKAGE_IMAGE',
            filename: picked.name,
            mimeType: mimeType,
            sizeBytes: bytes.length,
          );
      await ref
          .read(mediaRepositoryProvider)
          .uploadBytes(
            uploadUrl: ticket.uploadUrl,
            bytes: bytes,
            mimeType: mimeType,
          );
      draft
        ..assetId = ticket.assetId
        ..uploading = false;
    } catch (e) {
      controllers.images.remove(draft);
      if (context.mounted) {
        final message = e is ApiException
            ? "Couldn't upload photo: ${e.message}"
            : "Couldn't upload photo.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      onChanged();
    }
  }

  void _removePhoto(_PackageImageDraft draft) {
    controllers.images.remove(draft);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: controllers.nameController,
                  hint: 'Package name',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: controllers.weightController,
                  hint: 'Weight (kg)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          StatefulBuilder(
            builder: (context, setInner) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setInner(
                            () => controllers.moreInfoExpanded =
                                !controllers.moreInfoExpanded,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  controllers.moreInfoExpanded
                                      ? LucideIcons.chevronDown
                                      : LucideIcons.chevronRight,
                                  size: 16,
                                  color: context.colors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'More information',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (canRemove)
                        IconButton(
                          onPressed: onRemove,
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                  if (controllers.moreInfoExpanded)
                    Column(
                      children: [
                        _FlagCheckbox(
                          label: 'Fragile — handle with care',
                          value: controllers.isFragile,
                          onChanged: (value) {
                            setInner(() => controllers.isFragile = value);
                            onChanged();
                          },
                        ),
                        _FlagCheckbox(
                          label: 'Flammable',
                          value: controllers.isFlammable,
                          onChanged: (value) {
                            setInner(() => controllers.isFlammable = value);
                            onChanged();
                          },
                        ),
                        _FlagCheckbox(
                          label: 'Must be kept dry',
                          value: controllers.needsToBeDry,
                          onChanged: (value) {
                            setInner(() => controllers.needsToBeDry = value);
                            onChanged();
                          },
                        ),
                        _FlagCheckbox(
                          label: 'Contains dangerous goods',
                          value: controllers.isDangerous,
                          onChanged: (value) {
                            setInner(() => controllers.isDangerous = value);
                            onChanged();
                          },
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: _PackagePhotosRow(
              images: controllers.images,
              onAdd: () => _addPhoto(context, ref),
              onRemove: _removePhoto,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagCheckbox extends StatelessWidget {
  const _FlagCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

class _PackagePhotosRow extends StatelessWidget {
  const _PackagePhotosRow({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PackageImageDraft> images;
  final VoidCallback onAdd;
  final ValueChanged<_PackageImageDraft> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final image in images)
          _PackagePhotoThumb(image: image, onRemove: () => onRemove(image)),
        _AddPhotoTile(onTap: onAdd),
      ],
    );
  }
}

class _PackagePhotoThumb extends StatelessWidget {
  const _PackagePhotoThumb({required this.image, required this.onRemove});

  final _PackageImageDraft image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            image.bytes,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        if (image.uploading)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          LucideIcons.imagePlus,
          size: 20,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}

class _PayerSelector extends StatelessWidget {
  const _PayerSelector({required this.payer, required this.onChanged});

  final OrderPayer payer;
  final ValueChanged<OrderPayer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in OrderPayer.values)
            Expanded(
              child: _SelectableSegment(
                label: orderPayerLabel(option),
                selected: payer == option,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectableSegment extends StatelessWidget {
  const _SelectableSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
