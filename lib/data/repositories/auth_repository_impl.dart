import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  // TODO: Replace with actual API datasource
  // For now, using mock implementation

  @override
  Future<void> sendOtp(String phoneNumber) async {
    // TODO: Call API to send OTP
    await Future.delayed(const Duration(seconds: 1));
    print('OTP sent to $phoneNumber');
  }

  @override
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    // TODO: Call API to verify OTP
    await Future.delayed(const Duration(seconds: 1));
    // Mock: accept any 6-digit OTP
    return otp.length == 6 && int.tryParse(otp) != null;
  }

  @override
  Future<User> createAccount({
    required String phoneNumber,
    required String fullName,
    required String businessName,
  }) async {
    // TODO: Call API to create account
    await Future.delayed(const Duration(seconds: 1));
    
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      phone: phoneNumber,
      fullName: fullName,
      businessName: businessName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // TODO: Save user to local storage
    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    // TODO: Get user from local storage or API
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  @override
  Future<void> logout() async {
    // TODO: Clear local storage and logout from API
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
