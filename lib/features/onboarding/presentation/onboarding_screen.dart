import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../signin/presentation/signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _trackingCtrl = TextEditingController();

  void _onTrackPressed() {
    final trackingId = _trackingCtrl.text.trim().toUpperCase();
    if (trackingId.isEmpty) return;

    final isFound = trackingId == 'TRK001';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ShipmentResultScreen(trackingId: trackingId, isFound: isFound),
      ),
    );
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 170,
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '9:41',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        Row(
                          children: const [
                            Icon(
                              Icons.signal_cellular_4_bar_rounded,
                              size: 16,
                              color: AppColors.black,
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.wifi_rounded,
                              size: 16,
                              color: AppColors.black,
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.battery_full_rounded,
                              size: 16,
                              color: AppColors.black,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Center(
                      child: Image.asset(
                        'assets/images/onboarding_logo.png',
                        width: 160,
                        height: 46,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good Morning',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Track your Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: TextField(
                                controller: _trackingCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                onSubmitted: (_) => _onTrackPressed(),
                                decoration: const InputDecoration(
                                  hintText: 'Enter your shipping number',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF969696),
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: _onTrackPressed,
                            child: Container(
                              width: 54,
                              height: 54,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 28,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Sign In To',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _InfoRow(
                      icon: Icons.lock_outline_rounded,
                      text: 'Keep track of your order history',
                    ),

                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.local_shipping_outlined,
                      text: 'Ship your order within Valley',
                    ),

                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.percent_rounded,
                      text: 'Get our exclusive offers',
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Before your Sign In',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _InfoRow(
                      icon: Icons.check_box_outline_blank_rounded,
                      text: 'We deliver only inside the valley',
                    ),

                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.check_rounded,
                      text: 'We deliver only electronics goods',
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SigninScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.black,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF696969),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShipmentResultScreen extends StatelessWidget {
  const ShipmentResultScreen({
    super.key,
    required this.trackingId,
    required this.isFound,
  });

  final String trackingId;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '9:41',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.signal_cellular_4_bar_rounded,
                                size: 16,
                                color: AppColors.black,
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.wifi_rounded,
                                size: 16,
                                color: AppColors.black,
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.battery_full_rounded,
                                size: 16,
                                color: AppColors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.black,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isFound) ...[
                        const Text(
                          'Order Created',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: const [
                            _StatusStep(title: 'Order Created', active: true),
                            _StatusStep(
                              title: 'processing/packed',
                              active: false,
                            ),
                            _StatusStep(title: 'shipped', active: false),
                            _StatusStep(title: 'delivered', active: false),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tracking ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7A7A7A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                trackingId,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Order has been created',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Estimated Delivery: 12:55 PM',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF5B5B5B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tracking ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7A7A7A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                trackingId,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Shipment Not Found',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'The shipment of shipping number. $trackingId doesnt existing in our system.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF5B5B5B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({required this.title, required this.active});

  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : const Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: active ? AppColors.black : const Color(0xFF787878),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5D5D5D)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5B5B5B),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}
