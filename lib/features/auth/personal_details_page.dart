import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:galli_maps_package/galli_maps_package.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/location.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class PersonalDetailsArgs {
  const PersonalDetailsArgs({
    required this.signupToken,
    required this.phoneNumber,
  });

  final String signupToken;
  final String phoneNumber;
}

class PersonalDetailsPage extends ConsumerStatefulWidget {
  const PersonalDetailsPage({
    super.key,
    required this.signupToken,
    required this.phoneNumber,
  });

  final String signupToken;
  final String phoneNumber;

  @override
  ConsumerState<PersonalDetailsPage> createState() =>
      _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends ConsumerState<PersonalDetailsPage> {
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();

  GalliPickedLocation? _pickedLocation;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _shopNameController.text.trim().isNotEmpty &&
      _pickedLocation != null;

  Future<void> _pickLocation() async {
    final picked = await GalliLocationPicker.pickLocation(context);
    if (picked != null) {
      setState(() => _pickedLocation = picked);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final location = _pickedLocation!;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeSignup(
            signupToken: widget.signupToken,
            name: _nameController.text.trim(),
            shopName: _shopNameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            shopLocation: LocationInput(
              addressLine: location.address ?? location.name ?? 'Shop location',
              latitude: location.latitude,
              longitude: location.longitude,
            ),
          );
      // AuthController sets the authenticated state; the router redirect
      // takes it from here to /home.
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not complete signup. Please try again.';
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
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tell us about your shop",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "We'll use this to set up your account.",
              style: TextStyle(color: context.colors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _nameController,
              label: 'Your name',
              hint: 'e.g. Sita Sharma',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _shopNameController,
              label: 'Shop name',
              hint: 'e.g. Sita Electronics',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              label: 'Email (optional)',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Text(
              'Shop location',
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
                    Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: context.colors.text,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedLocation?.address ??
                            _pickedLocation?.name ??
                            'Pick your shop location on the map',
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
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Finish',
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
