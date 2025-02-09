class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.isActive,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
