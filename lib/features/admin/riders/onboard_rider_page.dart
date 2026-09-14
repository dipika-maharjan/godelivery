import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/riders_repository.dart';
import '../../../models/rider.dart';
import '../../../providers/admin_riders_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

/// Onboard a new delivery partner (`POST /riders`).
class OnboardRiderPage extends ConsumerStatefulWidget {
  const OnboardRiderPage({super.key});

  @override
  ConsumerState<OnboardRiderPage> createState() => _OnboardRiderPageState();
}

class _OnboardRiderPageState extends ConsumerState<OnboardRiderPage> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  VehicleType _vehicleType = VehicleType.motorbike;
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      isValidNepaliMobileNumber(_phoneController.text) &&
      _nameController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(ridersRepositoryProvider).onboard(
            phoneNumber: '+977${_phoneController.text.trim()}',
            name: _nameController.text.trim(),
            vehicleType: _vehicleType,
            vehiclePlateNumber: _plateController.text.trim().isEmpty
                ? null
                : _plateController.text.trim(),
          );
      await ref.read(adminRidersProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not onboard the rider. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboard rider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _phoneController,
              label: 'Phone number',
              hint: '98XXXXXXXX',
              keyboardType: TextInputType.phone,
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
                  child: Text('+977', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Rider name',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              'Vehicle type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleType>(
                  value: _vehicleType,
                  isExpanded: true,
                  items: [
                    for (final type in VehicleType.values)
                      DropdownMenuItem(value: type, child: Text(vehicleTypeLabel(type))),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _vehicleType = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _plateController,
              label: 'Plate number (optional)',
              hint: 'e.g. BA 12 PA 3456',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Onboard rider',
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
