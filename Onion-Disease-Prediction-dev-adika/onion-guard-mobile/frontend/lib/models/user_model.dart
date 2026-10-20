class UserModel {
  final String name;
  final String email;
  final String phone;
  final String username;
  final String userType;
  final String languagePreference;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
    required this.userType,
    this.languagePreference = 'en',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      userType: json['user_type'] ?? 'Farmer',
      languagePreference: json['language_preference'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'username': username,
        'user_type': userType,
        'language_preference': languagePreference,
      };
}
