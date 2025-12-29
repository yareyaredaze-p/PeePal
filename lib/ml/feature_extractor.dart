import '../models/pee_log.dart';
import '../models/pee_log_features.dart';

/// Algorithm 1: Pee Log Feature Computation
/// Computes features from user pee logs to feed the offline ML model
class FeatureExtractor {
  FeatureExtractor._();
  static final FeatureExtractor instance = FeatureExtractor._();

  /// Extracts features for each pee log:
  /// - gap_minutes: Time difference from the previous log (in minutes)
  /// - hour_of_day: Hour of the timestamp (0-23)
  /// - daily_count: Total number of pee logs for that day
  List<PeeLogFeatures> extractFeatures(List<PeeLog> logs) {
    if (logs.isEmpty) return [];

    // Sort logs by timestamp ascending
    final sortedLogs = List<PeeLog>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Group logs by date to calculate daily counts
    final Map<String, int> dailyCounts = {};
    for (final log in sortedLogs) {
      final dateKey = _getDateKey(log.timestamp);
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }

    // Extract features for each log
    final List<PeeLogFeatures> features = [];
    PeeLog? previousLog;

    for (final log in sortedLogs) {
      // Calculate gap from previous log
      double gapMinutes = 0.0;
      if (previousLog != null) {
        gapMinutes = log.timestamp
            .difference(previousLog.timestamp)
            .inMinutes
            .toDouble();
      } else {
        // For the first log of the day, use a default high gap
        // This encourages drinking water at the start
        gapMinutes = 180.0; // 3 hours default
      }

      // Extract hour of day
      final hourOfDay = log.timestamp.hour;

      // Get daily count for this log's date
      final dateKey = _getDateKey(log.timestamp);
      final dailyCount = dailyCounts[dateKey] ?? 1;

      features.add(
        PeeLogFeatures(
          peeLogId: log.id ?? 0,
          userId: log.userId,
          timestamp: log.timestamp,
          gapMinutes: gapMinutes,
          hourOfDay: hourOfDay,
          dailyCount: dailyCount,
        ),
      );

      previousLog = log;
    }

    return features;
  }

  /// Extract features for the most recent log only
  /// Used for real-time prediction after adding a new log
  PeeLogFeatures? extractLatestFeatures(List<PeeLog> logs) {
    if (logs.isEmpty) return null;

    final allFeatures = extractFeatures(logs);
    return allFeatures.isNotEmpty ? allFeatures.last : null;
  }

  /// Extract features for today's logs
  List<PeeLogFeatures> extractTodayFeatures(List<PeeLog> logs) {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);

    final todayLogs = logs
        .where((log) => _getDateKey(log.timestamp) == todayKey)
        .toList();

    return extractFeatures(todayLogs);
  }

  /// Compute current state features for prediction
  /// Takes into account time since last log
  PeeLogFeatures computeCurrentStateFeatures({
    required int userId,
    required List<PeeLog> todayLogs,
    PeeLog? lastLog,
  }) {
    final now = DateTime.now();

    // Calculate gap since last log
    double gapMinutes = 180.0; // Default 3 hours if no logs
    if (lastLog != null) {
      gapMinutes = now.difference(lastLog.timestamp).inMinutes.toDouble();
    }

    return PeeLogFeatures(
      peeLogId: 0,
      userId: userId,
      timestamp: now,
      gapMinutes: gapMinutes,
      hourOfDay: now.hour,
      dailyCount: todayLogs.length,
    );
  }

  /// Helper to get date key string for grouping
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
