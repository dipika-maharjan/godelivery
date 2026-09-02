import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits')));
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Call AuthProvider.verifyOtpCode(otp)
    // and navigate to business info page on success

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a code to ${widget.phoneNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5F5F5F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  border: Border.all(
                    color: const Color(0xFFD2D2D2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF5B5B5B),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: 'OTP',
                          hintStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '0/6',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3C91F),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Didn\'t receive code? Resend',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
