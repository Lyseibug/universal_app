import '../datasources/user_api.dart';
import '../models/user_model.dart';

/// Repository for user profile operations with ERPNext.
class UserRepository {
  final UserApi _userApi;

  UserRepository({required UserApi userApi}) : _userApi = userApi;

  /// Fetch user profile from ERPNext by email.
  Future<UserModel> getProfile(String email) async {
    return _userApi.getProfile(email);
  }
}
