import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _trackingCtrl = TextEditingController();

  void _onTrackPressed() {
    final id = _trackingCtrl.text.trim();
    if (id.isEmpty) return;
    // TODO: navigate to Tracking Details / Shipment Not Found once
    // those screens + the tracking repository exist.
    debugPrint('Track pressed for: $id');
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Yellow header: logo wordmark ---
            const SizedBox(height: 60),
            const _LogoWordmark(),
            const SizedBox(height: 36),

            // --- White rounded content sheet ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text('☀️', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text(
                            'Good Morning',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track your Order',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tracking search field
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _trackingCtrl,
                                  onSubmitted: (_) => _onTrackPressed(),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your shipping number',
                                    hintStyle: TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: _onTrackPressed,
                            borderRadius: BorderRadius.circular(26),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        'Sign In to',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _InfoRow(
                        icon: Icons.history,
                        label: 'Keep track of your order history',
                      ),
                      const _InfoRow(
                        icon: Icons.send_outlined,
                        label: 'Ship your order within Valley',
                      ),
                      const _InfoRow(
                        icon: Icons.percent,
                        label: 'Get our exclusive offers',
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Before your Sign In',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _InfoRow(
                        icon: Icons.map_outlined,
                        label: 'We delivery only inside the valley',
                      ),
                      const _InfoRow(
                        icon: Icons.bolt_outlined,
                        label: 'We delivery only electronics goods',
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: navigate to Sign In screen.
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                          children: [
                            TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoWordmark extends StatelessWidget {
  const _LogoWordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/onboarding_logo.png',
        width: 180,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF444444)),
            ),
          ),
        ],
      ),
    );
  }
}
