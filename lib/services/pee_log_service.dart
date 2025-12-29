import '../models/pee_log.dart';

import 'database_service.dart';
import 'ml_service.dart';

/// Pee Log Service - Handles all pee log operations
class PeeLogService {
  static final PeeLogService instance = PeeLogService._init();
  final DatabaseService _db = DatabaseService.instance;
  final MLService _ml = MLService.instance;

  PeeLogService._init();

  /// Add a new pee log
  Future<PeeLog> addPeeLog({
    required int userId,
    required DateTime timestamp,
  }) async {
    final log = PeeLog(userId: userId, timestamp: timestamp);

    final id = await _db.insertPeeLog(log);

    // Trigger ML model update
    await _ml.onNewLogAdded(userId);

    return log.copyWith(id: id);
  }

  /// Get recent pee logs
  Future<List<PeeLog>> getRecentLogs(int userId, {int limit = 10}) async {
    return await _db.getPeeLogs(userId, limit: limit);
  }

  /// Get all pee logs
  Future<List<PeeLog>> getAllLogs(int userId) async {
    return await _db.getPeeLogs(userId);
  }

  /// Get logs for a specific date
  Future<List<PeeLog>> getLogsForDate(int userId, DateTime date) async {
    return await _db.getPeeLogsForDate(userId, date);
  }

  /// Get logs grouped by date
  Future<Map<String, List<PeeLog>>> getLogsGroupedByDate(int userId) async {
    final logs = await _db.getPeeLogs(userId);
    final Map<String, List<PeeLog>> grouped = {};

    for (final log in logs) {
      final dateKey = _formatDateKey(log.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }

    return grouped;
  }

  /// Get dates with activity in a month
  Future<Set<DateTime>> getActivityDatesInMonth(
    int userId,
    int year,
    int month,
  ) async {
    return await _db.getPeeLogDatesInMonth(userId, year, month);
  }

  /// Get weekly frequency data
  Future<Map<DateTime, int>> getWeeklyFrequency(int userId) async {
    return await _db.getWeeklyPeeFrequency(userId);
  }

  /// Delete a log
  Future<void> deleteLog(int logId, int userId) async {
    await _db.deletePeeLog(logId);
    await _ml.onNewLogAdded(userId); // Re-train after deletion
  }

  /// Get today's log count
  Future<int> getTodayCount(int userId) async {
    return await _db.getDailyPeeCount(userId, DateTime.now());
  }

  /// Get total logs count
  Future<int> getTotalCount(int userId) async {
    return await _db.getTotalPeeLogsCount(userId);
  }

  /// Format date as display key
  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return 'Today';
    } else if (logDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)}';
    }
  }

  String _weekday(int weekday) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday];
  }

  String _month(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}
