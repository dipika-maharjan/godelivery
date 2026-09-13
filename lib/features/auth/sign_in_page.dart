import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const _kCountryCode = '+977';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValid => isValidNepaliMobileNumber(_phoneController.text);

  Future<void> _sendOtp() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final phoneNumber = _phoneController.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(phoneNumber);
      if (!mounted) return;
      context.push('/sign-in/otp', extra: phoneNumber);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not send the code.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              "We'll text you a one-time code to verify your number.",
              style: TextStyle(color: AppColors.muted, fontSize: 13.5),
            ),
            const SizedBox(height: 28),
            AppTextField(
              controller: _phoneController,
              label: 'Phone number',
              hint: '98XXXXXXXX',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              maxLength: 10,
              helperText: '10 digits, starting with 98, 97, or 96',
              prefix: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      _kCountryCode,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(width: 6),
                    SizedBox(
                      height: 18,
                      child: VerticalDivider(color: AppColors.border),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Send OTP',
              enabled: _isValid,
              loading: _submitting,
              onPressed: _sendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
