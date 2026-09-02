import '../entities/user.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phoneNumber);
  Future<bool> verifyOtp(String phoneNumber, String otp);
  Future<User> createAccount({
    required String phoneNumber,
    required String fullName,
    required String businessName,
  });
  Future<User?> getCurrentUser();
  Future<void> logout();
}
