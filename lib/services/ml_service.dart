import '../models/hydration_recommendation.dart';
import '../models/pee_log.dart';
import 'database_service.dart';
import '../ml/feature_extractor.dart';
import '../ml/decision_tree_trainer.dart';
import '../ml/hydration_predictor.dart';

/// ML Service - Coordinates ML pipeline operations
/// Provides a clean interface for UI to interact with ML components
class MLService {
  static final MLService instance = MLService._init();
  final DatabaseService _db = DatabaseService.instance;
  final FeatureExtractor _featureExtractor = FeatureExtractor.instance;
  final DecisionTreeTrainer _trainer = DecisionTreeTrainer.instance;
  final HydrationPredictor _predictor = HydrationPredictor.instance;

  MLService._init();

  /// Get current hydration recommendation for a user
  Future<HydrationRecommendation> getRecommendation(int userId) async {
    // Fetch all logs and today's logs
    final allLogs = await _db.getPeeLogs(userId);
    final todayLogs = await _db.getPeeLogsForDate(userId, DateTime.now());

    return await _predictor.predict(
      userId: userId,
      allLogs: allLogs,
      todayLogs: todayLogs,
    );
  }

  /// Update model after new log is added
  Future<void> onNewLogAdded(int userId) async {
    final logs = await _db.getPeeLogs(userId);
    await _predictor.retrainModel(userId, logs);
  }

  /// Check if user has a trained model
  Future<bool> hasModel(int userId) async {
    return await _trainer.hasModel(userId);
  }

  /// Get model information for display
  Future<Map<String, dynamic>?> getModelInfo(int userId) async {
    return await _predictor.getModelInfo(userId);
  }

  /// Force model retraining
  Future<void> retrainModel(int userId) async {
    final logs = await _db.getPeeLogs(userId);
    if (logs.isNotEmpty) {
      final features = _featureExtractor.extractFeatures(logs);
      await _trainer.trainAndSave(features, userId);
    }
  }

  /// Get statistics for the home screen graph
  Future<Map<String, double>> getRecentStats(int userId) async {
    final logs = await _db.getPeeLogs(userId);
    if (logs.isEmpty) {
      return {'sinceLast': 0.0, 'averageInterval': 0.0, 'count': 0};
    }

    // Sort logs by timestamp ascending
    final sortedLogs = List<PeeLog>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final lastLog = sortedLogs.last;
    final sinceLast =
        DateTime.now().difference(lastLog.timestamp).inMinutes / 60.0;

    // Calculate average interval of last 10 pees
    double averageIntervalHours = 0.0;
    int count = 0;
    if (sortedLogs.length > 1) {
      final lastLogs = sortedLogs.length > 11
          ? sortedLogs.sublist(sortedLogs.length - 11)
          : sortedLogs;

      double totalMinutes = 0;
      int intervals = 0;
      for (int i = 1; i < lastLogs.length; i++) {
        totalMinutes += lastLogs[i].timestamp
            .difference(lastLogs[i - 1].timestamp)
            .inMinutes;
        intervals++;
      }
      if (intervals > 0) {
        averageIntervalHours = (totalMinutes / intervals) / 60.0;
      }
      count = sortedLogs.length;
    }

    return {
      'sinceLast': sinceLast,
      'averageInterval': averageIntervalHours,
      'count': count.toDouble(),
    };
  }

  /// Get a list of future water intake recommendations
  Future<List<Map<String, dynamic>>> getFutureRecommendations(
    int userId,
  ) async {
    final logs = await _db.getPeeLogs(userId);
    if (logs.length < 10) {
      return []; // Return empty to indicate "Training"
    }

    final stats = await getRecentStats(userId);
    final averageIntervalHours = stats['averageInterval'] ?? 3.0;

    // Fallback to 3 hours if average is suspicious
    final interval = (averageIntervalHours > 0.5 && averageIntervalHours < 8.0)
        ? averageIntervalHours
        : 3.0;

    final List<Map<String, dynamic>> recommendations = [];
    final now = DateTime.now();

    // Generate 4 recommendations for today
    for (int i = 1; i <= 4; i++) {
      final recommendTime = now.add(
        Duration(minutes: (interval * 60 * i).toInt()),
      );
      recommendations.add({'time': recommendTime, 'amount': '250ml'});
    }

    return recommendations;
  }
}
