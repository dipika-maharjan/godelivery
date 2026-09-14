import '../repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repository;

  SendOtp(this.repository);

  Future<void> call(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (phoneNumber.length < 10) {
      throw ArgumentError('Phone number must be at least 10 digits');
    }
    return repository.sendOtp(phoneNumber);
  }
}
