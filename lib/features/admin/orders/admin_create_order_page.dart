import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/order_repository.dart';
import '../../../data/media_repository.dart';
import '../../../data/pricing_repository.dart';
import '../../../data/user_repository.dart';
import '../../../models/location.dart';
import '../../../models/order.dart';
import '../../../models/pricing.dart';
import '../../../models/user.dart';
import '../../../providers/admin_orders_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/location_picker.dart';
import '../../../widgets/primary_button.dart';

class AdminCreateOrderPage extends ConsumerStatefulWidget {
  const AdminCreateOrderPage({super.key});

  @override
  ConsumerState<AdminCreateOrderPage> createState() =>
      _AdminCreateOrderPageState();
}

class _AdminPackage {
  final name = TextEditingController();
  final weight = TextEditingController();
  final length = TextEditingController();
  final width = TextEditingController();
  final height = TextEditingController();
  bool dangerous = false;
  bool fragile = true;
  bool flammable = true;
  bool dry = true;
  bool moreInfoExpanded = false;
  final imageAssetIds = <String>[];
  bool uploadingImage = false;

  void dispose() {
    name.dispose();
    weight.dispose();
    length.dispose();
    width.dispose();
    height.dispose();
  }
}

class _AdminCreateOrderPageState extends ConsumerState<AdminCreateOrderPage> {
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _senderEmail = TextEditingController();
  final _senderContactName = TextEditingController();
  final _senderContactPhone = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _pickupLandmark = TextEditingController();
  final _pickupCity = TextEditingController();
  final _pickupState = TextEditingController();
  final _pickupPostalCode = TextEditingController();
  final _pickupCountry = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _receiverEmail = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _deliveryLandmark = TextEditingController();
  final _deliveryCity = TextEditingController();
  final _deliveryState = TextEditingController();
  final _deliveryPostalCode = TextEditingController();
  final _deliveryCountry = TextEditingController();
  final _remarks = TextEditingController();
  final _codAmount = TextEditingController();
  final _packages = <_AdminPackage>[_AdminPackage()];

  PickedLocation? _pickup;
  PickedLocation? _delivery;
  DeliveryType _deliveryType = DeliveryType.normal;
  DateTime? _scheduledDate;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  OrderPayer _payer = OrderPayer.sender;
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  EstimateResult? _estimate;
  bool _estimating = false;
  bool _submitting = false;

  @override
  void dispose() {
    for (final package in _packages) {
      package.dispose();
    }
    for (final controller in [
      _senderName,
      _senderPhone,
      _senderEmail,
      _senderContactName,
      _senderContactPhone,
      _pickupAddress,
      _pickupLandmark,
      _pickupCity,
      _pickupState,
      _pickupPostalCode,
      _pickupCountry,
      _receiverName,
      _receiverPhone,
      _receiverEmail,
      _deliveryAddress,
      _deliveryLandmark,
      _deliveryCity,
      _deliveryState,
      _deliveryPostalCode,
      _deliveryCountry,
      _remarks,
      _codAmount,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _validPhones =>
      isValidNepaliMobileNumber(_senderPhone.text) &&
      isValidNepaliMobileNumber(_receiverPhone.text);

  String? get _scheduleError {
    if (_deliveryType != DeliveryType.scheduled) return null;
    if (_scheduledDate == null) return 'Choose a scheduled pickup date.';
    if (_scheduledDate!.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return 'Scheduled pickup date cannot be in the past.';
    }
    final start = _start.hour * 60 + _start.minute;
    final end = _end.hour * 60 + _end.minute;
    if (end <= start) return 'Pickup end time must be after start time.';
    return null;
  }

  bool get _validPackages => _packages.every((package) {
    final weight = double.tryParse(package.weight.text.trim());
    return package.name.text.trim().isNotEmpty && weight != null && weight > 0;
  });

  bool get _validCodAmount =>
      _paymentMethod != PaymentMethod.cod ||
      _codAmount.text.trim().isEmpty ||
      (double.tryParse(_codAmount.text.trim()) ?? 0) > 0;

  bool _validLocation(
    PickedLocation? location,
    TextEditingController address,
  ) => location != null && address.text.trim().isNotEmpty;

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _isValid =>
      _senderName.text.trim().isNotEmpty &&
      _validPhones &&
      _validLocation(_pickup, _pickupAddress) &&
      _validLocation(_delivery, _deliveryAddress) &&
      _receiverName.text.trim().isNotEmpty &&
      _validPackages &&
      _validCodAmount &&
      _scheduleError == null;

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickLocation({required bool pickup}) async {
    final result = await LocationPicker.pickLocation(
      context,
      initialLocation: pickup ? _pickup : _delivery,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup = result;
        if (_pickupAddress.text.trim().isEmpty) {
          _pickupAddress.text = result.address ?? result.name ?? '';
        }
      } else {
        _delivery = result;
        if (_deliveryAddress.text.trim().isEmpty) {
          _deliveryAddress.text = result.address ?? result.name ?? '';
        }
      }
    });
    await _estimatePrice();
  }

  Future<void> _lookupReceiver() async {
    final phone = _receiverPhone.text.trim();
    if (!isValidNepaliMobileNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid receiver phone number.')),
      );
      return;
    }
    try {
      final result = await ref.read(userRepositoryProvider).lookup(phone);
      if (!mounted) return;
      if (!result.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No receiver found. You can enter new details.'),
          ),
        );
        return;
      }
      setState(() {
        if (result.name != null) _receiverName.text = result.name!;
        if (result.email != null) _receiverEmail.text = result.email!;
        final location = result.lastLocation;
        if (location != null) {
          _delivery = PickedLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            name: location.label,
            address: location.addressLine,
          );
          _deliveryAddress.text = location.addressLine;
          _deliveryLandmark.text = location.landmark ?? '';
          _deliveryCity.text = location.city ?? '';
          _deliveryState.text = location.state ?? '';
          _deliveryPostalCode.text = location.postalCode ?? '';
          _deliveryCountry.text = location.country ?? '';
        }
      });
      await _estimatePrice();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not look up the receiver.',
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final result = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (result != null) setState(() => _scheduledDate = result);
  }

  Future<void> _pickTime({required bool start}) async {
    final result = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (result == null) return;
    setState(() => start ? _start = result : _end = result);
  }

  Future<void> _estimatePrice() async {
    if (_pickup == null || _delivery == null || !_validPackages) {
      setState(() => _estimate = null);
      return;
    }

    setState(() => _estimating = true);
    try {
      final result = await ref
          .read(pricingRepositoryProvider)
          .estimate(
            EstimateRequest(
              pickup: Coordinates(
                latitude: _pickup!.latitude,
                longitude: _pickup!.longitude,
              ),
              delivery: Coordinates(
                latitude: _delivery!.latitude,
                longitude: _delivery!.longitude,
              ),
              totalWeightKg: _packages.fold(
                0,
                (sum, package) =>
                    sum + (double.tryParse(package.weight.text.trim()) ?? 0),
              ),
              hasDangerousGoods: _packages.any((package) => package.dangerous),
              deliveryType: _deliveryType,
            ),
          );
      if (mounted) setState(() => _estimate = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _estimate = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not calculate the delivery estimate.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  Future<void> _addPackageImage(_AdminPackage package) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() => package.uploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last;
      final mimeType = 'image/$extension';
      final ticket = await ref
          .read(mediaRepositoryProvider)
          .requestUploadUrl(
            purpose: 'PACKAGE_IMAGE',
            filename: file.name,
            mimeType: mimeType,
            sizeBytes: bytes.length,
          );
      await ref
          .read(mediaRepositoryProvider)
          .uploadBytes(
            uploadUrl: ticket.uploadUrl,
            bytes: Uint8List.fromList(bytes),
            mimeType: mimeType,
          );
      package.imageAssetIds.add(ticket.assetId);
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Could not upload image.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => package.uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_isValid) {
      final message =
          _scheduleError ??
          (!_validCodAmount ? 'COD amount must be greater than zero.' : null) ??
          (!_validPhones
              ? 'Enter valid sender and receiver phone numbers.'
              : 'Complete all required order fields.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .create(
            senderName: _senderName.text.trim(),
            senderPhoneNumber: _senderPhone.text.trim(),
            senderEmail: _senderEmail.text.trim(),
            pickupLocation: LocationInput(
              addressLine: _pickupAddress.text.trim(),
              landmark: _optionalText(_pickupLandmark),
              city: _optionalText(_pickupCity),
              state: _optionalText(_pickupState),
              postalCode: _optionalText(_pickupPostalCode),
              country: _optionalText(_pickupCountry),
              latitude: _pickup!.latitude,
              longitude: _pickup!.longitude,
            ),
            pickupContactName: _optionalText(_senderContactName),
            pickupContactPhone: _optionalText(_senderContactPhone),
            deliveryType: _deliveryType,
            scheduledPickupDate: _deliveryType == DeliveryType.scheduled
                ? _scheduledDate
                : null,
            pickupStartTime: _deliveryType == DeliveryType.scheduled
                ? _time(_start)
                : null,
            pickupEndTime: _deliveryType == DeliveryType.scheduled
                ? _time(_end)
                : null,
            payer: _payer,
            paymentMethod: _paymentMethod,
            codAmount: _paymentMethod == PaymentMethod.cod
                ? double.tryParse(_codAmount.text.trim())
                : null,
            remarks: _remarks.text.trim(),
            receiverName: _receiverName.text.trim(),
            receiverPhoneNumber: _receiverPhone.text.trim(),
            receiverEmail: _receiverEmail.text.trim(),
            receiverLocation: LocationInput(
              addressLine: _deliveryAddress.text.trim(),
              landmark: _optionalText(_deliveryLandmark),
              city: _optionalText(_deliveryCity),
              state: _optionalText(_deliveryState),
              postalCode: _optionalText(_deliveryPostalCode),
              country: _optionalText(_deliveryCountry),
              latitude: _delivery!.latitude,
              longitude: _delivery!.longitude,
            ),
            packages: _packages
                .map(
                  (package) => PackageDraft(
                    name: package.name.text.trim(),
                    weightKg: double.parse(package.weight.text.trim()),
                    lengthInches: double.tryParse(package.length.text.trim()),
                    widthInches: double.tryParse(package.width.text.trim()),
                    heightInches: double.tryParse(package.height.text.trim()),
                    isDangerous: package.dangerous,
                    isFragile: package.fragile,
                    isFlammable: package.flammable,
                    needsToBeDry: package.dry,
                    imageAssetIds: package.imageAssetIds,
                  ),
                )
                .toList(),
          );
      ref.invalidate(adminOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order.trackingNumber} created.')),
      );
      context.go('/admin/orders/${order.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Could not create order.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        ref.watch(authControllerProvider).user?.role == UserRole.admin;
    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to create orders.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to orders',
        ),
        title: const Text('New order'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _section('Sender', [
            AppTextField(
              controller: _senderName,
              label: 'Sender name *',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _senderPhone,
              label: 'Sender phone *',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _senderEmail,
              label: 'Sender email (optional)',
              keyboardType: TextInputType.emailAddress,
            ),
          ]),
          _section('Pickup location', [
            _LocationButton(
              label: 'Pickup location *',
              location: _pickup,
              onTap: () => _pickLocation(pickup: true),
            ),
            const SizedBox(height: 10),
            _LocationFields(
              address: _pickupAddress,
              landmark: _pickupLandmark,
              city: _pickupCity,
              state: _pickupState,
              postalCode: _pickupPostalCode,
              country: _pickupCountry,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _senderContactName,
              label: 'Pickup contact (optional)',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _senderContactPhone,
              label: 'Pickup contact phone (optional)',
              keyboardType: TextInputType.phone,
            ),
          ]),
          _section('Receiver', [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _receiverPhone,
                    label: 'Receiver phone *',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton(
                    onPressed: _lookupReceiver,
                    icon: const Icon(LucideIcons.search),
                    tooltip: 'Look up receiver',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _receiverName,
              label: 'Receiver name *',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _receiverEmail,
              label: 'Receiver email (optional)',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            _LocationButton(
              label: 'Delivery location *',
              location: _delivery,
              onTap: () => _pickLocation(pickup: false),
            ),
            const SizedBox(height: 10),
            _LocationFields(
              address: _deliveryAddress,
              landmark: _deliveryLandmark,
              city: _deliveryCity,
              state: _deliveryState,
              postalCode: _deliveryPostalCode,
              country: _deliveryCountry,
              onChanged: () => setState(() {}),
            ),
          ]),
          _section('Packages', [
            ..._packages.asMap().entries.map(
              (entry) => _PackageEditor(
                package: entry.value,
                index: entry.key,
                canRemove: _packages.length > 1,
                onChanged: () {
                  setState(() {});
                  _estimatePrice();
                },
                onAddImage: () => _addPackageImage(entry.value),
                onRemove: () => setState(() {
                  entry.value.dispose();
                  _packages.removeAt(entry.key);
                }),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _packages.add(_AdminPackage())),
              icon: const Icon(LucideIcons.plus, size: 17),
              label: const Text('Add package'),
            ),
          ]),
          _section('Delivery type', [
            for (final option in [
              (DeliveryType.express, 'Express', 'Pickup as soon as possible'),
              (DeliveryType.normal, 'Normal', 'Standard delivery service'),
              (
                DeliveryType.scheduled,
                'Scheduled',
                'Choose a pickup time slot',
              ),
            ])
              _DeliveryOption(
                type: option.$1,
                title: option.$2,
                description: option.$3,
                selectedType: _deliveryType,
                onTap: () {
                  setState(() => _deliveryType = option.$1);
                  _estimatePrice();
                },
              ),
            if (_deliveryType == DeliveryType.scheduled)
              _ScheduleFields(
                date: _scheduledDate,
                start: _start,
                end: _end,
                onDate: _pickDate,
                onStart: () => _pickTime(start: true),
                onEnd: () => _pickTime(start: false),
              ),
          ]),
          _section('Payment', [
            RadioListTile<OrderPayer>(
              value: OrderPayer.sender,
              groupValue: _payer,
              title: const Text('Sender pays delivery charge'),
              onChanged: (value) => setState(() => _payer = value!),
            ),
            RadioListTile<OrderPayer>(
              value: OrderPayer.receiver,
              groupValue: _payer,
              title: const Text('Receiver pays delivery charge'),
              onChanged: (value) => setState(() => _payer = value!),
            ),
            DropdownButtonFormField<PaymentMethod>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: PaymentMethod.values
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(_paymentLabel(method)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            if (_paymentMethod == PaymentMethod.cod) ...[
              const SizedBox(height: 10),
              AppTextField(
                controller: _codAmount,
                label: 'Cash to collect from receiver (optional)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter this only if the receiver still owes the sender for the product. It is separate from the delivery charge.',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted),
              ),
            ],
          ]),
          _section('Price estimate', [
            if (_estimating)
              const Center(child: CircularProgressIndicator())
            else if (_estimate == null)
              Text(
                'Choose locations and enter package weight to calculate pricing.',
                style: TextStyle(color: context.colors.textMuted),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery charge: ${_estimate!.amount} ${_estimate!.currency}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Distance: ${_estimate!.distanceKm.toStringAsFixed(1)} km · '
                    'Delivery type: ${deliveryTypeLabel(_deliveryType)}',
                  ),
                ],
              ),
          ]),
          AppTextField(controller: _remarks, label: 'Remarks (optional)'),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Create order',
            enabled: _isValid,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  String _paymentLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cod => 'COD',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.esewa => 'eSewa',
    PaymentMethod.khalti => 'Khalti',
    PaymentMethod.fonepay => 'Fonepay',
    PaymentMethod.connectIps => 'ConnectIPS',
  };
}

class _LocationFields extends StatelessWidget {
  const _LocationFields({
    required this.address,
    required this.landmark,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.onChanged,
  });

  final TextEditingController address;
  final TextEditingController landmark;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController postalCode;
  final TextEditingController country;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTextField(
        controller: address,
        label: 'Address *',
        onChanged: (_) => onChanged(),
      ),
      const SizedBox(height: 8),
      AppTextField(
        controller: landmark,
        label: 'Landmark',
        onChanged: (_) => onChanged(),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: city,
              label: 'City',
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextField(
              controller: state,
              label: 'State',
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: postalCode,
              label: 'Postal code',
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextField(
              controller: country,
              label: 'Country',
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    ],
  );
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.label,
    required this.location,
    required this.onTap,
  });

  final String label;
  final PickedLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: location == null ? context.colors.border : AppColors.primary,
          ),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.mapPin),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                location?.address ?? location?.name ?? label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.type,
    required this.title,
    required this.description,
    required this.selectedType,
    required this.onTap,
  });

  final DeliveryType type;
  final String title;
  final String description;
  final DeliveryType selectedType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedType == type;
    return Semantics(
      label: '$title delivery',
      hint: description,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : context.colors.cardAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: RadioListTile<DeliveryType>(
            value: type,
            groupValue: selectedType,
            title: Text(title),
            subtitle: Text(description),
            onChanged: (_) => onTap(),
          ),
        ),
      ),
    );
  }
}

class _ScheduleFields extends StatelessWidget {
  const _ScheduleFields({
    required this.date,
    required this.start,
    required this.end,
    required this.onDate,
    required this.onStart,
    required this.onEnd,
  });

  final DateTime? date;
  final TimeOfDay start;
  final TimeOfDay end;
  final VoidCallback onDate;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _PickerTile(
        label: date == null
            ? 'Pickup date *'
            : DateFormat('MMM d, y').format(date!),
        icon: LucideIcons.calendarClock,
        onTap: onDate,
      ),
      Row(
        children: [
          Expanded(
            child: _PickerTile(
              label: 'From ${_format(start)}',
              icon: LucideIcons.clock3,
              onTap: onStart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PickerTile(
              label: 'Until ${_format(end)}',
              icon: LucideIcons.clock3,
              onTap: onEnd,
            ),
          ),
        ],
      ),
    ],
  );

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    ),
  );
}

class _PackageEditor extends StatelessWidget {
  const _PackageEditor({
    required this.package,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onAddImage,
    required this.onRemove,
  });

  final _AdminPackage package;
  final int index;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onAddImage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
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
                controller: package.name,
                hint: 'Package name',
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: package.weight,
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
          builder: (context, setInner) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setInner(
                        () => package.moreInfoExpanded =
                            !package.moreInfoExpanded,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              package.moreInfoExpanded
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
              if (package.moreInfoExpanded)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: package.length,
                            hint: 'Length (in)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AppTextField(
                            controller: package.width,
                            hint: 'Width (in)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AppTextField(
                            controller: package.height,
                            hint: 'Height (in)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _flag('Fragile — handle with care', package.fragile, (v) {
                      package.fragile = v;
                      onChanged();
                    }),
                    _flag('Flammable', package.flammable, (v) {
                      package.flammable = v;
                      onChanged();
                    }),
                    _flag('Must be kept dry', package.dry, (v) {
                      package.dry = v;
                      onChanged();
                    }),
                    _flag('Contains dangerous goods', package.dangerous, (v) {
                      package.dangerous = v;
                      onChanged();
                    }),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: package.uploadingImage ? null : onAddImage,
            icon: const Icon(LucideIcons.imagePlus, size: 16),
            label: Text(
              package.uploadingImage
                  ? 'Uploading image...'
                  : package.imageAssetIds.isEmpty
                  ? 'Add package image'
                  : 'Add another image (${package.imageAssetIds.length})',
            ),
          ),
        ),
      ],
    ),
  );

  Widget _flag(String label, bool value, ValueChanged<bool> onChanged) =>
      CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        value: value,
        title: Text(label, style: const TextStyle(fontSize: 12.5)),
        onChanged: (next) => onChanged(next ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      );
}
