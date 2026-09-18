import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/admin_users_repository.dart';
import '../../../providers/admin_users_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

/// Create another admin account (`POST /users/admins`). No OTP signup
/// involved — the new admin's first OTP verification logs them straight in.
class CreateAdminPage extends ConsumerStatefulWidget {
  const CreateAdminPage({super.key});

  @override
  ConsumerState<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends ConsumerState<CreateAdminPage> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      isValidNepaliMobileNumber(_phoneController.text) &&
      _nameController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(adminUsersRepositoryProvider).createAdmin(
            phoneNumber: _phoneController.text.trim(),
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );
      await ref.read(adminUsersProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not create the admin account. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New admin')),
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
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: 'Email (optional)',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Create admin account',
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
