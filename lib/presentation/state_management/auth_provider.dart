import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/send_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/logout.dart';

class AuthProvider extends ChangeNotifier {
  final SendOtp sendOtp;
  final VerifyOtp verifyOtp;
  final CreateAccount createAccount;
  final GetCurrentUser getCurrentUser;
  final Logout logout;

  User? _currentUser;
  String? _currentPhone;
  bool _isLoading = false;
  String? _error;

  AuthProvider({
    required this.sendOtp,
    required this.verifyOtp,
    required this.createAccount,
    required this.getCurrentUser,
    required this.logout,
  });

  // Getters
  User? get user => _currentUser;
  String? get phone => _currentPhone;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Send OTP
  Future<void> sendOtpToPhone(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await sendOtp(phoneNumber);
      _currentPhone = phoneNumber;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Verify OTP
  Future<bool> verifyOtpCode(String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentPhone == null) {
        throw Exception('Phone number not set');
      }

      final isValid = await verifyOtp(_currentPhone!, otp);
      
      _isLoading = false;
      notifyListeners();
      
      return isValid;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Create Account
  Future<User> createUserAccount({
    required String fullName,
    required String businessName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentPhone == null) {
        throw Exception('Phone number not set');
      }

      final user = await createAccount(
        phoneNumber: _currentPhone!,
        fullName: fullName,
        businessName: businessName,
      );

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      
      return user;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get Current User
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      
      // Use Future.delayed to avoid setState during build
      await Future.delayed(Duration.zero);
      notifyListeners();

      final user = await getCurrentUser();
      _currentUser = user;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Logout
  Future<void> logoutUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await logout();
      
      _currentUser = null;
      _currentPhone = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
