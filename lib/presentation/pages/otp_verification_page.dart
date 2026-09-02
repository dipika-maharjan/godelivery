import 'package:flutter/material.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  late TextEditingController _otpController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP must be 6 digits')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Call AuthProvider.verifyOtpCode(otp)
    // and navigate to business info page on success
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushNamed(
          '/business-info',
          arguments: widget.phoneNumber,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter OTP',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a code to ${widget.phoneNumber}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'OTP',
                hintText: 'Enter 6-digit OTP',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pop(context);
                },
                child: const Text('Didn\'t receive code? Resend'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
