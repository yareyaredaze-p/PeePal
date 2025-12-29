/// Application constants for PeePal
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PeePal';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'peepal.db';
  static const int databaseVersion = 1;

  // Session Keys
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  static const String keyIsLoggedIn = 'is_logged_in';

  // ML Configuration
  static const double gapThresholdMinutes = 120.0; // 2 hours
  static const int expectedDailyCount = 6;
  static const String mlModelKey = 'hydration_model';

  // Validation
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const double maxVolumeML = 2000.0;
  static const double minVolumeML = 50.0;
  static const double defaultVolumeML = 250.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Date/Time Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
}
