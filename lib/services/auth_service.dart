import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants/app_constants.dart';
import '../models/user.dart';
import 'database_service.dart';

/// Authentication service for user management and session handling
class AuthService {
  static final AuthService instance = AuthService._init();
  final DatabaseService _db = DatabaseService.instance;

  AuthService._init();

  // ============== PASSWORD HASHING ==============

  /// Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a password against a hash
  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // ============== AUTHENTICATION ==============

  /// Register a new user
  /// Returns the created user or throws an exception on failure
  Future<User> register(String username, String password) async {
    // Validate input
    if (username.length < AppConstants.minUsernameLength) {
      throw AuthException(
        'Username must be at least ${AppConstants.minUsernameLength} characters',
      );
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw AuthException(
        'Password must be at least ${AppConstants.minPasswordLength} characters',
      );
    }

    // Check if username already exists
    final existingUser = await _db.getUserByUsername(username);
    if (existingUser != null) {
      throw AuthException('Username already exists');
    }

    // Create user
    final user = User(
      username: username,
      passwordHash: _hashPassword(password),
    );

    final id = await _db.insertUser(user);
    final createdUser = user.copyWith(id: id);

    // Save session
    await _saveSession(createdUser);

    return createdUser;
  }

  /// Login with username and password
  /// Returns the user or throws an exception on failure
  Future<User> login(String username, String password) async {
    // Validate input
    if (username.isEmpty || password.isEmpty) {
      throw AuthException('Username and password are required');
    }

    // Find user
    final user = await _db.getUserByUsername(username);
    if (user == null) {
      throw AuthException('Invalid username or password');
    }

    // Verify password
    if (!_verifyPassword(password, user.passwordHash)) {
      throw AuthException('Invalid username or password');
    }

    // Save session
    await _saveSession(user);

    return user;
  }

  /// Logout the current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUsername);
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
  }

  // ============== SESSION MANAGEMENT ==============

  /// Save user session to shared preferences
  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyUserId, user.id!);
    await prefs.setString(AppConstants.keyUsername, user.username);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Get current user ID
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyUserId);
  }

  /// Get current username
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUsername);
  }

  /// Get current user from database
  Future<User?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;
    return await _db.getUserById(userId);
  }

  /// Restore session on app start
  Future<User?> restoreSession() async {
    final isLoggedIn = await this.isLoggedIn();
    if (!isLoggedIn) return null;

    final user = await getCurrentUser();
    if (user == null) {
      // Session invalid, clear it
      await logout();
      return null;
    }

    return user;
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
