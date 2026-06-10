/// Model for ERPNext/Frappe login API response.
///
/// Success response (HTTP 200):
/// {
///   "message": "Logged In",
///   "home_page": "/app",
///   "full_name": "Naziya"
/// }
///
/// Error response (HTTP 401):
/// {
///   "message": "Invalid login credentials",
///   "exc_type": "AuthenticationError"
/// }
class LoginResponseModel {
  final bool success;
  final String? message;
  final String? fullName;
  final String? homePage;
  final String? excType;

  const LoginResponseModel({
    required this.success,
    this.message,
    this.fullName,
    this.homePage,
    this.excType,
  });

  /// Parse from Frappe login response JSON.
  factory LoginResponseModel.fromFrappeJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final message = json['message'] as String? ?? '';
    final excType = json['exc_type'] as String?;
    final fullName = json['full_name'] as String?;
    final homePage = json['home_page'] as String?;

    // Frappe returns HTTP 200 with "Logged In" on success
    final isSuccess =
        statusCode == 200 && message.toLowerCase().contains('logged in');

    return LoginResponseModel(
      success: isSuccess,
      message: message,
      fullName: fullName,
      homePage: homePage,
      excType: excType,
    );
  }
}
