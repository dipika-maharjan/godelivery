import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/greeting.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const _termsUrl = 'https://godelivery.godokan.com/help/terms-and-conditions';
const _privacyUrl = 'https://godelivery.godokan.com/help/privacy-policies';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _trackingController = TextEditingController();
  late final _termsTapRecognizer = TapGestureRecognizer()
    ..onTap = () => _openUrl(_termsUrl);
  late final _privacyTapRecognizer = TapGestureRecognizer()
    ..onTap = () => _openUrl(_privacyUrl);

  @override
  void dispose() {
    _trackingController.dispose();
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
    }
  }

  void _track() {
    final value = _trackingController.text.trim();
    if (value.isEmpty) return;
    context.push('/track/${Uri.encodeComponent(value)}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.onPrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),

              child: const Image(
                image: AssetImage('assets/logo/godelivery-black.png'),
                // width: "auto",
                height: 32,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeBasedGreeting(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track a shipment, or sign in to send one.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _trackingController,
                              hint: 'Enter tracking number',
                              prefix: Icon(
                                LucideIcons.search,
                                size: 18,
                                color: context.colors.textMuted,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (_) {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 52,
                            width: 52,
                            child: ElevatedButton(
                              onPressed: _track,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Icon(LucideIcons.search),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Sign in to',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      const _PerkRow(
                        icon: LucideIcons.truck,
                        text: 'Keep track of your order history',
                      ),
                      const _PerkRow(
                        icon: LucideIcons.mapPin,
                        text: 'Ship your order within Kathmandu',
                      ),
                      const _PerkRow(
                        icon: LucideIcons.percent,
                        text: 'Get our exclusive offers',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Before your sign in',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      const _PerkRow(
                        icon: LucideIcons.map,
                        text: 'We deliver only inside the valley',
                      ),
                      const _PerkRow(
                        icon: LucideIcons.zap,
                        text: 'We deliver only electronics goods',
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Sign In',
                        onPressed: () => context.push('/sign-in'),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.colors.textMuted,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: context.colors.text,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsTapRecognizer,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: context.colors.text,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _privacyTapRecognizer,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
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

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              // color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: context.colors.textMuted),
          ),
          const SizedBox(width: 0),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
