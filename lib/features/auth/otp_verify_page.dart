import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/otp_box_input.dart';
import '../../widgets/primary_button.dart';
import 'personal_details_page.dart';

const _otpLength = 6;
const _resendCooldownSeconds = 30;

class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  String _code = '';
  bool _submitting = false;
  bool _resending = false;
  int _cooldown = _resendCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = _resendCooldownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_resending || _cooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestOtp(widget.phoneNumber);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Code resent.')));
      _startCooldown();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not resend the code.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_code.length != _otpLength || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(phoneNumber: widget.phoneNumber, code: _code);
      if (!mounted) return;
      if (result.status == VerifyOtpStatus.signupRequired) {
        context.push(
          '/sign-in/details',
          extra: PersonalDetailsArgs(
            signupToken: result.signupToken!,
            phoneNumber: widget.phoneNumber,
          ),
        );
      }
      // On LOGIN, AuthController already set authenticated state and the
      // router redirect takes over to send us to /home.
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Invalid code, please try again.';
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter code',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a $_otpLength-digit code to +977 ${widget.phoneNumber}',
              style: TextStyle(color: context.colors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 32),
            OtpBoxInput(
              length: _otpLength,
              onChanged: (value) => setState(() => _code = value),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _cooldown > 0 ? null : _resend,
                child: Text(
                  _resending
                      ? 'Resending…'
                      : _cooldown > 0
                      ? 'Resend code in ${_cooldown}s'
                      : 'Resend code',
                ),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Verify',
              enabled: _code.length == _otpLength,
              loading: _submitting,
              onPressed: _verify,
            ),
          ],
        ),
      ),
    );
  }
}
