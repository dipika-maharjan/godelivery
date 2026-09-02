import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CreateAccount {
  final AuthRepository repository;

  CreateAccount(this.repository);

  Future<User> call({
    required String phoneNumber,
    required String fullName,
    required String businessName,
  }) async {
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (fullName.isEmpty || fullName.length < 2) {
      throw ArgumentError('Full name must be at least 2 characters');
    }
    if (businessName.isEmpty || businessName.length < 2) {
      throw ArgumentError('Business name must be at least 2 characters');
    }
    
    return repository.createAccount(
      phoneNumber: phoneNumber,
      fullName: fullName,
      businessName: businessName,
    );
  }
}
