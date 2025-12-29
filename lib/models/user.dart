/// User model for authentication and session management
class User {
  final int? id;
  final String username;
  final String passwordHash;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create User from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert User to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, createdAt: $createdAt)';
  }
}
