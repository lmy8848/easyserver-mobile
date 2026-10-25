import '../repositories/auth_repository.dart';

class ConfirmQrLoginUseCase {
  final AuthRepository _repo;
  ConfirmQrLoginUseCase(this._repo);
  Future<void> call(String qrToken) => _repo.confirmQrLogin(qrToken);
}
