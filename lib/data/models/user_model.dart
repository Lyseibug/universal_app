/// User model representing the logged-in user.
/// Supports both generic and ERPNext/Frappe formats.
class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? fullName;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fullName,
    this.avatar,
  });

  /// Parse from generic JSON format.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  /// Parse from ERPNext/Frappe User doctype format.
  factory UserModel.fromFrappeJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['name'] as String? ?? '',
      username: json['name'] as String? ?? '',
      email: json['email'] as String? ?? json['name'] as String? ?? '',
      role: json['role_profile_name'] as String? ?? 'User',
      fullName: json['full_name'] as String?,
      avatar: json['user_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'full_name': fullName,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? fullName,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
    );
  }
}
