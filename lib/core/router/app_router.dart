import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/admin/orders/admin_order_detail_page.dart';
import '../../features/auth/otp_verify_page.dart';
import '../../features/auth/personal_details_page.dart';
import '../../features/auth/sign_in_page.dart';
import '../../features/home/home_shell.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/orders/order_detail_page.dart';
import '../../features/rider/deliveries/rider_order_detail_page.dart';
import '../../features/rider/rider_shell.dart';
import '../../features/tracking/track_result_page.dart';
import '../../features/welcome/welcome_page.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading) return null;

      final isAuthEntryRoute = loc == '/welcome' || loc.startsWith('/sign-in');
      if (!auth.isAuthenticated) {
        if (loc.startsWith('/home') ||
            loc.startsWith('/admin') ||
            loc.startsWith('/rider')) {
          return '/welcome';
        }
        return null;
      }

      final role = auth.user?.role;
      if (role == UserRole.admin) {
        if (isAuthEntryRoute || loc.startsWith('/home') || loc.startsWith('/rider')) {
          return '/admin';
        }
        return null;
      }
      if (role == UserRole.rider) {
        if (isAuthEntryRoute || loc.startsWith('/home') || loc.startsWith('/admin')) {
          return '/rider';
        }
        return null;
      }
      if (loc.startsWith('/admin') || loc.startsWith('/rider')) return '/home';
      if (isAuthEntryRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/track/:trackingNumber',
        builder: (context, state) => TrackResultPage(
          trackingNumber: state.pathParameters['trackingNumber']!,
        ),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/sign-in/otp',
        builder: (context, state) =>
            OtpVerifyPage(phoneNumber: state.extra as String),
      ),
      GoRoute(
        path: '/sign-in/details',
        builder: (context, state) {
          final extra = state.extra as PersonalDetailsArgs;
          return PersonalDetailsPage(
            signupToken: extra.signupToken,
            phoneNumber: extra.phoneNumber,
          );
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/home/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
      GoRoute(
        path: '/admin/orders/:id',
        builder: (context, state) =>
            AdminOrderDetailPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/rider', builder: (context, state) => const RiderShell()),
      GoRoute(
        path: '/rider/orders/:id',
        builder: (context, state) =>
            RiderOrderDetailPage(orderId: state.pathParameters['id']!),
      ),
    ],
  );
});
