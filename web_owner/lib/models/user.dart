class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'owner',
    this.isActive = true,
    this.emailVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'owner',
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  User copyWith({String? name, String? email}) => User(
        id: id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role,
        isActive: isActive,
        emailVerified: emailVerified,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'is_active': isActive,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
