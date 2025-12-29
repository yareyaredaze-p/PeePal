/// Computed features for ML model input
class PeeLogFeatures {
  final int peeLogId;
  final int userId;
  final DateTime timestamp;
  final double gapMinutes; // Time since previous log
  final int hourOfDay; // Hour of the timestamp (0-23)
  final int dailyCount; // Total logs for that day

  PeeLogFeatures({
    required this.peeLogId,
    required this.userId,
    required this.timestamp,
    required this.gapMinutes,
    required this.hourOfDay,
    required this.dailyCount,
  });

  /// Convert to feature vector for ML model
  List<double> toFeatureVector() {
    return [gapMinutes, hourOfDay.toDouble(), dailyCount.toDouble()];
  }

  /// Create from database map
  factory PeeLogFeatures.fromMap(Map<String, dynamic> map) {
    return PeeLogFeatures(
      peeLogId: map['pee_log_id'] as int,
      userId: map['user_id'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      gapMinutes: (map['gap_minutes'] as num).toDouble(),
      hourOfDay: map['hour_of_day'] as int,
      dailyCount: map['daily_count'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'pee_log_id': peeLogId,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'gap_minutes': gapMinutes,
      'hour_of_day': hourOfDay,
      'daily_count': dailyCount,
    };
  }

  @override
  String toString() {
    return 'PeeLogFeatures(peeLogId: $peeLogId, gapMinutes: $gapMinutes, hourOfDay: $hourOfDay, dailyCount: $dailyCount)';
  }
}
