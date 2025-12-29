/// PeeLog model for tracking urination events
class PeeLog {
  final int? id;
  final int userId;
  final DateTime timestamp;

  PeeLog({this.id, required this.userId, required this.timestamp});

  /// Create PeeLog from database map
  factory PeeLog.fromMap(Map<String, dynamic> map) {
    return PeeLog(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// Convert PeeLog to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  PeeLog copyWith({int? id, int? userId, DateTime? timestamp}) {
    return PeeLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final p = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $p';
  }

  @override
  String toString() {
    return 'PeeLog(id: $id, userId: $userId, timestamp: $timestamp)';
  }
}
