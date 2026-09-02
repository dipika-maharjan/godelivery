import '../repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository repository;

  VerifyOtp(this.repository);

  Future<bool> call(String phoneNumber, String otp) async {
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (otp.isEmpty || otp.length != 6) {
      throw ArgumentError('OTP must be 6 digits');
    }
    return repository.verifyOtp(phoneNumber, otp);
  }
}
