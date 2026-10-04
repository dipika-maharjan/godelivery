import '../presentation/state_management/auth_provider.dart';
import '../domain/usecases/send_otp.dart';
import '../domain/usecases/verify_otp.dart';
import '../domain/usecases/create_account.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/logout.dart';
import '../data/repositories/auth_repository_impl.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  late AuthProvider _authProvider;

  void setupDependencies() {
    // Repository
    final authRepository = AuthRepositoryImpl();

    // Use Cases
    final sendOtp = SendOtp(authRepository);
    final verifyOtp = VerifyOtp(authRepository);
    final createAccount = CreateAccount(authRepository);
    final getCurrentUser = GetCurrentUser(authRepository);
    final logout = Logout(authRepository);

    // Provider
    _authProvider = AuthProvider(
      sendOtp: sendOtp,
      verifyOtp: verifyOtp,
      createAccount: createAccount,
      getCurrentUser: getCurrentUser,
      logout: logout,
    );
  }

  AuthProvider get authProvider => _authProvider;
}
